classdef coherence < handle
    %COHERENCE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        DATA_BUFFER_DURRATION
        DATA_VEC_SIZE
        DATA_BUFFER_SIZE
        DATA_BUFFER
        
        COHERENCE_BUFFER_DURRATION
        COHERENCE_VEC_SIZE
        COHERENCE_BUFFER_SIZE
        COHERENCE_BUFFER
        
        sampling_frequency        
        channels
        ylim
        name
        
    end
    
    methods
        function obj = coherence(TD_FS, channels, ~)
            obj.sampling_frequency          = 2;
            obj.channels                    = channels;
            obj.COHERENCE_BUFFER_DURRATION  = 20;
            obj.COHERENCE_VEC_SIZE          = 1;
            obj.COHERENCE_BUFFER_SIZE       = TD_FS*obj.COHERENCE_BUFFER_DURRATION/(TD_FS*.5);
            obj.COHERENCE_BUFFER            = circVBuf(int64(obj.COHERENCE_BUFFER_SIZE),...
                                            int64(obj.COHERENCE_VEC_SIZE), 0);
            obj.name                        = 'Coherence';
            obj.ylim                        = [0 1];
        end
        
        function update_buffer(obj, new_data)
            channel_a   = new_data(:,obj.channels(1));
            channel_b   = new_data(:,obj.channels(2));
            [cxy,~]      = mscohere(channel_a,channel_b, [], [],5:10,obj.sampling_frequency);
            
            obj.COHERENCE_BUFFER.append(mean(cxy));
        end
        
        function m = get_metric(obj, duration)
            start_point = obj.COHERENCE_BUFFER.lst-duration*obj.sampling_frequency;
            end_point   = obj.COHERENCE_BUFFER.lst;
            
            m = obj.COHERENCE_BUFFER.raw(start_point:end_point);
            
        end
        
        function update_metric(~)
            
        end
    end
    
end

