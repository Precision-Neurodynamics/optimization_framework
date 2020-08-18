classdef opto_bayesian_optimization_controller < handle
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
                %                 obj.TD.SetTargetVal([obj.stimulator.device_name '.nPeriod'],obj.stimulator.sampling_frequency/obj.stimulator.stimulation_frequency);
                %                 obj.TD.SetTargetVal([obj.stimulator.device_name '.nPulses'],obj.stimulator.stimulation_frequency * obj.stimulator.stimulation_duration);
                %                 % optimizer.width                     = 2/stimulation_manager.sampling_frequency;
                %                 obj.TD.SetTargetVal([obj.stimulator.device_name '.nDur-A'],obj.stimulator.sampling_frequency/1000*obj.stimulator.stimulation_pulse_width);
                %                 obj.TD.SetTargetVal([obj.stimulator.device_name '.nDur-B'],5); % Useless
                %                 obj.TD.SetTargetVal([obj.stimulator.device_name '.Amp-A'],obj.stimulator.stimulation_amplitude);
                obj.stimulator.generate_stimulation_signal();
                obj.stimulator.write_stimulation_signals();
                %%%%%%%%%%%%%%%%%%%%
                
                obj.stimulator.stimulate()  
                
            elseif this_time  > ...
                    obj.evaluate_delay_s + obj.stimulator.stimulation_duration + obj.stimulator.stimulation_time && ...
                    ~obj.stimulator.stimulation_armed
                
                obj.evaluate_objective_function(); 
                figure(3)
                if obj.n_samples >= obj.n_burn_in
                    % Update GP model
                    obj.gp_model.initialize_data(obj.parameter_vector(1:length(obj.sample_results),:), obj.sample_results, obj.lower_bound, obj.upper_bound) 
                    % Plot GP model
                    if size(obj.lower_bound,2)<3
                        subplot(1,3,1)
                        obj.gp_model.plot_mean();
                        
                        subplot(1,3,2)
                        obj.gp_model.plot_expected_improvement();
                        view(0,90)
                        
                        subplot(1,3,3)
                        obj.gp_model.plot_confidence_magnitude();
                        view(0,90)
                    elseif size(obj.lower_bound,2) == 3
                        [x_max, y_max, x_min, y_min]  = obj.gp_model.discrete_extrema(2);
                        subplot(4,1,1);
                        title('Optimization Progress');
                        plot(obj.parameter_vector(:,1)); xlabel('Samples'); ylabel('Amplitude');
                        hold on; plot(size(obj.parameter_vector,1), x_max(1), 'bo');
                        subplot(4,1,2); 
                        plot(obj.parameter_vector(:,2)); xlabel('Samples'); ylabel('Frequency');
                        hold on; plot(size(obj.parameter_vector,1), x_max(2), 'bo');
                        subplot(4,1,3); 
                        
                        plot(obj.parameter_vector(:,3)); xlabel('Samples'); ylabel('Pulse Width');
                        hold on; plot(size(obj.parameter_vector,1), x_max(3), 'bo');
                        subplot(4,1,4); 
                        
                        plot(obj.sample_results); xlabel('Samples'); ylabel('Objective Function');
                        hold on; plot(size(obj.parameter_vector,1), y_max, 'bo');
                        
                    end
                end
                
                
                gp_temp = obj.gp_model;
                save(sprintf('%s/gp_model',obj.logging_directory),'gp_temp');
                obj.reset_time();
                obj.stimulator.stimulation_armed = 1;
            end  
                   
        end
        
        function select_next_sample(obj)
            
            if obj.n_samples <= obj.n_burn_in
                obj.parameter_vector(obj.n_samples,:) = rand(1,obj.n_parameters).* (obj.upper_bound - obj.lower_bound) + obj.lower_bound;
            else
                obj.parameter_vector(obj.n_samples,:) = obj.gp_model.discrete_aquisition_function(2, 0.4); %grid order (10 to ?), hyperparam
            
                obj.parameter_vector(obj.n_samples,:);
            end
            
            fprintf('Sample: %d\n', obj.n_samples);
            for c1 = 1:obj.n_parameters
                % Update the stimulation parameters
                
                fprintf('\tStimulation %s = %e\n', obj.stimulation_parameter{c1}, obj.parameter_vector(obj.n_samples, c1));
                
