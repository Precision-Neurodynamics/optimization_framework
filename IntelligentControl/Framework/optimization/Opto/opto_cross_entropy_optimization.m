classdef opto_cross_entropy_optimization < handle
    %CROSS_ENTROPY_OPTIMIZATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        TD
        device_name
        sampling_frequency
        logging_directory
        
        % Stimulation parameters
        stimulation_type
        f_stimulation_range
        duration_range
        amplitude_range
        width_range
        stim_channels
         
        stimulation_frequency
        duration
        amplitude
        width
        
        state_threshold
        
        % Timing parameters
        run_start_time_s
        cycle_start_time_s
        this_time_s
        last_time_s
        
        stimulation_time_s
        evaluate_time_s
        evaluate_delay_s
        
        % Optimization parameters
        samples_per_cycle
        sample_results
        n_samples
        n_elite_samples
        n_parameters
        learning_rate
        
        mu_norm
        sigma_norm
        
        mu_scaled
        sigma_scaled
        
        lower_bound
        upper_bound
        parameter_vector_norm
        parameter_vector_scaled
        stimulation_parameter
        
        scale_factor_m
        scale_factor_b
        
        objective_function
        objective_window_s
        pre_stimulation_metric
        
        % optimization_direction
        %   'maximize'  searches for maximum of objective function
        %   'minimize'  searches for minimum of objective function                        
        optimization_direction
        
        % objective_type values: 
        %   'raw'   evaluates post-stimulation metric
        %   'delta' evaluates the change in the metric from pre- to
        %   post-stimualtion
        objective_type          
        
        % distribution values:
        %   'gaussian'  Normal distribution parameterized by a mean (mu)
        %   and standard deviation (sigma). Can be restricted to a lower
        %   bound and upper bound
        %   'uniform'   Uniform distribution with upper and lower bounds 
        distribution
        
        % Logging parameters
        stimulation_fid
        objective_fid   
        state_fid
        mu_fid
        sigma_fid
        
        optimization_done
        stimulator
    end
    
    methods
      
        %%%%%%%%%%%%%%%
        %
        %%%%%%%%%%%%%%%
        function initialize(obj)
            obj.run_start_time_s        = posixtime(datetime);
            obj.sample_results          = nan(obj.samples_per_cycle,1);
            obj.n_samples               = 0;
            
            obj.optimization_done       = 0;

            obj.parameter_vector_norm   = nan(obj.samples_per_cycle, obj.n_parameters);
            obj.parameter_vector_scaled = nan(obj.samples_per_cycle, obj.n_parameters);
            
            obj.scale_factor_m          = (obj.upper_bound - obj.lower_bound) / 2;
            obj.scale_factor_b          = (obj.upper_bound + obj.lower_bound) / 2;
            
            obj.mu_norm                 = zeros(1,obj.n_parameters);
            obj.sigma_norm              = eye(obj.n_parameters);
            
            obj.mu_scaled               = obj.mu_norm .* obj.scale_factor_m + obj.scale_factor_b;
            obj.sigma_scaled            = diag(obj.upper_bound);
            
            obj.objective_fid           = fopen(sprintf('%s/objective_function.csv',...
                                            obj.logging_directory),'a');
            
            obj.state_fid               = fopen(sprintf('%s/state_function.csv',...
                                            obj.logging_directory),'a');
                                        
            obj.mu_fid                  = fopen(sprintf('%s/parameter_mu.csv',...
                                            obj.logging_directory),'a');
                                        
            obj.sigma_fid               = fopen(sprintf('%s/parameter_sigma.csv',...
                                            obj.logging_directory),'a');
            obj.reset_time();
        end
        
        %%%%%%%%%%%%%%%
        %
        %%%%%%%%%%%%%%%
        function optimize(obj)
            
%             obj.stimulator.check_stimulation()
            
            this_time  = obj.get_current_time();
%             sprintf('This time = %.2f, obj.evaluate_delay_s = %d, obj.stimulator.stimulation_duration = %d, obj.stimulator.stimulation_time  = %d',...
%                 this_time,  obj.evaluate_delay_s, obj.stimulator.stimulation_duration, obj.stimulator.stimulation_time)
           
            if this_time > ...
                    obj.stimulation_time_s +  obj.cycle_start_time_s && ...
                    obj.stimulator.stimulation_armed
                                   
                obj.select_next_sample();
%                 obj.pre_stimulation_metric = obj.objective_function.get_metric(obj.stimulator.stimulation_duration);
                obj.pre_stimulation_metric = obj.objective_function.get_metric(obj.stimulator.stimulation_duration); % The input is the length 
                
