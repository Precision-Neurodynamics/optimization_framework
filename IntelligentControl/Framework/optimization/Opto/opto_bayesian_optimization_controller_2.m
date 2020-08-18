classdef opto_bayesian_optimization_controller_2 < handle
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
        
        
        % Acquisition parameters
        lower_bound
        upper_bound
        
        % Logging parameters
        objective_fid   
        parameter_fid
        state_fid
        
        optimization_done
        stimulator
        samples_per_cycle
        n_iter
        second_objective_fid
        iter_results
        pre_state_ready
    end
    
    methods
      
        %%%%%%%%%%%%%%%
        %
        %%%%%%%%%%%%%%%
        function initialize(obj, gp_model)
            if isempty(obj.samples_per_cycle)
                obj.samples_per_cycle       =5;
            end
            
            obj.run_start_time_s        = posixtime(datetime);

            obj.optimization_done       = 0;

            obj.objective_fid           = fopen(sprintf('%s/objective_function.csv',...
                                            obj.logging_directory),'a');
            obj.parameter_fid           = fopen(sprintf('%s/parameter.csv',...
                                            obj.logging_directory),'a');
            obj.state_fid               = fopen(sprintf('%s/state_function.csv',...
                obj.logging_directory),'a');
            obj.second_objective_fid       = fopen(sprintf('%s/second_objective_function.csv',...
                                            obj.logging_directory),'a');
           
            obj.n_samples               = 0;
            obj.n_iter                  = 1;
            
            if nargin == 2
                 obj.n_samples = size(gp_model.y_data,1);
                 obj.parameter_vector = gp_model.x_data;
                 obj.iter_results = gp_model.y_data;
                 obj.gp_model = gp_model;
            end
            obj.select_next_sample();
            obj.reset_time();
            obj.pre_state_ready = 1;
        end
        
        %%%%%%%%%%%%%%%
        %
        %%%%%%%%%%%%%%%
        function optimize(obj)
            
