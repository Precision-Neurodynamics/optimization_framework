classdef opto_grid_search_3 < handle
    %GRID_SEARCH Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        f_sample
        TD
        device_name
        video_filename
        
        % Stimulation parameters
        frequency_pulse
        frequency_train
        duration
        amplitude
        width_pulse
        width_train
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
        
        N_seg
        sequence
        isfirst
        param_temp
    end
    
    methods
 
        function obj = initialize(obj)
            obj.device_name             = obj.TD.GetDeviceName(0);
            obj.f_sample                = obj.TD.GetDeviceSF(obj.device_name);
            
            obj.run_start_time_s        = posixtime(datetime);
            obj.cycle_start_time_s      = posixtime(datetime);
            obj.last_time_s             = posixtime(datetime);
            obj.this_time_s             = posixtime(datetime);
            obj.isfirst                 = 1;
            if obj.sequence == 1
                
            else
                if obj.combvec_flag == 1
                    param_temp        = combvec(obj.frequency_train,obj.frequency_pulse, obj.duration, obj.amplitude, obj.width_train, obj.width_pulse)'; %For all combination
                else
                    param_temp        = [obj.frequency_train',obj.frequency_pulse', obj.duration', obj.amplitude', obj.width_train', obj.width_pulse']; % For the aligned row
                end
                obj.param_temp = param_temp;
                if obj.rep_flag == 1
                    for i=1:1:size(param_temp,1)
                        obj.parameter_vector(obj.n_repetitions*(i-1)+1:obj.n_repetitions*i,:) = repmat(param_temp(i,:), obj.n_repetitions,1);
                    end
                else
                    obj.parameter_vector        = repmat(param_temp, obj.n_repetitions,1);
                end
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
            if obj.n_samples == 1 && obj.isfirst == 1
                reset_time(obj);
                obj.isfirst = 0;
            end
            obj.this_time_s = posixtime(datetime);
            
            this_time       = obj.this_time_s - obj.cycle_start_time_s;

            if this_time > obj.stimulation_time_s && (~obj.stimulator.is_stimulating() && obj.stimulator.stimulation_armed) %this_time > obj.stimulation_time_s && obj.stimulator.stimulation_armed && ~obj.stimulator.is_stimulating()
%                 posixtime(datetime)

                if obj.sequence == 1
                    sample_count_output = sprintf('Sample: %d/%d\n', obj.n_samples, obj.n_repetitions);
                    a = randi(7,obj.N_seg,1);
                    b = randi(7,obj.N_seg,1);
                    obj.stimulator.stimulation_frequency_train    = obj.frequency_train;
                    obj.stimulator.stimulation_frequency_pulse    = obj.frequency_pulse(a);
                    obj.stimulator.stimulation_duration     = obj.duration;
                    obj.stimulator.stimulation_amplitude    = obj.amplitude(b);
                    obj.stimulator.stimulation_pulse_width_train  = obj.width_train;
                    obj.stimulator.stimulation_pulse_width_pulse  = obj.width_pulse;
                    
                else
                    sample_count_output = sprintf('Sample: %d/%d\t', obj.n_samples, size(obj.parameter_vector,1));
                    obj.stimulator.stimulation_frequency_train    = obj.parameter_vector(obj.n_samples,1);
                    obj.stimulator.stimulation_frequency_pulse    = obj.parameter_vector(obj.n_samples,2);
                    obj.stimulator.stimulation_duration     = obj.parameter_vector(obj.n_samples,3);
                    obj.stimulator.stimulation_amplitude    = obj.parameter_vector(obj.n_samples,4);
                    obj.stimulator.stimulation_pulse_width_train  = obj.parameter_vector(obj.n_samples,5);
                    obj.stimulator.stimulation_pulse_width_pulse  = obj.parameter_vector(obj.n_samples,6);
                end
                if size(obj.param_temp,1) > 1 || obj.n_samples == 1
                obj.stimulator.generate_stimulation_signal();

                obj.stimulator.write_stimulation_signals();
                end

                obj.stimulator.stimulate()
                obj.n_samples                           = obj.n_samples + 1;
                switch obj.display_log_output
                    case 'verbose'
                        fprintf(sample_count_output);
                    case 'simple'
                        fprintf(sample_count_output);
                end
                
            elseif ~isempty(obj.stimulator.stimulation_duration) && (this_time - (obj.stimulation_time_s + obj.stimulator.stimulation_duration) > obj.evaluate_delay_s) && ~obj.stimulator.is_stimulating()
%                 this_time
                reset_time(obj)
                obj.stimulator.stimulation_armed = 1;
                if obj.sequence == 1
                    if obj.n_samples > obj.n_repetitions
                        obj.optimization_done = 1;
                    end
                else
                    if obj.n_samples > size(obj.parameter_vector,1)
                        obj.optimization_done = 1;
                    end
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