%                 if obj.pre_stimulation_metric > obj.state_threshold   
%                     obj.stimulator.stimulation_amplitude = 0;
%                 end


                
%                 obj.stimulator.generate_stimulation_signal(); %Electrical
%                 obj.stimulator.write_stimulation_signals(); %Electrical
                
                obj.TD.SetTargetVal([obj.stimulator.device_name '.nPeriod'],obj.stimulator.sampling_frequency/obj.stimulator.stimulation_frequency);
                obj.TD.SetTargetVal([obj.stimulator.device_name '.nPulses'],obj.stimulator.stimulation_frequency * obj.stimulator.stimulation_duration);
                % optimizer.width                     = 2/stimulation_manager.sampling_frequency;
                obj.TD.SetTargetVal([obj.stimulator.device_name '.nDur-A'],obj.stimulator.sampling_frequency/1000*obj.stimulator.stimulation_pulse_width);
                obj.TD.SetTargetVal([obj.stimulator.device_name '.nDur-B'],5); % Useless
                if obj.stimulator.stimulation_amplitude > 4.6 %put the value of the voltage corresponding to 50I
                    obj.TD.SetTargetVal([obj.stimulator.device_name '.Amp-A'],3);
                else
                    obj.TD.SetTargetVal([obj.stimulator.device_name '.Amp-A'],obj.stimulator.stimulation_amplitude);
                end

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
        
        %%%%%%%%%%%%%%%
        % Resets the clock to start another stimulation trial
        %%%%%%%%%%%%%%%
        function reset_time(obj)
            obj.cycle_start_time_s   = obj.get_current_time();
            obj.last_time_s          = obj.get_current_time();
            obj.this_time_s          = obj.get_current_time();
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
        
        
        %%%%%%%%%%%%%%%
        % Only set up for single parameter search
        %%%%%%%%%%%%%%%
        function  select_next_sample(obj)
            obj.n_samples = obj.n_samples + 1;
                    
            % Determine stimulation distribution
            switch obj.distribution
                
                case 'gaussian'
                    
                    % Select parameter from constrained Gaussian
                    params = mvnrnd(obj.mu_norm,obj.sigma_norm, 1);
                    while any(params < -1) || any(params > 1)
                        params = mvnrnd(obj.mu_norm,obj.sigma_norm, 1);
                    end

                    % Save to object
                    obj.parameter_vector_scaled(obj.n_samples, :)   = params.*obj.scale_factor_m + obj.scale_factor_b;
                    obj.parameter_vector_norm(obj.n_samples, :)     = params;

                case 'uniform'
                    
                    % Select parameter from a uniform distribution
                    obj.parameter_vector_scaled(obj.n_samples) = obj.lower_bound + (obj.upper_bound - obj.lower_bound)*rand();
                
            end
            
           
            fprintf('Sample: %d\n',obj.n_samples);
            
            for c1 = 1:obj.n_parameters
                % Update the stimulation parameters
                fprintf('\tStimulation %s = %e\n', obj.stimulation_parameter{c1}, obj.parameter_vector_scaled(obj.n_samples, c1));

                switch obj.stimulation_parameter{c1}
                    case 'frequency'
                        obj.stimulator.stimulation_frequency    = obj.parameter_vector_scaled(obj.n_samples, c1);
                    case 'duration'
                        obj.stimulator.stimulation_duration     = obj.parameter_vector_scaled(obj.n_samples, c1);
                    case 'amplitude'
                        obj.stimulator.stimulation_amplitude    = obj.parameter_vector_scaled(obj.n_samples, c1);
                    case 'state_threshold'
                        obj.state_threshold                     = obj.parameter_vector_scaled(obj.n_samples, c1);
                    case 'pulse_width'
                        obj.stimulator.stimulation_pulse_width  = obj.parameter_vector_scaled(obj.n_samples, c1);
                end
                
            end
            
            fprintf('\n');
        end
        
       
        
        %%%%%%%%%%%%%%%
        % Identifies the elite samples to update the sampling distribution
        %%%%%%%%%%%%%%%
        function update_parameters(obj)
            
            switch obj.optimization_direction
                case 'maximize'
                     [~, sorted_idx] = sort(obj.sample_results,'descend');
                case 'minimize'
                     [~, sorted_idx] = sort(obj.sample_results,'ascend');
            end
            
            old_mu_norm         = obj.mu_norm;
            old_sigma_norm      = obj.sigma_norm;

            old_mu_scaled       = obj.mu_scaled;
            old_sigma_scaled    = obj.sigma_scaled;
            
            elite_idx           = sorted_idx(1:obj.n_elite_samples);
            
            elite_mu_norm       = mean(obj.parameter_vector_norm(elite_idx,:),1);
            elite_sigma_norm    = cov(obj.parameter_vector_norm(elite_idx,:),1); 

            elite_mu_scaled     = mean(obj.parameter_vector_scaled(elite_idx,:),1);
            elite_sigma_scaled  = cov(obj.parameter_vector_scaled(elite_idx,:),1);       
            
            obj.mu_norm         = obj.learning_rate*elite_mu_norm + (1 - obj.learning_rate)*old_mu_norm;
            obj.sigma_norm      = obj.learning_rate*elite_sigma_norm + (1 - obj.learning_rate)*old_sigma_norm;
            
            obj.mu_scaled       = obj.learning_rate*elite_mu_scaled + (1 - obj.learning_rate)*old_mu_scaled;
            obj.sigma_scaled    = obj.learning_rate*elite_sigma_scaled + (1 - obj.learning_rate)*old_sigma_scaled;
            
            obj.n_samples   = 0;
            
            format shortG
            
            fprintf('Ojective: \n\tmean = %.3e \n\tstd = %.3e\n', mean(obj.sample_results), std(obj.sample_results));
            fprintf('\n\nmu\n');
            disp(old_mu_scaled)
            fprintf('\t\t\t |\n\n')
            disp(obj.mu_scaled)

            fprintf('sigma\n')
            disp(old_sigma_scaled)
            fprintf('\t\t\t |\n\n')
            disp(obj.sigma_scaled)
            
            fprintf(obj.mu_fid, '%f', posixtime(datetime('now')));
            fprintf(obj.mu_fid, ',%e', obj.mu_scaled);
            fprintf(obj.mu_fid, '\n');
            
            fprintf(obj.sigma_fid, '%f', posixtime(datetime('now')));
            fprintf(obj.sigma_fid, ',%e', obj.sigma_scaled);
            fprintf(obj.sigma_fid, '\n');
           
            
        end   
        

        function t = get_current_time(obj)
            t = obj.TD.ReadTargetVEX([obj.device_name '.current_time'], 0, 1, 'I32', 'F64')/obj.sampling_frequency;
        end
    end    
end

