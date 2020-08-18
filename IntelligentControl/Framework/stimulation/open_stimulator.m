classdef open_stimulator < handle
    %STIMULATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        TD
        device_name
        sampling_frequency
        headstage_type
        electrode_location
        animal_id
        experiment_name
        tank_name
        block_name
        experiment_start_time
        
        % Common names used to describe signal
        stimulation_type
        stimulation_frequency
        stimulation_duration
        stimulation_pulse_width
        stimulation_amplitude
        stimulation_channels
        stimulation_phase 
        
        % Specific parameters that are used by PulseGenN
        period
        dur
        nPulses
        pulse_width
            
        stimulation_signal
        stimulation_time
        stimulation_armed
        channels_closed
        
        logging_directory
        display_log_output
        stimulation_fid
        stimulation_log
        stimulation_uid
    end
    
    methods
        
        %%%%%%%%%%%%%%%
        %
        %%%%%%%%%%%%%%%
        function initialize(obj)
            obj.stimulation_armed       = 1;
            obj.channels_closed         = 0;
            obj.stimulation_log         = sprintf('%s/stimulation_table.csv',...
                                            obj.logging_directory);
            obj.stimulation_fid         = fopen(obj.stimulation_log, 'a'); 
            obj.stimulation_time        = 1;        
            obj.write_log_header();
            obj.open_channels();
        end
        
        %%%%%%%%%%%%%%%
        %
        %%%%%%%%%%%%%%%
        function generate_stimulation_signal(obj)
            
            obj.period      = floor(obj.sampling_frequency / obj.stimulation_frequency);
            obj.dur         = obj.stimulation_duration*obj.sampling_frequency;
            obj.nPulses     = obj.stimulation_frequency * obj.stimulation_duration;
            obj.pulse_width = obj.stimulation_pulse_width * obj.sampling_frequency;
        end
        
        %%%%%%%%%%%%%%%
        %
        %%%%%%%%%%%%%%%
        function open_channels(obj)
            for c1 = 1:size(obj.stimulation_channels,2);
                obj.TD.WriteTargetVEX( ...
                    [obj.device_name '.stim_buff~' num2str(obj.stimulation_channels(c1))], ...
                    0, 'F32',  10000*ones(1,10));
                
                obj.TD.SetTargetVal([obj.device_name '.dur~' num2str(obj.stimulation_channels(c1))], 10);
            end
        end
        
        %%%%%%%%%%%%%%%
        %
        %%%%%%%%%%%%%%%
        function v = is_stimulating(obj)
            v = 0;
            for c1 = 1:numel(obj.stimulation_channels)
                v = v + obj.TD.ReadTargetVEX(...
                    [obj.device_name '.not_done~' num2str(obj.stimulation_channels(c1))],...
                    0, 1, 'F32', 'F32');
            end
            
        end
        
        %%%%%%%%%%%%%%%
        %
        %%%%%%%%%%%%%%%
        function write_stimulation_signals(obj)
            obj.stimulation_uid     = posixtime(datetime('now'));          
            obj.TD.SetTargetVal([obj.device_name '.mon_bank' ], 0);
            
            switch obj.stimulation_type
                case 'synchronous'
                    delays      = ones(size(obj.stimulation_channels));
                case 'asynchronous'
                    stim_freq   = obj.stimulation_frequency;
                    n_channels  = size(obj.stimulation_channels,2);
                    d0_seconds  = 1/stim_freq/n_channels;
                    d0_samples  = d0_seconds * obj.sampling_frequency;
                    delays      = (0:n_channels-1) * d0_samples;
            end
            
            for c1 = 1:length(obj.stimulation_channels)
               
                obj.TD.SetTargetVal([obj.device_name '.nDelay~' num2str(obj.stimulation_channels(c1))], delays(c1));
                
                obj.TD.SetTargetVal([obj.device_name '.dur~' num2str(obj.stimulation_channels(c1))], obj.dur);
                obj.TD.SetTargetVal([obj.device_name '.nPeriod~' num2str(obj.stimulation_channels(c1))], obj.period);
                obj.TD.SetTargetVal([obj.device_name '.nPulses~' num2str(obj.stimulation_channels(c1))], obj.nPulses); % check n pulses
                obj.TD.SetTargetVal([obj.device_name '.nDur-A~'    num2str(obj.stimulation_channels(c1))], obj.pulse_width);
                
                if strcmp(obj.stimulation_phase, 'A')
                    obj.TD.SetTargetVal([obj.device_name '.Amp-A~'   num2str(obj.stimulation_channels(c1))], -1*obj.stimulation_amplitude/2);
                    obj.TD.SetTargetVal([obj.device_name '.Amp-C~'   num2str(obj.stimulation_channels(c1))], 1*obj.stimulation_amplitude/2);
                elseif strcmp(obj.stimulation_phase, 'C')
                    obj.TD.SetTargetVal([obj.device_name '.Amp-A~'   num2str(obj.stimulation_channels(c1))], 1*obj.stimulation_amplitude/2);
                    obj.TD.SetTargetVal([obj.device_name '.Amp-C~'   num2str(obj.stimulation_channels(c1))], -1*obj.stimulation_amplitude/2);                  
                end
                
                obj.TD.SetTargetVal([obj.device_name '.trig_stim~' num2str(obj.stimulation_channels(c1))], 1);
                
            end
              
        end        
        
        %%%%%%%%%%%%%%%
        %
        %%%%%%%%%%%%%%%
        function stimulate(obj)       
            obj.TD.SetTargetVal([obj.device_name '.trig_stim'], 1);

            pause(.1)
            obj.TD.SetTargetVal([obj.device_name '.trig_stim'], 0);
            
            obj.channels_closed     = 1;
            obj.stimulation_armed   = 0;
            obj.stimulation_time    = obj.get_last_stimulation_time();
            obj.log_stimulation();
        end

        %%%%%%%%%%%%%%%
        %
        %%%%%%%%%%%%%%%
        function check_stimulation(obj)
            if  obj.channels_closed && ~obj.is_stimulating()
                obj.open_channels();
                obj.channels_closed     = 0;
            end
        end

        %%%%%%%%%%%%%%%
        %
        %%%%%%%%%%%%%%%
        function log_stimulation(obj)
            log_string = '';
            log_string = [log_string sprintf('%f,', obj.stimulation_uid)];
            log_string = [log_string sprintf('%s,', obj.tank_name)];
            log_string = [log_string sprintf('%s,', obj.headstage_type)];
            log_string = [log_string sprintf('%s,', obj.electrode_location)];
            log_string = [log_string sprintf('%f,', obj.experiment_start_time)];
            log_string = [log_string sprintf('%s,', obj.experiment_name)];
            log_string = [log_string sprintf('%s,', obj.animal_id)];
            log_string = [log_string sprintf('%s,', obj.block_name)];
            log_string = [log_string sprintf('%s,', obj.sampling_frequency)];
            log_string = [log_string sprintf('%f,', obj.stimulation_time)];
            log_string = [log_string sprintf('%f,', obj.stimulation_frequency)];
            log_string = [log_string sprintf('%f,', 0.0)];
            log_string = [log_string sprintf('%f,', obj.stimulation_duration)];
            log_string = [log_string sprintf('%f,', obj.stimulation_amplitude/2)];
            log_string = [log_string sprintf('%f,', obj.stimulation_amplitude/2)];
            log_string = [log_string sprintf('%f,', obj.stimulation_pulse_width/2)];
            log_string = [log_string sprintf('%f,', obj.stimulation_pulse_width/2)];
            log_string = [log_string sprintf('%f,', 0.0)];
            
            if strcmp(obj.stimulation_type,'synchronous')
                log_string = [log_string sprintf('%f,', 1.0)];
            else
                log_string = [log_string sprintf('%f,', 0.0)];
            end
            
            log_string = [log_string sprintf('%s,', obj.stimulation_type)];
            log_string = [log_string sprintf('1|3|5|7|10|12|14|16')];
            log_string = [log_string sprintf('\n')];
            
            switch obj.display_log_output
                case 'verbose'
                    fprintf(log_string);
                case 'simple'

                    fprintf('Frequency: %.1f, Duration: %.2f, Amplitude: %.2f\n', ...
                        obj.stimulation_frequency, obj.stimulation_duration,...
                        obj.stimulation_amplitude);
            end
            fprintf(obj.stimulation_fid, log_string);
        end
        
        %%%%%%%%%%%%%%%
        %
        %%%%%%%%%%%%%%%
        function write_log_header(obj)
            header_string = ['stimulation_uid,' ...
                'tank_name,' ... 
                'headstage_type,' ...
                'electrode_location,' ...
                'experiment_start_time,' ...
                'experiment_name,' ...
                'animal_id,' ...
                'block_name,' ...
                'sampling_frequency,' ...
                'stimulation_time,' ...
                'pulse_frequency,' ...
                'train_frequency,' ...
                'stimulation_duration,' ...
                'stimulation_amplitude_a,' ...
                'stimulation_amplitude_b,' ...
                'stimulation_pulse_width_a,' ...
                'stimulation_pulse_width_b,' ...
                'stimulation_gap,' ...
                'stimulation_synchronicity,' ...
                'stimulation_type,' ...
                'stimulation_channel_order\n' ...
                ];
            fprintf(obj.stimulation_fid, header_string);

        end
        
        %%%%%%%%%%%%%%%
        %
        %%%%%%%%%%%%%%%
        function t = get_last_stimulation_time(obj)
            t = obj.TD.ReadTargetVEX([obj.device_name '.last_stim_time'], 0, 1, 'I32', 'F64')/obj.sampling_frequency;
        end
    end
    
end

