classdef pid_controller < handle
    %CROSS_ENTROPY_OPTIMIZATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        TD
        device_name
        sampling_frequency
        logging_directory
        
        % Timing parameters
        run_start_time_s
        cycle_start_time_s
        this_time_s
        last_time_s       
        
        evaluate_delay_s
        
        
        lower_bound
        upper_bound
           
        pv_function
        pv_window_s
        
        % control setpoint
        setpoint
        setpoint_time
        stimulation_parameter
        
        Kp
        Ki
        Kd
        
        integral_error
        previous_error
        error_array
        
        % Logging parameters
        process_variable_fid   
        control_fid
        
        optimization_done
        stimulator
    end
    
    methods
      
        %%%%%%%%%%%%%%%
        %
        %%%%%%%%%%%%%%%
        function initialize(obj)
            obj.run_start_time_s        = posixtime(datetime);
          
            obj.process_variable_fid    = fopen(sprintf('%s/process_variable.csv',...
                                            obj.logging_directory),'a');
            obj.control_fid             = fopen(sprintf('%s/control.csv',...
                                            obj.logging_directory),'a');                  
                                         
            obj.integral_error          = 0;
            obj.previous_error          = 0;
            obj.optimization_done       = 0;                         
            obj.reset_time();
            
        end
        
        %%%%%%%%%%%%%%%
        %
        %%%%%%%%%%%%%%%
        function optimize(obj)
           
            
            this_time = obj.get_current_time();
            
            if this_time < 3
                return;
            end
            
            stimulation_time_s = obj.stimulator.stimulation_time;
            obj.stimulator.check_stimulation();
            
            if this_time >  stimulation_time_s +                    ...
                    obj.stimulator.stimulation_duration +   ...
                    obj.pv_window_s 
                
              
                process_variable    = obj.evaluate_process_variable();
                
                setpoint_idx        = find(this_time > obj.setpoint_time, 1, 'last' );
                current_setpoint    = obj.setpoint(setpoint_idx);
                
                if isnan(current_setpoint)
                    error           = 0;
                else
                    error               = obj.setpoint(setpoint_idx) - process_variable;                   

                    obj.integral_error  = nansum([obj.integral_error  error]);
                    derivative_error    = (error - obj.previous_error);
                end

                obj.error_array(end+1)  = error;
                
                p_error                 = obj.Kp*error;
                i_error             	= obj.Ki*obj.integral_error;
                d_error                 = obj.Kd*derivative_error;   
                output                  = p_error + i_error + d_error;
                                
                output                  = max(output,obj.lower_bound);
                output                  = min(output,obj.upper_bound);
                printf(' output = %.4f\n', output);
                obj.previous_error      = error;
                                
                obj.stimulator.stimulation_amplitude = output;
                obj.stimulator.generate_stimulation_signal();
                obj.stimulator.write_stimulation_signals();
                obj.stimulator.stimulate();
                
                obj.reset_time();
                
                fprintf(obj.control_fid,'%f, %f, %e, %e, %e, %e\n', ...
                    obj.stimulator.stimulation_time, posixtime(datetime('now')), p_error, i_error, d_error, output); 
                
%                 fprintf('%f, %f, %e, %e, %e, %e\n', ...
%                     obj.stimulator.stimulation_time, posixtime(datetime('now')), p_error, i_error, d_error, output); 
%                 fprintf('%e\n', output); 
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
        function process_variable = evaluate_process_variable(obj)
            objective_window_start  = obj.stimulator.stimulation_time + obj.evaluate_delay_s;
            objective_window_end    = objective_window_start + obj.pv_window_s;
            
            process_variable = obj.pv_function.get_metric(objective_window_start, objective_window_end,0);
           
            process_variable = 10*log10(process_variable);
            
            fprintf(obj.process_variable_fid,'%f, %f, %e\n', ...
                obj.stimulator.stimulation_time, posixtime(datetime('now')), process_variable); 
            
            fprintf('state: %.5e, ', process_variable);
        end

        %%%%%%%%%%%%%%%
        % 
        %%%%%%%%%%%%%%%
        function t = get_current_time(obj)
            t = obj.TD.ReadTargetVEX([obj.device_name '.current_time'], 0, 1, 'I32', 'F64')/obj.sampling_frequency;
        end
    end    
end

