classdef mt_spectrogram < handle
    %COHERENCE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        DATA_BUFFER_DURRATION
        DATA_VEC_SIZE
        DATA_BUFFER_SIZE
        DATA_BUFFER
        
        METRIC_BUFFER_DURRATION
        METRIC_BUFFER_VEC_SIZE
        METRIC_BUFFER_SIZE
        METRIC_BUFFER
        
        data_update_time
        
        params
        metric_sampling_frequency
        data_sampling_frequency        
        channels
        ylim
        name
        
        bin_min
        bin_max
    end
    
    methods
        function obj = mt_spectrogram(TD_FS, channel, ~)
            obj.data_sampling_frequency             = TD_FS;
            obj.channels                            = channel;
            
            obj.DATA_BUFFER_DURRATION               = 15;
            obj.DATA_VEC_SIZE                       = 16;
            obj.DATA_BUFFER_SIZE                    = obj.DATA_BUFFER_DURRATION*TD_FS;
            obj.DATA_BUFFER                         = circVBuf(int64(obj.DATA_BUFFER_SIZE),...
                                                    int64(obj.DATA_VEC_SIZE), 0);
            
            obj.metric_sampling_frequency           = 4;
            obj.METRIC_BUFFER_DURRATION             = 20;
            obj.METRIC_BUFFER_VEC_SIZE              = 1;
            obj.METRIC_BUFFER_SIZE                  = obj.METRIC_BUFFER_DURRATION*obj.metric_sampling_frequency;
            obj.METRIC_BUFFER                       = circVBuf(int64(obj.METRIC_BUFFER_SIZE),...
                                                    int64(obj.METRIC_BUFFER_VEC_SIZE), 0);

                                                
            obj.params.Fs                           = TD_FS;
            obj.params.tapers                       = [3 5];
            obj.params.fpass                        = [1 100];

            obj.name                                = sprintf('Bipolar Spectral Power (%d-%dHz)', obj.params.fpass(1), obj.params.fpass(2));
     
        end
        
        function update_buffer(obj, new_data, update_time)

            obj.data_update_time = update_time;
            
            channel_a   = new_data(:,obj.channels);
            obj.DATA_BUFFER.append(channel_a);

        end
        
        function display_metric(obj)
            data = obj.DATA_BUFFER.raw(obj.DATA_BUFFER.fst:obj.DATA_BUFFER.lst,2); % the last number = channel
            [S, t,f] = mtspecgramc(data, [1 .25], obj.params);
            if length(t) > 2
                plot_matrix(S,t,f);
                drawnow()
            end
        end
        
        function data = filter_data(obj, data)
            [z, p, k] = butter(15,60/obj.data_sampling_frequency*2);
            soshi       = zp2sos(z, p, k);
            data        = sosfilt(soshi, data);
        end
    end
    
end

