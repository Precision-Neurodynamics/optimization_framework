classdef correlation < handle
    %METRIC Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        DATA_BUFFER_DURRATION
        DATA_VEC_SIZE
        DATA_BUFFER_SIZE
        DATA_BUFFER
        
        METRIC_BUFFER_DURRATION
        METRIC_VEC_SIZE
        METRIC_BUFFER_SIZE
        METRIC_BUFFER
        
        sampling_frequency        
        channels
        ylim
        name
        
    end
    
    methods
        function obj = correlation(TD_FS, channels, ~)
            obj.sampling_frequency          = 2;
            obj.channels                    = channels;
            obj.METRIC_BUFFER_DURRATION     = 20;
            obj.METRIC_VEC_SIZE             = 1;
            obj.METRIC_BUFFER_SIZE          = TD_FS*obj.METRIC_BUFFER_DURRATION/(TD_FS*.5);
            obj.METRIC_BUFFER               = circVBuf(int64(obj.METRIC_BUFFER_SIZE),...
                                            int64(obj.METRIC_VEC_SIZE), 0);
            obj.name                        = 'Correlation';
            obj.ylim                        = [-1 1];
        end
        
        function update_buffer(obj, new_data)
            channel_a   = new_data(:,obj.channels(1));
            channel_b   = new_data(:,obj.channels(2));

            obj.METRIC_BUFFER.append(corr(channel_a, channel_b));
        end
        
        function m = get_metric(obj, duration)
            start_point = obj.METRIC_BUFFER.lst-duration*obj.sampling_frequency;
            end_point   = obj.METRIC_BUFFER.lst;
            
            m = obj.METRIC_BUFFER.raw(start_point:end_point);
            
        end
        
        function update_metric(~)
            
        end
    end
    
end