%                 switch obj.stimulation_parameter{c1}
%                     case 'frequency'
%                         obj.stimulator.stimulation_frequency    = obj.parameter_vector(obj.n_samples, c1);
%                     case 'duration'
%                         obj.stimulator.stimulation_duration     = obj.parameter_vector(obj.n_samples, c1);
%                     case 'amplitude'
%                         obj.stimulator.stimulation_amplitude    = obj.parameter_vector(obj.n_samples, c1);
%                     case 'state_threshold'
%                         obj.state_threshold                     = obj.parameter_vector(obj.n_samples, c1);
%                     case 'pulse_width'
%                         obj.stimulator.stimulation_pulse_width  = obj.parameter_vector(obj.n_samples, c1);
%                 end
                switch obj.stimulation_parameter{c1}
                    case 'train_frequency'
                        obj.stimulator.stimulation_frequency_train      = obj.parameter_vector(obj.n_samples, c1);
                    case 'pulse_frequency'
                        obj.stimulator.stimulation_frequency_pulse      = obj.parameter_vector(obj.n_samples, c1);
                    case 'duration'
                        obj.stimulator.stimulation_duration             = obj.parameter_vector(obj.n_samples, c1);
                    case 'amplitude'
                        obj.stimulator.stimulation_amplitude            = obj.parameter_vector(obj.n_samples, c1);
                    case 'state_threshold'
                        obj.state_threshold                             = obj.parameter_vector(obj.n_samples, c1);
                    case 'train_width'
                        obj.stimulator.stimulation_pulse_width_train    = obj.parameter_vector(obj.n_samples, c1);
                    case 'pulse_width'
                        obj.stimulator.stimulation_pulse_width_pulse    = obj.parameter_vector(obj.n_samples, c1);
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
            objective_window_prestart   = obj.stimulator.stimulation_time - obj.objective_window_s;
            objective_window_start      = obj.stimulator.stimulation_time;
            objective_window_end        = objective_window_start + obj.objective_window_s;
            if(objective_window_prestart < 0)
                a = 1;
            end
                
            obj.pre_stimulation_metric  = obj.objective_function.get_metric(objective_window_prestart, objective_window_start,0);
            
            fprintf('Pre-stimulation state = %e\n', obj.pre_stimulation_metric);
            m = obj.objective_function.get_metric(objective_window_start, objective_window_end,1);
            
            if ~strcmp(obj.objective_type,'threshold') || obj.pre_stimulation_metric<0.1;
                if ~isnan(m) && ~isnan(obj.pre_stimulation_metric)
                    switch(obj.objective_type)
                        case 'raw'
                            if strcmp(obj.optimization_direction,'maximize')
                                sign = 1;
                            elseif strcmp(obj.optimization_direction,'minimize')
                                sign = -1;
                            end
                            obj.sample_results(obj.n_samples,1) = sign*m;
                            
                        case 'delta'
                            if strcmp(obj.optimization_direction,'maximize')
                                sign = 1;
                            elseif strcmp(obj.optimization_direction,'minimize')
                                sign = -1;
                            end
                            obj.sample_results(obj.n_samples,1) = sign*(m-obj.pre_stimulation_metric);
                            
                       case 'complex'
                            if strcmp(obj.optimization_direction,'maximize')
                                sign = 1;
                            elseif strcmp(obj.optimization_direction,'minimize')
                                sign = -1;
                            end
                            obj.sample_results(obj.n_samples,1) = sign*((m-obj.pre_stimulation_metric+1)*(1+obj.pre_stimulation_metric));
                            
                        case 'target'
                            if strcmp(obj.optimization_direction,'maximize')
                                sign = 1;
                            elseif strcmp(obj.optimization_direction,'minimize')
                                sign = -1;
                            end
                            obj.sample_results(obj.n_samples,1) = sign*(abs(m-obj.target_metric));

                    end
                    
                    fprintf(obj.objective_fid,'%f, %f, %e\n', ...
                        obj.stimulator.stimulation_time, posixtime(datetime('now')), obj.sample_results(obj.n_samples,1));
                    
                    fprintf(obj.state_fid,'%f, %f, %e\n', ...
                        obj.stimulator.stimulation_time, posixtime(datetime('now')), obj.pre_stimulation_metric);
                    fprintf('Objective: %.5e\n', obj.sample_results(obj.n_samples,1));
                    
                    obj.n_samples = obj.n_samples+1;
                else
                    %                 obj.parameter_vector(obj.n_samples,:) = [];
                end
            end
        end
        
    end
    

end

