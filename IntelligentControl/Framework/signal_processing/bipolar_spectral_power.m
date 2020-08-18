classdef bipolar_spectral_power < handle
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
        function obj = bipolar_spectral_power(TD_FS, channels, ~)
            obj.data_sampling_frequency             = TD_FS;
            obj.channels                            = channels;
            
            obj.DATA_BUFFER_DURRATION               = 15;
            obj.DATA_VEC_SIZE                       = 4;
            obj.DATA_BUFFER_SIZE                    = obj.DATA_BUFFER_DURRATION*TD_FS;
            obj.DATA_BUFFER                         = circVBuf(int64(obj.DATA_BUFFER_SIZE),...
                                                    int64(obj.DATA_VEC_SIZE), 0);
            
            obj.metric_sampling_frequency           = 4;
            obj.METRIC_BUFFER_DURRATION             = 20;
            obj.METRIC_BUFFER_VEC_SIZE              = 2;
            obj.METRIC_BUFFER_SIZE                  = obj.METRIC_BUFFER_DURRATION*obj.metric_sampling_frequency;
            obj.METRIC_BUFFER                       = circVBuf(int64(obj.METRIC_BUFFER_SIZE),...
                                                    int64(obj.METRIC_BUFFER_VEC_SIZE), 0);

                                                
            obj.params.Fs                           = TD_FS;
            obj.params.tapers                       = [3 5];
            obj.params.fpass                        = [4 10];

            obj.name                                = sprintf('Bipolar Spectral Power (%d-%dHz)', obj.params.fpass(1), obj.params.fpass(2));
     
        end
        
        function update_buffer(obj, new_data, update_time)
            if update_time > 10
               a = 1; 
            end
            obj.data_update_time = update_time;
            
            new_data    = new_data - repmat(mean(new_data),size(new_data,1),1);
            new_data    = new_data ./ repmat(std(new_data),size(new_data,1),1);
            
            channel_a   = new_data(:,obj.channels(:,1))-new_data(:,obj.channels(:,2));
            obj.DATA_BUFFER.append(channel_a);

        end
        
        function m = get_metric(obj,window_start_time, window_end_time, plot_flag)
            if nargin == 2
                start_index = obj.DATA_BUFFER.lst - window_start_time * obj.data_sampling_frequency;
                end_index   = obj.DATA_BUFFER.lst;
            else
                start_index         = obj.DATA_BUFFER.lst - obj.DATA_BUFFER.fst - (obj.data_update_time - window_start_time) * obj.data_sampling_frequency;
                end_index           = obj.DATA_BUFFER.lst - obj.DATA_BUFFER.fst - (obj.data_update_time - window_end_time) * obj.data_sampling_frequency;
            end
            
            objective_segment   = obj.DATA_BUFFER.raw(start_index:end_index,:);
               
            if exist('plot_flag', 'var') && plot_flag
                pre_segment = obj.DATA_BUFFER.raw(start_index - (end_index - start_index):start_index,:);
                obj.params.fpass = [4 8];
                [S1, f1] = mtspectrumc(objective_segment, obj.params);
                [S2, f1] = mtspectrumc(pre_segment, obj.params);
               
                plot(f1, S1-S2)
%                 for c1 = 1:4
%                     subplot(4,1,c1)
%                     plot(a(:,c1))
% %                     hold on
% %                     plot(obj.filter_data(a(:,c1)));
%                     
%                     plot([start_index start_index],[-1 1], 'r-')
%                     hold off
%                 end
              
                drawnow
            
            end
            
           
            
            [S, ~]  = mtspectrumc(objective_segment, obj.params);
            m       = mean(sum(S));
            
            
            obj.METRIC_BUFFER.append(m);
        end
        
        function data = filter_data(obj, data)
            [z, p, k] = butter(15,60/obj.data_sampling_frequency*2);
            soshi       = zp2sos(z, p, k);
            data        = sosfilt(soshi, data);
        end
    end
    
end

