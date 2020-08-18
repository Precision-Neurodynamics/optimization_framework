classdef incoherence < handle
    %INCOHERENCE 
    % Calculates 1 minus the mean of the coherence spectrum over the past
    % sample. Used to minimize coherence
    
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
        
        name
        ylim
    end
    
    methods
        function obj = incoherence(TD_FS, channels, logging_directory)
            obj.sampling_frequency          = 2;
            obj.channels                    = channels;
            obj.COHERENCE_BUFFER_DURRATION  = 20;
            obj.COHERENCE_VEC_SIZE          = 1;
            obj.COHERENCE_BUFFER_SIZE       = TD_FS*obj.COHERENCE_BUFFER_DURRATION/(TD_FS*.5);
            obj.COHERENCE_BUFFER            = circVBuf(int64(obj.COHERENCE_BUFFER_SIZE),...
                                            int64(obj.COHERENCE_VEC_SIZE), 0);
            obj.name                        = 'Incoherence';
            obj.ylim                        = [0 1];

        end
        
        function update_buffer(obj, new_data)
            channel_a   = new_data(:,obj.channels(1));
            channel_b   = new_data(:,obj.channels(2));
            [cxy,~]     = mscohere(channel_a,channel_b, [], [],6:.1:7.1,obj.sampling_frequency);
            
            obj.COHERENCE_BUFFER.append(1-mean(cxy));
        end
        
        function m = get_metric(obj, duration)
            start_point = obj.COHERENCE_BUFFER.lst-duration*obj.sampling_frequency;
            end_point   = obj.COHERENCE_BUFFER.lst;
            
            m = obj.COHERENCE_BUFFER.raw(start_point:end_point);
            
        end
        
        function update_metric(obj)
            
        end
    end
    
end

