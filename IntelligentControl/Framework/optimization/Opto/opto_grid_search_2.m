classdef opto_grid_search_2 < handle
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
        
        stimulator
        
        N_seg_dur
        objective_function
    end
    
    methods
        
        function obj = initialize(obj)
            obj.device_name             = obj.TD.GetDeviceName(0);
            obj.f_sample                = obj.TD.GetDeviceSF(obj.device_name);
            
            obj.run_start_time_s        = posixtime(datetime);
            obj.cycle_start_time_s      = posixtime(datetime);
            obj.last_time_s             = posixtime(datetime);
            obj.this_time_s             = posixtime(datetime);
            
                        obj.parameter_vector        = combvec(obj.frequency, obj.duration, obj.amplitude, obj.width)'; %For all combination
%             obj.parameter_vector        = [obj.frequency', obj.duration',obj.amplitude', obj.width']; % For the aligned row
            obj.parameter_vector        = repmat(obj.parameter_vector, obj.n_repetitions,1);
            
            %             rng(0); %Known order?
            rand_idx                    = randperm(size(obj.parameter_vector,1));
            obj.parameter_vector        = obj.parameter_vector(rand_idx,:);
            obj.optimization_done       = 0;
        end
        
        %%%%%%%%%%%%%%%
        %
        %%%%%%%%%%%%%%%
        function optimize(obj)
            TD = obj.TD;
            % For the buffer
            device_name = TD.GetDeviceName(0);
            TD_FS       = TD.GetDeviceSF(device_name);            
            TD_BUFFER_TIME          = 1; % Seconds (Control policy checked at TD_BUFFER_TIME/2)
            TD_READ_BUFFER_SIZE     = 16*floor(TD_FS*TD_BUFFER_TIME);
            
            % Get acquisition circuit variables
            n_read_pts      = TD_READ_BUFFER_SIZE;
            n_buff_pts      = n_read_pts/2;
            curindex        = TD.ReadTargetVEX([device_name '.read_index'], 0, 1, 'F32', 'F32');
            buffer_offset   = n_buff_pts;

            
            if isempty(obj.N_seg_dur)
                N_seg_stim_dur = 3; % Stimulation segmentation duration
            else
                N_seg_stim_dur = obj.N_seg_dur;
            end
            N_seg_feat_dur = N_seg_stim_dur-1; % The window length of objective (feature extraction) is one sec shorter
            
            N_seg = obj.parameter_vector(obj.n_samples,2)/N_seg_stim_dur; % Total number of segments
            N_iter = 0; % How many segments so far?
            
            obj.this_time_s = posixtime(datetime);
            
            this_time       = obj.this_time_s - obj.cycle_start_time_s; % How long from this cycle started?
            
            if this_time > obj.stimulation_time_s && obj.stimulator.stimulation_armed % First stimulation
                sample_count_output = sprintf('Sample: %d/%d\t', obj.n_samples, size(obj.parameter_vector,1));
                switch obj.display_log_output
                    case 'verbose'
                        fprintf(sample_count_output);
                    case 'simple'
                        fprintf(sample_count_output);
                end
                % Stim parameter setting
                obj.stimulator.stimulation_frequency    = obj.parameter_vector(obj.n_samples,1);
                obj.stimulator.stimulation_duration     = N_seg_stim_dur; % Stimulating as long as the segment duration
                obj.stimulator.stimulation_amplitude    = obj.parameter_vector(obj.n_samples,3);
                obj.stimulator.stimulation_pulse_width  = obj.parameter_vector(obj.n_samples,4);
                % Shoot the stim
                obj.TD.SetTargetVal([obj.stimulator.device_name '.nPeriod'],obj.stimulator.sampling_frequency/obj.stimulator.stimulation_frequency);
                obj.TD.SetTargetVal([obj.stimulator.device_name '.nPulses'],obj.stimulator.stimulation_frequency * obj.stimulator.stimulation_duration);
                obj.TD.SetTargetVal([obj.stimulator.device_name '.nDur-A'],obj.stimulator.sampling_frequency/1000*obj.stimulator.stimulation_pulse_width);
                obj.TD.SetTargetVal([obj.stimulator.device_name '.nDur-B'],5); % Useless
                obj.TD.SetTargetVal([obj.stimulator.device_name '.Amp-A'],obj.stimulator.stimulation_amplitude);
                obj.stimulator.stimulate()
                N_iter = 1;
                while N_iter < N_seg % From the 2nd stim to end of stim period, this loop is continuously going
                    obj.this_time_s = posixtime(datetime);
                    
                    this_time       = obj.this_time_s - obj.cycle_start_time_s;
                    if this_time > obj.stimulation_time_s + N_seg_stim_dur*N_iter % Time to next stim
                        % Let's update the buffer first%%%%%%%%%%%%%%%%%
                        if buffer_offset == 0 % Second half of buffer
                            
                            % Check if second half of buffer is full
                            while(curindex >= n_buff_pts)
                                
                                curindex = TD.ReadTargetVEX([device_name '.read_index'], 0, 1, 'F32', 'F32');
                            end
                            buffer_offset = n_buff_pts;
                            
                        else % First half of buffer
                            
                            % Check if first half of buffer is full
                            while(curindex < n_buff_pts)
                                curindex = TD.ReadTargetVEX([device_name '.read_index'], 0, 1, 'F32', 'F32');
                            end
                            buffer_offset = 0;
                            
                        end
                        new_data    = TD.ReadTargetVEX([device_name '.read_buff'], ...
                            buffer_offset, n_buff_pts, 'F32', 'F32');
                        new_data    = reshape(new_data, 16, n_buff_pts/16)';
                        obj.objective_function.update_buffer(new_data, TD.ReadTargetVEX([device_name '.current_time'], 0, 1, 'I32', 'F64')/TD_FS);% Update the buffer here
                        objective_window_start  = obj.stimulator.stimulation_time-obj.stimulator.stimulation_duration;
                        objective_window_end    = objective_window_start + N_seg_feat_dur;
                        m = obj.objective_function.get_metric(objective_window_start, objective_window_end);
                        if m>1
                            obj.stimulator.stimulation_amplitude = 0;
                        else
                            obj.stimulator.stimulation_amplitude    = obj.parameter_vector(obj.n_samples,3);                        
                        end
                        % Shoot the stim
                        obj.TD.SetTargetVal([obj.stimulator.device_name '.nPeriod'],obj.stimulator.sampling_frequency/obj.stimulator.stimulation_frequency);
                        obj.TD.SetTargetVal([obj.stimulator.device_name '.nPulses'],obj.stimulator.stimulation_frequency * obj.stimulator.stimulation_duration);
                        obj.TD.SetTargetVal([obj.stimulator.device_name '.nDur-A'],obj.stimulator.sampling_frequency/1000*obj.stimulator.stimulation_pulse_width);
                        obj.TD.SetTargetVal([obj.stimulator.device_name '.nDur-B'],5); % Useless
                        obj.TD.SetTargetVal([obj.stimulator.device_name '.Amp-A'],obj.stimulator.stimulation_amplitude);
                        obj.stimulator.stimulate() % This printout the stimulation parameter
                        N_iter = N_iter+1;
                        
                    end
                end
                obj.n_samples                           = obj.n_samples + 1; % the loop is done. Go to a next stim param.
                
            elseif this_time - (obj.stimulation_time_s + obj.stimulator.stimulation_duration*N_seg) > obj.evaluate_delay_s
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
        function t = get_current_time(obj,TD,device_name, sampling_frequency)
            t = TD.ReadTargetVEX([device_name '.current_time'], 0, 1, 'I32', 'F64')/sampling_frequency;
        end
    end
end

