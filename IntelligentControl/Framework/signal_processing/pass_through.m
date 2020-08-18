classdef pass_through
    %PASS_THROUGH Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        DATA_BUFFER_DURRATION
        DATA_VEC_SIZE
        DATA_BUFFER_SIZE
        DATA_BUFFER
        
        name
        sampling_frequency
        
        buffer_duration
        channel
        
        log_file
        fid
    end
    
    methods
        function obj = pass_through(TD_FS, channel, logging_directory)
            obj.sampling_frequency          = TD_FS;
            obj.channel                     = channel;
            
            obj.DATA_BUFFER_DURRATION       = 10;
            obj.DATA_VEC_SIZE               = 1;
            obj.DATA_BUFFER_SIZE            = TD_FS*obj.DATA_BUFFER_DURRATION;
            obj.DATA_BUFFER                 = circVBuf(int64(obj.DATA_BUFFER_SIZE),...
                                            int64(obj.DATA_VEC_SIZE), 0);
            
            obj.log_file                    = sprintf('%s/pass_through_channel_%d.csv',...
                                            logging_directory, channel);
            obj.fid                         = fopen(obj.log_file, 'a');
            obj.name                        = 'Pass Through';
        end
        
        function update_buffer(obj, new_data)
            obj.DATA_BUFFER.append(new_data(:,obj.channel));
        end
        
        function m = get_metric(obj, duration)
            start_point = obj.DATA_BUFFER.lst-duration*obj.sampling_frequency;
            end_point   = obj.DATA_BUFFER.lst;
            
            m = obj.DATA_BUFFER.raw(start_point:end_point);
        end
        
        function log_data(obj, log_time)
            data = obj.DATA_BUFFER.raw(obj.DATA_BUFFER.new:obj.DATA_BUFFER.lst);
            time = log_time - (size(data,1)-1)/obj.sampling_frequency:1/obj.sampling_frequency:log_time;
            fprintf(obj.fid,'%f, %f\n',[time; data']);
        end
    end
end

