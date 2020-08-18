classdef opto_model_state_5 < handle
    % segment power and inter-ictal spike detection
    
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
        metric_band
        model_coefficients
        bin_min
        bin_max
    end
    
    methods
        function obj = opto_model_state_5(TD_FS, channels, metric_band, ~, model_location)
            obj.data_sampling_frequency             = TD_FS;
            obj.channels                            = channels;
            
            obj.DATA_BUFFER_DURRATION               = 120;
            obj.DATA_VEC_SIZE                       = size(channels,2);
            obj.DATA_BUFFER_SIZE                    = obj.DATA_BUFFER_DURRATION*TD_FS;
            obj.DATA_BUFFER                         = circVBuf(int64(obj.DATA_BUFFER_SIZE),...
                                                    int64(obj.DATA_VEC_SIZE), 0);
            
            obj.metric_sampling_frequency           = 4;
            obj.METRIC_BUFFER_DURRATION             = 20;
            obj.METRIC_BUFFER_VEC_SIZE              = 1;
            obj.METRIC_BUFFER_SIZE                  = obj.METRIC_BUFFER_DURRATION*obj.metric_sampling_frequency;
            obj.METRIC_BUFFER                       = circVBuf(int64(obj.METRIC_BUFFER_SIZE),...
                                                    int64(obj.METRIC_BUFFER_VEC_SIZE), 0);
                                            
            obj.params.Fs                           = 2000;
            obj.params.tapers                       = [3 5];%[3 5];
            obj.params.fpass                        = metric_band;%[40 45];
            
            
        end
        
        function update_buffer(obj, new_data, update_time)

            obj.data_update_time    = update_time;
            channel_a               = new_data(:,obj.channels);
            
            obj.DATA_BUFFER.append(channel_a);

        end
        
        function [m1_return, p] = get_metric(obj,window_start_time, window_end_time, window_s,samples_per_cycle, O_Window,stim_tag, S_th)
            ca3_idx = [2:2:16];
            ca1_idx = [1:2:15];
            Fs = 2000;
            start_index         = obj.DATA_BUFFER.lst - obj.DATA_BUFFER.fst - (obj.data_update_time - window_start_time) * obj.data_sampling_frequency ;
            end_index           = obj.DATA_BUFFER.lst - obj.DATA_BUFFER.fst - (obj.data_update_time - window_end_time) * obj.data_sampling_frequency;
            temp_seg = obj.DATA_BUFFER.raw(obj.DATA_BUFFER.fst:obj.DATA_BUFFER.lst,:);
            if end_index>size(temp_seg,1)
                end_index = size(temp_seg,1);
            end
            objective_segment   = temp_seg(start_index:end_index,:);
            
            for c1 = 1:size(obj.channels,2)
                objective_data(:,c1) = resample(objective_segment(:,c1), Fs, floor(obj.data_sampling_frequency));
            end
            figure(3)
            spectrogram_60s(objective_data',2000,3,3); % For check
            param2 = obj.params;
            param2.fpass = [1 80];
            [S2,f2] = mtspectrumc(objective_data, param2);
            if stim_tag == 0
                figure(4)
                plot(f2,mean(S2,2))
                hold on
            else
                figure(4)
                plot(f2,mean(S2,2),'r')
                hold off
            end
            % Define window for pre and on

            
            for i=1:1:samples_per_cycle
                Pre_W(i,1) = (window_s-O_Window)*(i-1); %start
                Pre_W(i,2) = window_s+(window_s-O_Window)*(i-1); %end
                On_W(i,1) = window_s+(window_s-O_Window)*(i-1); %start
                On_W(i,2) = window_s*2+(window_s-O_Window)*(i-1); %end
            end
            
            % Find IIS and segments (each channel)
            IIS_detected = BO_IIS_detect_power(objective_data',S_th,0.5,0.1,2000);
            for C=1:1:length(obj.channels)
                Pre_IIS{C} = BO_IIS_detect_segment(IIS_detected.time_Sp_final{C},Pre_W);
                On_IIS{C} = BO_IIS_detect_segment(IIS_detected.time_Sp_final{C},On_W);
                IIS{C} = [];
                for j1 = 1:1:length(Pre_IIS{C})
                    IIS{C} = [IIS{C} Pre_IIS{C}{j1} On_IIS{C}{j1}];
                end
                IIS{C} = unique(IIS{C});
            end
            
            % Calculate only legit channels !!!!!
            for z1 = 1:1:samples_per_cycle
                seg_start = (window_s-O_Window)*(z1-1);
                seg_start_index = floor(seg_start*Fs) + 1;
                seg_end = seg_start + window_s;
                seg_end_index = floor(seg_end*Fs);
                objective_seg = objective_data(seg_start_index:seg_end_index,:);
%                 Ch_noIIS = obj.channels;
                Ch_noIIS = [];
                for C = 1:1:length(obj.channels);
                    if isempty(find(IIS{C}==z1))
                        Ch_noIIS = [Ch_noIIS C];
                    end
                end
                if length(Ch_noIIS)>4
                    [S,f] = mtspectrumc(objective_seg(:,Ch_noIIS), obj.params);
                    m_pre(z1)               = mean(sum(S));
                else
                    m_pre(z1) = NaN;
                end
                seg_start = window_s + (window_s-O_Window)*(z1-1);
                seg_start_index = floor(seg_start*Fs) + 1;
                seg_end = seg_start + window_s;
                seg_end_index = floor(seg_end*Fs);
                seg_end_index_insuarance = min(seg_end_index,size(objective_data,1));
                objective_seg = objective_data(seg_start_index:seg_end_index_insuarance,:);
                if length(Ch_noIIS)>4
                    [S,f] = mtspectrumc(objective_seg(:,Ch_noIIS), obj.params);
                    m_on(z1)               = mean(sum(S));
                else
                    m_on(z1) = NaN;
                end
                m1(z1,1) = m_on(z1) - m_pre(z1);
                m1(z1,2) = m_pre(z1);
            end
                        m1_return = m1;
%                         m1(isnan(m1(:,1)),:) = [];
%                         p = polyfit(m1(:,2),m1(:,1),1);

        end
        
        function features = bin_data(~, data, f)
           features = [];
           for c2 = 1:size(data,3)
               channel_features = [];
               for c1 = 1:49
                   idx = f > c1 & f < (c1+1);
                   power_bin = squeeze(sum(data(:,idx,c2),2));
                   
                   channel_features(:, c1) = power_bin;
               end
               features = [features, channel_features]; 
           end
        end
     
    end
    
end

