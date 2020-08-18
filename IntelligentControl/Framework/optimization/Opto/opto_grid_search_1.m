
classdef opto_grid_search_1 < handle
    %GRID_SEARCH Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        f_sample
        TD
        device_name
        video_filename
        
        % Stimulation parameters
        frequency
        duration
        amplitude
        width
        stim_channels
        
        
        % Timing parameters
        run_start_time_s
        cycle_start_time_s
        this_time_s
        last_time_s
        
        stimulation_time_s
        evaluate_time_s
        evaluate_delay_s

        % Search parameters
        n_samples
        n_parameters
        parameter_vector
        n_repetitions
        
        % Logging parameters
        logging_directory
        stimulation_fid
        objective_fid   
        parameter_fid
        display_log_output
        
        optimization_done
        random_flag
        combvec_flag
        rep_flag
        stimulator
    end
    
    methods
 
        function obj = initialize(obj)
            obj.device_name             = obj.TD.GetDeviceName(0);
            obj.f_sample                = obj.TD.GetDeviceSF(obj.device_name);
            
            obj.run_start_time_s        = posixtime(datetime);
            obj.cycle_start_time_s      = posixtime(datetime);
            obj.last_time_s             = posixtime(datetime);
            obj.this_time_s             = posixtime(datetime); 
            if obj.combvec_flag == 1
                param_temp        = combvec(obj.frequency, obj.duration, obj.amplitude, obj.width)'; %For all combination
            else
                param_temp        = [obj.frequency, obj.duration, obj.amplitude, obj.width]'; % For the aligned row
            end
            if obj.rep_flag == 1
                for i=1:1:size(param_temp,1)
                    obj.parameter_vector(obj.n_repetitions*(i-1)+1:obj.n_repetitions*i,:) = repmat(param_temp(i,:), obj.n_repetitions,1);
                end
            else
                obj.parameter_vector        = repmat(param_temp, obj.n_repetitions,1);
            end
            
            if obj.random_flag ~= 0
            rng(obj.random_flag); %Known order?
            rand_idx                    = randperm(size(obj.parameter_vector,1));
            obj.parameter_vector        = obj.parameter_vector(rand_idx,:);
            end
            obj.optimization_done       = 0;
        end
        
        %%%%%%%%%%%%%%%
        %
        %%%%%%%%%%%%%%%
        function optimize(obj)
%             obj.stimulator.check_stimulation()
            obj.this_time_s = posixtime(datetime);
            
            this_time       = obj.this_time_s - obj.cycle_start_time_s;
                    
            if this_time > obj.stimulation_time_s && obj.stimulator.stimulation_armed
                
                sample_count_output = sprintf('Sample: %d/%d\t', obj.n_samples, size(obj.parameter_vector,1));
                switch obj.display_log_output
                    case 'verbose'
                        fprintf(sample_count_output);
                    case 'simple'
                        fprintf(sample_count_output);
                end
                
                obj.stimulator.stimulation_frequency    = obj.parameter_vector(obj.n_samples,1);
                obj.stimulator.stimulation_duration     = obj.parameter_vector(obj.n_samples,2);
                obj.stimulator.stimulation_amplitude    = obj.parameter_vector(obj.n_samples,3);
                obj.stimulator.stimulation_pulse_width  = obj.parameter_vector(obj.n_samples,4);
                
                obj.TD.SetTargetVal([obj.stimulator.device_name '.nPeriod'],obj.stimulator.sampling_frequency/obj.stimulator.stimulation_frequency);
                obj.TD.SetTargetVal([obj.stimulator.device_name '.nPulses'],obj.stimulator.stimulation_frequency * obj.stimulator.stimulation_duration);
                % optimizer.width                     = 2/stimulation_manager.sampling_frequency;
                obj.TD.SetTargetVal([obj.stimulator.device_name '.nDur-A'],obj.stimulator.sampling_frequency/1000*obj.stimulator.stimulation_pulse_width);
                obj.TD.SetTargetVal([obj.stimulator.device_name '.nDur-B'],5); % Useless
                obj.TD.SetTargetVal([obj.stimulator.device_name '.Amp-A'],obj.stimulator.stimulation_amplitude);
                
%                 if ~isnan(obj.parameter_vector(obj.n_samples,5))
%                     obj.stimulator.stimulation_channels     = obj.parameter_vector(obj.n_samples,5);
%                 else
%                 end
%                 obj.stimulator.generate_stimulation_signal(); % comment
%                 obj.stimulator.write_stimulation_signals(); % comment
                obj.stimulator.stimulate()
                obj.n_samples                           = obj.n_samples + 1;  

            elseif this_time - (obj.stimulation_time_s + obj.stimulator.stimulation_duration) > obj.evaluate_delay_s
                reset_time(obj)
                obj.stimulator.stimulation_armed = 1;                     
                
                if obj.n_samples > size(obj.parameter_vector,1)
                    obj.optimization_done = 1;
                end
            end            
        end

        %%%%%%%%%%%%%%%
        % Resets the clock to start another stimulation trial
        %%%%%%%%%%%%%%%
        function reset_time(obj)
            obj.cycle_start_time_s   = posixtime(datetime);
            obj.last_time_s          = posixtime(datetime);
            obj.this_time_s          = posixtime(datetime);
        end
    end
end

