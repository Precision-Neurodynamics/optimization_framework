classdef bayesian_optimization < handle
    % BAYESIAN_OPTIMIZATION Summary of this class goes here
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
        running_policy
        
        % Optimization parameters
        control_time
        n_samples
        n_burn_in
        
        policy_parameters
        policy_performance
        
        % Acquisition parameters
        lower_bound
        upper_bound
        x0
        
        % Logging parameters
        objective_fid   
        parameter_fid
        
        optimization_done
      
        stimulator
    end
    
    methods
      
        %%%%%%%%%%%%%%%
        %
        %%%%%%%%%%%%%%%
        function initialize(obj)
            obj.run_start_time_s        = posixtime(datetime);

            obj.optimization_done       = 0;

            obj.objective_fid           = fopen(sprintf('%s/objective_function.csv',...
                                            obj.logging_directory),'a');
            obj.parameter_fid           = fopen(sprintf('%s/parameter.csv',...
                                            obj.logging_directory),'a');
            
            obj.n_samples               = 0;
            obj.reset_time();
            
            obj.running_policy          = 0;
        end
        
        %%%%%%%%%%%%%%%
        %
        %%%%%%%%%%%%%%%
        function optimize(obj)
            
            obj.stimulator.check_stimulation()
            
            this_time  = obj.get_current_time();
%             sprintf('This time = %.2f, obj.evaluate_delay_s = %d, obj.stimulator.stimulation_duration = %d, obj.stimulator.stimulation_time  = %d',...
%                 this_time,  obj.evaluate_delay_s, obj.stimulator.stimulation_duration, obj.stimulator.stimulation_time)
           
            if this_time > ...
                    obj.stimulation_time_s +  obj.cycle_start_time_s && ...
                    obj.stimulator.stimulation_armed
                                   
                obj.select_next_sample();
                obj.pre_stimulation_metric = obj.objective_function.get_metric(obj.stimulator.stimulation_duration);

                if obj.pre_stimulation_metric > obj.state_threshold   
                    obj.stimulator.stimulation_amplitude = 0;
                end
                
                obj.stimulator.generate_stimulation_signal();
                obj.stimulator.write_stimulation_signals();
                obj.stimulator.stimulate()  
                    
            elseif this_time  > ...
                    obj.evaluate_delay_s + obj.stimulator.stimulation_duration + obj.stimulator.stimulation_time && ...
                    ~obj.stimulator.stimulation_armed
                
                obj.evaluate_objective_function(); 
                
                if obj.n_samples >= obj.samples_per_cycle
                    obj.update_parameters();
                end
                
                obj.reset_time();
                obj.stimulator.stimulation_armed = 1;
            end                    
        end
        
        function optimize(obj)
            obj.controller.optimize();  
            
            this_time  = obj.get_current_time();
            
            if ~obj.running_policy
                obj.n_samples       = obj.n_samples+1

                % Caluclate next points
                if obj.n_samples <= obj.n_burn_in
                    obj.policy_parameters(obj.n_samples,:) = rand(1,2).*obj.upper_bound;
                else
                    obj.policy_parameters(obj.n_samples,:) = obj.gp_model.aquisition_function();
                end 
                
                fprintf('Kp = %.7f, Ki = %.7f, ', obj.policy_parameters(obj.n_samples,1), obj.policy_parameters(obj.n_samples,2));
                
                printf('Update the controller\n');
                obj.controller.initialize();
                obj.controller.Kp   = obj.policy_parameters(obj.n_samples,1);
                obj.controller.Ki   = obj.policy_parameters(obj.n_samples,2);
                
                obj.reset_time()
                
                obj.running_policy = 1;
                
            end
            
            if this_time > obj.control_time + obj.cycle_start_time_s && obj.running_policy 
                    
                obj.running_policy = 0;
                
                
                                
                printf('Evaluate performance of controller\n');

                error                                       = obj.controller.error_array;
                obj.policy_performance(obj.n_samples,1)     = -1*(mean(error.*error))^.5;
                obj.controller.error_array                  = [];

                fprintf(' performance = %.4e\n', obj.policy_performance(obj.n_samples));
                    
                if obj.n_samples >= obj.n_burn_in
                    % Update GP model
                    obj.gp_model.initialize_data(obj.policy_parameters, obj.policy_performance) 
                    obj.gp_model.minimize();

                    % Plot data
                    subplot(2,1,1)
                    obj.gp_model.plot_mean();
                    subplot(2,1,2)
                    obj.gp_model.plot_ei();
                    drawnow
                end
                
            end
                           
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
            objective_window_start  = obj.stimulator.stimulation_time + obj.evaluate_delay_s;
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

