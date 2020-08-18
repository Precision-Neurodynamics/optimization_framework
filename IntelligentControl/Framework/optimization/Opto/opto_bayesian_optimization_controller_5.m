classdef opto_bayesian_optimization_controller_5 < handle
    %Latest Version: 010918, used for theta optimization with train/standard pulse
    %Coded for linear model theta optimization
    %(delta theta-pre theta linear model)
    %Train pulse stimulation
    %Outlier updates soon
    
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
        acqparam_fid
        
        optimization_done
        stimulator
        samples_per_cycle
        n_iter
        second_objective_fid
        iter_results
        pre_state_ready
        O_Window
        
        pre_stimulation_metric_control
        sample_results_control
        iter_results_control
        iter_results_delta
        iter_results_OF
        n_restart_I
        
        IIS_flag
        S_th
        metric_control_save
        metric_stim_save
        outlier_flag
    end
    
    methods
        
        %%%%%%%%%%%%%%%
        %
        %%%%%%%%%%%%%%%
        function initialize(obj, gp_model)
            if isempty(obj.samples_per_cycle)
                obj.samples_per_cycle       =10;
            end
            if isempty(obj.O_Window)
                obj.O_Window       = obj.objective_window_s*0.8;
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
            obj.acqparam_fid            = fopen(sprintf('%s/acqparam.csv',obj.logging_directory),'a');
            
            obj.n_samples               = 0;
            obj.n_iter                  = 1;
            
            if nargin == 2
                obj.n_samples = size(gp_model.y_data,1);
                obj.parameter_vector = gp_model.x_data;
                obj.iter_results_delta = gp_model.y_data;
                obj.gp_model = gp_model;
                obj.n_restart_I = size(obj.iter_results_delta,1);
                obj.n_iter                  = size(obj.iter_results_delta,1)+1;
                for i=1:1:obj.n_iter-1
                    fprintf(obj.second_objective_fid,'%f, %f, %e\n', ...
                        obj.stimulator.stimulation_time, posixtime(datetime('now')), obj.iter_results_delta(i,1));
                    s = sprintf('%e,',obj.parameter_vector(i,:));
                    fprintf(obj.parameter_fid,  [s(1:end-1) '\n']);
                end
            end
            if isempty(obj.n_restart_I)
                obj.n_restart_I = 0;
            end
            obj.select_next_sample();
            obj.reset_time();
            obj.pre_state_ready = 1;
            obj.stimulation_time_s = obj.stimulation_time_s + obj.objective_window_s + (obj.objective_window_s - obj.O_Window) * (obj.samples_per_cycle-1) + obj.objective_window_s;
            obj.stimulator.stimulation_duration = obj.stimulator.stimulation_duration + (obj.stimulator.stimulation_duration - obj.O_Window) * (obj.samples_per_cycle-1);
            s = sprintf('%e,',obj.lower_bound);
            fprintf(obj.acqparam_fid,  [s(1:end) '\n']);
            s = sprintf('%e,',obj.upper_bound);
            fprintf(obj.acqparam_fid,  [s(1:end) '\n']);
            
            obj.metric_control_save = [];
            obj.metric_stim_save = [];
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
                
                
                obj.stimulator.generate_stimulation_signal();
                obj.stimulator.write_stimulation_signals();
                obj.stimulator.stimulate()
                obj.pre_state_ready = 1;
                
            elseif this_time  > ...
                    obj.evaluate_delay_s + obj.stimulator.stimulation_duration + obj.stimulator.stimulation_time && ...
                    ~obj.stimulator.stimulation_armed
                
                
                obj.evaluate_objective_function();
                %                 obj.evaluate_second_objective_function();
                if obj.n_iter-1 >= obj.n_burn_in
                    % Update GP model
                    %                         figure(3)
                    obj.gp_model.initialize_data(obj.parameter_vector, obj.iter_results_delta, obj.lower_bound, obj.upper_bound)
                    
                    subplot(1,3,1)
                    obj.gp_model.plot_mean();
                    
                    subplot(1,3,2)
                    obj.gp_model.plot_expected_improvement();
                    view(0,90)
                    
                    subplot(1,3,3)
                    obj.gp_model.plot_confidence_magnitude();
                    view(0,90)
                end
                if obj.outlier_flag~=1
                obj.select_next_sample();
                end
                obj.n_samples = 0;
                
                gp_temp = obj.gp_model;
                save(sprintf('%s/gp_model',obj.logging_directory),'gp_temp');
                obj.reset_time();
                obj.stimulator.stimulation_armed = 1;
            end
        end
        
        function select_next_sample(obj)
            
            if obj.n_iter <= obj.n_burn_in
                obj.parameter_vector(obj.n_iter,:) = rand(1,obj.n_parameters).* (obj.upper_bound - obj.lower_bound) + obj.lower_bound;
            else
                obj.parameter_vector(obj.n_iter,:) = obj.gp_model.discrete_aquisition_function(2, 0.01); %order,
            end
            
            fprintf('Iter: %d\n', obj.n_iter);
            for c1 = 1:obj.n_parameters
                % Update the stimulation parameters
                
                fprintf('\tStimulation %s = %e\n', obj.stimulation_parameter{c1}, obj.parameter_vector(obj.n_iter, c1));
                
                switch obj.stimulation_parameter{c1}
                    case 'train_frequency'
                        obj.stimulator.stimulation_frequency_train    = obj.parameter_vector(obj.n_iter, c1);
                    case 'pulse_frequency'
                        obj.stimulator.stimulation_frequency_pulse    = obj.parameter_vector(obj.n_iter, c1);
                    case 'duration'
                        obj.stimulator.stimulation_duration     = obj.parameter_vector(obj.n_iter, c1);
                    case 'amplitude'
                        obj.stimulator.stimulation_amplitude    = obj.parameter_vector(obj.n_iter, c1);
                    case 'state_threshold'
                        obj.state_threshold                     = obj.parameter_vector(obj.n_iter, c1);
                    case 'pulse_width_train'
                        obj.stimulator.stimulation_pulse_width_train  = obj.parameter_vector(obj.n_iter, c1);
                    case 'pulse_width_pulse'
                        obj.stimulator.stimulation_pulse_width_pulse  = obj.parameter_vector(obj.n_iter, c1);
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
            
            % What we need to transfer : window start time, window end
            % time, samples per cyle, overlap window,
            % Whate we get : Obejctive X (samples+1), 2nd Objective
            % Two performs : one control, one stim
