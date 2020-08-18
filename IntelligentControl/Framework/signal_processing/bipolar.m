classdef bipolar
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
        channels
        
        log_file
        fid
    end
    
    methods
        function obj = bipolar(TD_FS, channels, logging_directory)
            obj.sampling_frequency          = TD_FS;
            obj.channels                     = channels;
            
            obj.DATA_BUFFER_DURRATION       = 10;
            obj.DATA_VEC_SIZE               = 1;
            obj.DATA_BUFFER_SIZE            = TD_FS*obj.DATA_BUFFER_DURRATION;
            obj.DATA_BUFFER                 = circVBuf(int64(obj.DATA_BUFFER_SIZE),...
                                            int64(obj.DATA_VEC_SIZE), 0);
            
            obj.log_file                    = sprintf('%s/bipolar_channels_%d_%d.csv',...
                                            logging_directory, channels);
            obj.fid                         = fopen(obj.log_file, 'a');
            obj.name                        = 'Bipolar Pass Through';
        end
        
        function update_buffer(obj, new_data)
            new_data = new_data - repmat(mean(new_data),size(new_data,1),1);
            new_data = new_data - repmat(std(new_data),size(new_data,1),1);
            obj.DATA_BUFFER.append(new_data(:,obj.channels(1))-new_data(:,obj.channels(2)));
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

