classdef opto_electrical_stimulation < handle
    %CROSS_ENTROPY_OPTIMIZATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        TD
        device_name
        sampling_frequency
        logging_directory
        
        gp_model
        
        % Timing parameters
        run_start_time_s
        cycle_start_time_s
        this_time_s
        last_time_s
        
        stimulation_time_s
        evaluate_delay_s
        objective_function
        objective_window_s
        objective_type
        optimization_direction
        sample_skip
        sample_results
        
        % Optimization parameters
        control_time
        n_samples
        next_sample_set
        n_burn_in
        parameter_vector
        pre_stimulation_metric
        state_threshold
        
        stimulation_parameter
        n_parameters
        target_metric
        
        % Acquisition parameters
        lower_bound
        upper_bound
        
        % Logging parameters
        objective_fid
        parameter_fid
        state_fid
        
        optimization_done
        stimulator
        metric_type
    end
    
    methods
        
        %%%%%%%%%%%%%%%
        %
        %%%%%%%%%%%%%%%
        function initialize(obj, gp_model)
            
            
            obj.run_start_time_s        = posixtime(datetime);
            
            obj.optimization_done       = 0;
            
            obj.objective_fid           = fopen(sprintf('%s/objective_function.csv',...
                obj.logging_directory),'a');
            obj.parameter_fid           = fopen(sprintf('%s/parameter.csv',...
                obj.logging_directory),'a');
            obj.state_fid               = fopen(sprintf('%s/state_function.csv',...
                obj.logging_directory),'a');
            
            obj.n_samples               = 1;
            
            if nargin == 2
                obj.n_samples = size(gp_model.y_data,1);
                obj.parameter_vector = gp_model.x_data;
                obj.sample_results = gp_model.y_data;
                obj.gp_model = gp_model;
            end
            
            obj.reset_time();
        end
        
        %%%%%%%%%%%%%%%
        %
        %%%%%%%%%%%%%%%
        function optimize(obj)
            
            %             obj.stimulator.check_stimulation()
            
            this_time  = obj.get_current_time();
            
            if this_time > ...
                    obj.stimulation_time_s +  obj.cycle_start_time_s && ...
                    obj.stimulator.stimulation_armed
                
                obj.select_next_sample();
                
                %%%%%%%%%%%%%%%%%%%%
                obj.stimulator.generate_stimulation_signal();
                obj.stimulator.write_stimulation_signals();
                %%%%%%%%%%%%%%%%%%%%
                
                obj.stimulator.stimulate()
                
            elseif this_time  > ...
                    obj.evaluate_delay_s + obj.stimulator.stimulation_duration + obj.stimulator.stimulation_time && ...
                    ~obj.stimulator.stimulation_armed
                
                obj.evaluate_objective_function();
                
                obj.reset_time();
                obj.stimulator.stimulation_armed = 1;
            end
            
        end
        
        function select_next_sample(obj)
            
%             obj.parameter_vector(obj.n_samples,:) = rand(1,obj.n_parameters).* (obj.upper_bound - obj.lower_bound) + obj.lower_bound;                
            fprintf('Sample: %d\n', obj.n_samples);
            if mod(obj.n_samples,2) == 1
                obj.stimulator.stimulation_amplitude = obj.stimulator.stimulation_amplitude;
                obj.metric_type = 1;
            else
                obj.stimulator.stimulation_amplitude = obj.stimulator.stimulation_amplitude;
                obj.metric_type = -1;
            end
            
%             for c1 = 1:obj.n_parameters
                % Update the stimulation parameters
                
%                 fprintf('\tStimulation %s = %e\n', obj.stimulation_parameter{c1}, obj.parameter_vector(obj.n_samples, c1));
                
%             end
%             
%             s = sprintf('%e,',obj.parameter_vector(obj.n_samples,:));
%             fprintf(obj.parameter_fid,  [s(1:end-1) '\n']);
        end
        
        %%%%%%%%%%%%%%%
        % Resets the clock to start another stimulation trial
        %%%%%%%%%%%%%%%
        function reset_time(obj)
            obj.cycle_start_time_s   = obj.get_current_time();
            obj.last_time_s          = obj.get_current_time();
            obj.this_time_s          = obj.get_current_time();
        end
        
        
        function t = get_current_time(obj)
            t = obj.TD.ReadTargetVEX([obj.device_name '.current_time'], 0, 1, 'I32', 'F64')/obj.sampling_frequency;
        end
        
        
        function evaluate_objective_function(obj)
            objective_window_start  = obj.stimulator.stimulation_time;
            objective_window_end    = objective_window_start + obj.objective_window_s;
%             obj.pre_stimulation_metric = obj.objective_function.get_metric(objective_window_prestart, objective_window_start,1);
%             fprintf('Pre-stimulation state = %e\n', obj.pre_stimulation_metric);
            m = obj.objective_function.get_metric(objective_window_start, objective_window_end,1,obj.metric_type);
            
            obj.n_samples = obj.n_samples+1;
            
        end
        
    end
    
    
end