%             S_th = obj.S_th;
            objective_window_start  = obj.stimulator.stimulation_time-obj.stimulator.stimulation_duration-obj.objective_window_s;
            objective_window_end    = obj.stimulator.stimulation_time;
            [metric_control_temp] = obj.objective_function.get_metric(objective_window_start, objective_window_end,obj.objective_window_s,obj.samples_per_cycle,obj.O_Window,0,obj.S_th);
            metric_control = [metric_control_temp; obj.metric_control_save];
            
            objective_window_start  = obj.stimulator.stimulation_time-obj.objective_window_s;
            objective_window_end    = obj.stimulator.stimulation_time + obj.stimulator.stimulation_duration;
            [metric_stim_temp] = obj.objective_function.get_metric(objective_window_start, objective_window_end,obj.objective_window_s,obj.samples_per_cycle,obj.O_Window,1, obj.S_th);
            metric_stim = [metric_stim_temp; obj.metric_stim_save];
            
            if min(sum(~isnan(metric_control(:,1))),sum(~isnan(metric_stim(:,1))))<5
                obj.outlier_flag = 1;
                obj.iter_results_delta(obj.n_iter,:) = 0;
                obj.metric_control_save = [obj.metric_control_save; metric_control_temp];
                obj.metric_stim_save = [obj.metric_stim_save; metric_stim_temp];
                fprintf('control: %d, stim: %d\n',sum(~isnan(metric_control(:,1))),sum(~isnan(metric_stim(:,1))));
            else
                obj.outlier_flag = 0;
                metric_control(isnan(metric_control(:,1)),:) = [];
                metric_stim(isnan(metric_stim(:,1)),:) = [];
                metric_control = metric_control(:,:);
                metric_stim = metric_stim(:,:);
                p_control = polyfit(metric_control(:,2),metric_control(:,1),1);
                p_stim = polyfit(metric_stim(:,2),metric_stim(:,1),1);
                
                obj.sample_results_control{obj.n_iter}(:,1) = metric_control(:,1);
                obj.sample_results_control{obj.n_iter}(:,2) =  metric_control(:,2);
                obj.sample_results{obj.n_iter}(:,1) = metric_stim(:,1);
                obj.sample_results{obj.n_iter}(:,2) =  metric_stim(:,2);
                [metric_control_2, metric_stim_2] = obj.plot_fit(p_control,p_stim);
                
                obj.iter_results_control(obj.n_iter,1) = metric_control_2;
                obj.iter_results_delta(obj.n_iter,1) = metric_stim_2 - metric_control_2;
                obj.iter_results_OF(obj.n_iter,1) = metric_stim_2;
                for samples = 1:1:min(size(metric_control,1),size(metric_stim,1))
                    fprintf(obj.objective_fid,'%f, %f, %e, %e\n', ...
                        obj.stimulator.stimulation_time, posixtime(datetime('now')), obj.sample_results_control{obj.n_iter}(samples,1),obj.sample_results{obj.n_iter}(samples,1));
                    
                    fprintf(obj.state_fid,'%f, %f, %e, %e\n', ...
                        obj.stimulator.stimulation_time, posixtime(datetime('now')), obj.pre_stimulation_metric_control, obj.pre_stimulation_metric);
                    fprintf('Objective_control: %.5e,\t Objective: %.5e\n',obj.sample_results_control{obj.n_iter}(samples,1), obj.sample_results{obj.n_iter}(samples,1));
                end
                
                fprintf('2nd_Objective_control: %.5e\t 2nd_Objective: %.5e\t 2nd_Objective_delta: %.5e\n',obj.iter_results_control(obj.n_iter),obj.iter_results_OF(obj.n_iter),...
                    obj.iter_results_delta(obj.n_iter));
                obj.metric_control_save = [];
                obj.metric_stim_save = [];
            end
            
            if obj.outlier_flag ~= 1 && p_stim(1)<0&&p_control(1)<0&&abs(p_stim(1))>0.1 && abs(p_control(1))>0.1
                s = sprintf('%e,',obj.parameter_vector(obj.n_iter,:));
                fprintf(obj.parameter_fid,  [s(1:end-1) '\n']);
                fprintf(obj.second_objective_fid,'%f, %f, %e\n', ...
                    obj.stimulator.stimulation_time, posixtime(datetime('now')), obj.iter_results_delta(obj.n_iter,1));
                for samples = 1:1:min(size(metric_control,1),size(metric_stim,1))
                    fprintf(obj.objective_fid,'%f, %f, %e, %e\n', ...
                        obj.stimulator.stimulation_time, posixtime(datetime('now')), obj.sample_results_control{obj.n_iter}(samples,1),obj.sample_results{obj.n_iter}(samples,1));
                    fprintf(obj.state_fid,'%f, %f, %e, %e\n', ...
                        obj.stimulator.stimulation_time, posixtime(datetime('now')), obj.pre_stimulation_metric_control, obj.pre_stimulation_metric);
                end
                
                obj.n_iter = obj.n_iter+1;
            else
                obj.n_iter = obj.n_iter;
