classdef SDBO_controller < handle
    %CROSS_ENTROPY_OPTIMIZATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        TD
        device_name
        sampling_frequency
        logging_directory
        
        policy_model
        
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
                
        % Acquisition parameters
        lower_bound
        upper_bound
        
        % Logging parameters
        objective_fid   
        parameter_fid
        state_fid
        
        optimization_done
        stimulator
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
           
            obj.n_samples               = 0;
            
            if nargin == 2
                 obj.n_samples = size(gp_model.y_data,1);
                 obj.parameter_vector = gp_model.x_data;
                 obj.sample_results = gp_model.y_data;
                 obj.gp_model = gp_model;
            end
            
%         obj.gp_model.acquisition_function = 'UCB';
        
        obj.reset_time();
        end
        
        %%%%%%%%%%%%%%%
        %
        %%%%%%%%%%%%%%%
        function optimize(obj)
            
            obj.stimulator.check_stimulation()
            
            this_time  = obj.get_current_time();

            if this_time > ...
                obj.stimulation_time_s +  obj.cycle_start_time_s && ...
                obj.stimulator.stimulation_armed
                
                obj.select_next_sample();
                
                obj.pre_stimulation_metric = obj.objective_function.get_metric(obj.evaluate_delay_s);
                fprintf('Pre-stimulation state = %e\n', obj.pre_stimulation_metric);
            
                if any(strcmp(obj.stimulation_parameter, 'state_threshold'))&& ...
                        obj.pre_stimulation_metric > obj.state_threshold 
                    
                    obj.stimulator.stimulation_amplitude = 0;
                   
                end
                
                obj.stimulator.generate_stimulation_signal();
                obj.stimulator.write_stimulation_signals();
                obj.stimulator.stimulate()  
                
            elseif this_time  > ...
                    obj.evaluate_delay_s + obj.stimulator.stimulation_duration + obj.stimulator.stimulation_time && ...
                    ~obj.stimulator.stimulation_armed
                
                obj.evaluate_objective_function(); 
                
                if obj.n_samples >= obj.n_burn_in 
                    % Update GP model
                    obj.policy_model.initialize_data(obj.parameter_vector, obj.sample_results, obj.lower_bound, obj.upper_bound) 
                    
                end
                
                obj.reset_time();
                obj.stimulator.stimulation_armed = 1;
            end  
                   
        end
        
        function select_next_sample(obj)
            obj.n_samples = obj.n_samples+1;
            
            if obj.n_samples <= obj.n_burn_in
                obj.parameter_vector(obj.n_samples,:) = rand(1,obj.n_parameters).* (obj.upper_bound - obj.lower_bound) + obj.lower_bound;
            else
                obj.parameter_vector(obj.n_samples,:) = obj.policy_model.state_acquisition(2,.2);
            
                obj.parameter_vector(obj.n_samples,:);
            end
            
            fprintf('Sample: %d\n', obj.n_samples);
            for c1 = 1:obj.n_parameters
                % Update the stimulation parameters
                
                fprintf('\tStimulation %s = %e\n', obj.stimulation_parameter{c1}, obj.parameter_vector(obj.n_samples, c1));
                
                switch obj.stimulation_parameter{c1}
                    case 'frequency'
                        obj.stimulator.stimulation_frequency    = obj.parameter_vector(obj.n_samples, c1);
                    case 'duration'
                        obj.stimulator.stimulation_duration     = obj.parameter_vector(obj.n_samples, c1);
                    case 'amplitude'
                        obj.stimulator.stimulation_amplitude    = obj.parameter_vector(obj.n_samples, c1);
                    case 'state_threshold'
                        obj.state_threshold                     = obj.parameter_vector(obj.n_samples, c1);
                end
                
            end
            
            s = sprintf('%e,',obj.parameter_vector(obj.n_samples,:));
            fprintf(obj.parameter_fid,  [s(1:end-1) '\n']);
        end
        
        %%%%%%%%%%%%%%%
        % Resets the clock to start another stimulation trial
        %%%%%%%%%%%%%%%
        function reset_time(obj)
            obj.cycle_start_time_s   = obj.get_current_time();
            obj.last_time_s          = obj.get_current_time();
            obj.this_time_s          = obj.get_current_time();
        end

        %%%%%%%%%%%%%%%
        % 
        %  
        %%%%%%%%%%%%%%%
        function t = get_current_time(obj)
            t = obj.TD.ReadTargetVEX([obj.device_name '.current_time'], 0, 1, 'I32', 'F64')/obj.sampling_frequency;
        end
        
         %%%%%%%%%%%%%%%
        % Evaluate objective function - this needs to be split into it's
        % own object 
        %%%%%%%%%%%%%%%
        function evaluate_objective_function(obj)
            objective_window_start  = obj.stimulator.stimulation_time + obj.stimulator.stimulation_duration;
            objective_window_end    = objective_window_start + obj.objective_window_s;
            
            m = obj.objective_function.get_metric(objective_window_start, objective_window_end,1);
            
            switch(obj.objective_type) 
                case 'raw' 
                    obj.sample_results(obj.n_samples,1) = m;
                case 'delta'          
                    obj.sample_results(obj.n_samples,1) = m-obj.pre_stimulation_metric;
            end
             
            fprintf(obj.objective_fid,'%f, %f, %e\n', ...
                obj.stimulator.stimulation_time, posixtime(datetime('now')), obj.sample_results(obj.n_samples,1)); 
            
            fprintf(obj.state_fid,'%f, %f, %e\n', ...
                obj.stimulator.stimulation_time, posixtime(datetime('now')), obj.pre_stimulation_metric); 
            fprintf('Objective: %.5e\n', obj.sample_results(obj.n_samples,1));
        end
        
    end
    

end

