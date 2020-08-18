classdef afterdischarge_optimization < handle
    properties
        
        f_sample
        
        % Stimulation parameters
        f_stimulation_range
        duration_range
        amplitude_range
        width_range
        stim_channel
        c_scale_range
        scale_point
        
        f_stimulation_static
        duration_static
        amplitude_static
        width_static
        
        % Timing parameters
        run_start_time_s
        cycle_start_time_s
        this_time_s
        last_time_s
        
        stimulation_time_s
        evaluate_time_s
        
        mode 
        n_stimulations
        fid
    end
    
    methods
        function obj = afterdischarge_optimization(f_s, mode)
            obj.f_sample                = f_s;
            obj.f_stimulation_range     = [5 120];          % Hertz
            obj.duration_range          = [2 2];            % Seconds
            obj.amplitude_range         = [1 1];            % Volts
            obj.width_range             = [.0001 .005];     % Seconds
            obj.stim_channel            = 16;
            obj.c_scale_range           = [0.5 2];
            obj.scale_point             = 732;
            
            obj.f_stimulation_static    = 20;
            obj.duration_static         = 2;
            obj.amplitude_static        = 1:2:16;
            obj.width_static            = 0.001;
            
            obj.run_start_time_s        = posixtime(datetime);
            obj.cycle_start_time_s      = posixtime(datetime);
            obj.last_time_s             = posixtime(datetime);
            obj.this_time_s             = posixtime(datetime);
            
            obj.stimulation_time_s      = 150;
            obj.evaluate_time_s         = 150;
            obj.mode                    = mode;
            obj.n_stimulations          = 0;
            obj.fid                     = fopen('afterdischarge_optimization_log.csv','a');
        end
        
        function control(obj, TD, data_buffer)

            obj.last_time_s = obj.this_time_s;
            obj.this_time_s = posixtime(datetime);
            
            this_time = obj.this_time_s - obj.cycle_start_time_s;
            global_time_s = obj.this_time_s - obj.run_start_time_s;
            last_time = obj.last_time_s - obj.cycle_start_time_s;
            
            fprintf('Global time = %4.1f, This time = %4.1f) ', global_time_s, this_time)

            if this_time < obj.stimulation_time_s
                
                fprintf('Waiting to stimulate\n');  
                
            elseif this_time < obj.evaluate_time_s

                fprintf('waiting to evaluate\n');
                
            end
            
            if this_time > obj.stimulation_time_s ...
                   && last_time < obj.stimulation_time_s
               
                fprintf('STIMULATE!!!\n');
                obj.n_stimulations = obj.n_stimulations + 1;
                
                beep
                signal = get_static_stimulation_signal(obj);
                write_signals(TD, obj.stim_channel, signal);
                stimulate_and_wait(TD, obj.stim_channel);
                open_channels(TD, obj.stim_channel);

            end

            if this_time > obj.evaluate_time_s ...
               && last_time < obj.evaluate_time_s
                
                fprintf('EVALUATE!!!!\n');

                reset_time(obj);

            end
           
        end
        
        function obj = reset_time(obj)
            obj.cycle_start_time_s   = posixtime(datetime);
            obj.last_time_s          = posixtime(datetime);
            obj.this_time_s          = posixtime(datetime);
        end
        
        function scaled_signal = get_random_stimulation_signal(obj,TD)
            
            % Determine stimulation parameters    
            f_stimulation_r     = obj.f_stimulation_range(1) + (obj.f_stimulation_range(2) - obj.f_stimulation_range(1))*rand();
            duration_r          = obj.duration_range(1) + (obj.duration_range(2) - obj.duration_range(1))*rand();
            amplitude_r         = obj.amplitude_range(1) + (obj.amplitude_range(2) - obj.amplitude_range(1))*rand();
            width_r             = obj.width_range(1) + (obj.width_range(2) - obj.width_range(1))*rand();
            c_scale_r           = obj.c_scale_range(1) + (obj.c_scale_range(2) - obj.c_scale_range(1))*rand();

            % Scale signal
            unscaled_signal     = generate_biphasic(obj.f_sample, f_stimulation_r, duration_r, amplitude_r, width_r);
            c_unscaled          = sum(abs(unscaled_signal));
            scaled_signal       = c_scale_r*(obj.scale_point/c_unscaled)*unscaled_signal;
            scale_pow           = sum(abs(scaled_signal));


            % Log stimulation data
            fprintf(obj.fid,'%f,', obj.run_start_time_s);
            fprintf(obj.fid,'%f,', obj.cycle_start_time_s);
            fprintf(obj.fid,'%f,', obj.this_time_s);
            fprintf(obj.fid,'%s,', 'biphasic-square-symmetric');
            fprintf(obj.fid,'%f,', f_stimulation_r);
            fprintf(obj.fid,'%f,', duration_r);
            fprintf(obj.fid,'%f,', amplitude_r);
            fprintf(obj.fid,'%f,', width_r);
            fprintf(obj.fid,'%f,', scale_pow);               
            fprintf(obj.fid,'%f,', c_scale_r);
            fprintf(obj.fid,'\n');

            % Output stimulation data
            fprintf('%15s = %10.2f\n','f_stimulation_r', f_stimulation_r)
            fprintf('%15s = %10.2f\n','duration_r', duration_r)
            fprintf('%15s = %10.2f\n','amplitude_r', amplitude_r)
            fprintf('%15s = %10.2f\n','width_r', width_r)
            fprintf('%15s = %10.2f\n','scale_pow', scale_pow)
            fprintf('%15s = %10.2f\n','c_scale_r', c_scale_r)
                
        end
        
        function signal = get_stimulation_signal(obj, mu, sigma)
            
            if isempty(mu) && isempty(sigma) % Generate random stimulation
                f_stimulation_r     = obj.f_stimulation_range(1) + (obj.f_stimulation_range(1) + obj.f_stimulation_range(2))*rand();
                duration_r          = obj.duration_range(1) + (obj.duration_range(1) + obj.duration_range(2))*rand();
                amplitude_r         = obj.amplitude_range(1) + (obj.amplitude_range(1) + obj.amplitude_range(2))*rand();
                width_r             = obj.width_range(1) + (obj.width_range(1) + obj.width_range(2))*rand();
                unscaled_signal     = generate_biphasic(obj.f_sample, f_stimulation_r, duration_r, amplitude_r, width_r);

                fprintf('f_stimulation_r = %f\n duration_r = %f\n amplitude_r = %f\n width_r = %f\n' ...
                    ,f_stimulation_r, duration_r, amplitude_r, width_r);
            else
                % Optimization code here
            end
            
        end
        
        
        function signal = get_static_stimulation_signal(obj)
            
            f_stimulation     = obj.f_stimulation_static;
            duration          = obj.duration_static;
            amplitude         = obj.amplitude_static;
            width             = obj.width_static;
            
            if strcmp(obj.mode, 'threshold')
                signal = generate_biphasic(obj.f_sample, f_stimulation, duration, amplitude(obj.n_stimulations), width, size(obj.stim_channel,2));
                fprintf('f_stimulation = %f\n duration = %f\n amplitude = %f\n width = %f\n' ...
                    ,f_stimulation, duration, amplitude(obj.n_stimulations), width);
            end
        end
    end
    
    
    
end