%                 obj.iter_results_delta(obj.n_iter) = [];
%                 obj.parameter_vector(obj.n_iter,:) = [];
            end
            obj.pre_state_ready = 1;
            
        end
        
        function [metric_control_2, metric_stim_2]= plot_fit(obj,p_control,p)
            figure(2)
            plot(obj.sample_results_control{obj.n_iter}(:,2),obj.sample_results_control{obj.n_iter}(:,1),'+')
            hold on
            plot(obj.sample_results{obj.n_iter}(:,2),obj.sample_results{obj.n_iter}(:,1),'r+')
            x_min = min([obj.sample_results_control{obj.n_iter}(:,2); obj.sample_results{obj.n_iter}(:,2)]);
            x_max = max([obj.sample_results_control{obj.n_iter}(:,2); obj.sample_results{obj.n_iter}(:,2)]);
            d = (x_max-x_min)/99;
            x = [x_min:d:x_max];
            plot(x,p_control(1)*x+p_control(2),'b')
            plot(x,p(1)*x+p(2),'r')
            hold off
            drawnow
            if (x_max*p_control(1)+p_control(2))*(x_min*p_control(1)+p_control(2)) < 0
                metric_control_2 = (-p_control(2)/p_control(1)-x_min)*(p_control(1)*x_min+p_control(2))/2 + (x_max+p_control(2)/p_control(1))*(p_control(1)*x_max+p_control(2))/2;
            else
                metric_control_2 = ((x_max*p_control(1)+p_control(2))+(x_min*p_control(1)+p_control(2)))*(x_max-x_min)/2;
            end
            
            if (x_max*p(1)+p(2))*(x_min*p(1)+p(2)) < 0
                metric_stim_2 = (-p(2)/p(1)-x_min)*(p(1)*x_min+p(2))/2 + (x_max+p(2)/p(1))*(p(1)*x_max+p(2))/2;
            else
                metric_stim_2 = ((x_max*p(1)+p(2))+(x_min*p(1)+p(2)))*(x_max-x_min)/2;
            end
        end
    end
    
    
end