%             obj.stimulator.check_stimulation()
            
            this_time  = obj.get_current_time();

            if (this_time > ...
                obj.stimulation_time_s*obj.pre_state_ready+  obj.cycle_start_time_s) && ...
                obj.stimulator.stimulation_armed
            
               
                obj.pre_stimulation_metric = obj.objective_function.get_metric(obj.stimulator.stimulation_duration);

                obj.TD.SetTargetVal([obj.stimulator.device_name '.nPeriod'],obj.stimulator.sampling_frequency/obj.stimulator.stimulation_frequency);
                obj.TD.SetTargetVal([obj.stimulator.device_name '.nPulses'],obj.stimulator.stimulation_frequency * obj.stimulator.stimulation_duration);
                % optimizer.width                     = 2/stimulation_manager.sampling_frequency;
                obj.TD.SetTargetVal([obj.stimulator.device_name '.nDur-A'],obj.stimulator.sampling_frequency/1000*obj.stimulator.stimulation_pulse_width);
                obj.TD.SetTargetVal([obj.stimulator.device_name '.nDur-B'],5); % Useless
                obj.TD.SetTargetVal([obj.stimulator.device_name '.Amp-A'],obj.stimulator.stimulation_amplitude);
                obj.stimulator.stimulate()  
                obj.pre_state_ready = 0;
                
            elseif this_time  > ...
                    obj.evaluate_delay_s + obj.stimulator.stimulation_duration + obj.stimulator.stimulation_time && ...
                    ~obj.stimulator.stimulation_armed
                
                
                obj.evaluate_objective_function();
                if obj.n_samples >= obj.samples_per_cycle
                    obj.evaluate_second_objective_function();
                    if obj.n_iter-1 >= obj.n_burn_in
                        % Update GP model
                        obj.gp_model.initialize_data(obj.parameter_vector, obj.iter_results, obj.lower_bound, obj.upper_bound)
                        
                        subplot(1,3,1)
                        obj.gp_model.plot_mean();
                        
                        subplot(1,3,2)
                        obj.gp_model.plot_expected_improvement();
                        view(0,90)
                        
                        subplot(1,3,3)
                        obj.gp_model.plot_confidence_magnitude();
                        view(0,90)
                    end
                    obj.select_next_sample();
                    obj.n_samples = 0;
                end
                obj.reset_time();
                obj.stimulator.stimulation_armed = 1;
            end  
                   
        end
        
        function select_next_sample(obj)
            
            if obj.n_iter <= obj.n_burn_in
                obj.parameter_vector(obj.n_iter,:) = rand(1,obj.n_parameters).* (obj.upper_bound - obj.lower_bound) + obj.lower_bound;
            else
                obj.parameter_vector(obj.n_iter,:) = obj.gp_model.discrete_aquisition_function(2, 0.01); %order, 
            
                obj.parameter_vector(obj.n_iter,:);
            end
            
            fprintf('Iter: %d\n', obj.n_iter);
            for c1 = 1:obj.n_parameters
                % Update the stimulation parameters
                
                fprintf('\tStimulation %s = %e\n', obj.stimulation_parameter{c1}, obj.parameter_vector(obj.n_iter, c1));
                
                switch obj.stimulation_parameter{c1}
                    case 'frequency'
                        obj.stimulator.stimulation_frequency    = obj.parameter_vector(obj.n_iter, c1);
                    case 'duration'
                        obj.stimulator.stimulation_duration     = obj.parameter_vector(obj.n_iter, c1);
                    case 'amplitude'
                        obj.stimulator.stimulation_amplitude    = obj.parameter_vector(obj.n_iter, c1);
                    case 'state_threshold'
                        obj.state_threshold                     = obj.parameter_vector(obj.n_iter, c1);
                    case 'pulse_width'
                        obj.stimulator.stimulation_pulse_width  = obj.parameter_vector(obj.n_iter, c1);
                end
                
            end
            
            s = sprintf('%e,',obj.parameter_vector(obj.n_iter,:));
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
            obj.n_samples = obj.n_samples+1;
            
            objective_window_start  = obj.stimulator.stimulation_time;
            objective_window_end    = objective_window_start + obj.objective_window_s;
            fprintf('Pre-stimulation state = %e\n', obj.pre_stimulation_metric);
            m = obj.objective_function.get_metric(objective_window_start, objective_window_end,1);
            
            switch(obj.objective_type) 
                case 'raw' 
                    if strcmp(obj.optimization_direction,'maximize')
                        sign = 1;
                    elseif strcmp(obj.optimization_direction,'minimize')
                        sign = -1;
                    end
                    obj.sample_results(obj.n_iter,obj.n_samples,1) = sign*m;
                case 'delta'          
                    if strcmp(obj.optimization_direction,'maximize')
                        sign = 1;
                    elseif strcmp(obj.optimization_direction,'minimize')
                        sign = -1;
                    end
                    obj.sample_results(obj.n_iter,obj.n_samples,1) = sign*(m-obj.pre_stimulation_metric);
                    obj.sample_results(obj.n_iter,obj.n_samples,2) = sign* obj.pre_stimulation_metric;
            end
             
            fprintf(obj.objective_fid,'%f, %f, %e\n', ...
                obj.stimulator.stimulation_time, posixtime(datetime('now')), obj.sample_results(obj.n_iter,obj.n_samples,1)); 
            
            fprintf(obj.state_fid,'%f, %f, %e\n', ...
                obj.stimulator.stimulation_time, posixtime(datetime('now')), obj.pre_stimulation_metric); 
            fprintf('Objective: %.5e\n', obj.sample_results(obj.n_iter,obj.n_samples,1));
        end
        
        function evaluate_second_objective_function(obj)
            
            [p,S] = polyfit(squeeze(obj.sample_results(obj.n_iter,:,2)),squeeze(obj.sample_results(obj.n_iter,:,1)),1);
            obj.iter_results(obj.n_iter,1) =  -(p(2)^2/p(1)); %p(1) = slope, p(2) = y intercept
             
            fprintf(obj.second_objective_fid,'%f, %f, %e\n', ...
                obj.stimulator.stimulation_time, posixtime(datetime('now')), obj.iter_results(obj.n_iter,1));
            fprintf('2nd_Objective: %.5e\n', obj.iter_results(obj.n_iter));
            obj.n_iter = obj.n_iter+1;
            obj.pre_state_ready = 1;
        end
        
    end
    

end

