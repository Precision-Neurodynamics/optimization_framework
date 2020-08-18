classdef opto_model_state_4 < handle
    % segment power and outliers
    
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
        function obj = opto_model_state_4(TD_FS, channels, metric_band, ~, model_location)
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
%             obj.model_coefficients                  = load(model_location);
%             obj.model_coefficients                  = obj.model_coefficients.g;
%             obj.name                                = sprintf('ADMETS Logistic Regression Model');
            
        end
        
        function update_buffer(obj, new_data, update_time)

            obj.data_update_time    = update_time;
            channel_a               = new_data(:,obj.channels);
            
            obj.DATA_BUFFER.append(channel_a);

        end
        
        function [m1_return, p] = get_metric(obj,window_start_time, window_end_time, window_s,samples_per_cycle, O_Window,stim_tag, sample_results_control, sample_results)
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

            for z1 = 1:1:samples_per_cycle
                seg_start = (window_s-O_Window)*(z1-1);
                seg_start_index = floor(seg_start*Fs) + 1;
                seg_end = seg_start + window_s;
                seg_end_index = floor(seg_end*Fs);
                objective_seg = objective_data(seg_start_index:seg_end_index,:);
                
                [S,f] = mtspectrumc(objective_seg, obj.params);
                m_pre(z1)               = mean(sum(S));
                
                seg_start = window_s + (window_s-O_Window)*(z1-1);
                seg_start_index = floor(seg_start*Fs) + 1;
                seg_end = seg_start + window_s;
                seg_end_index = floor(seg_end*Fs);
                seg_end_index_insuarance = min(seg_end_index,size(objective_data,1));
                objective_seg = objective_data(seg_start_index:seg_end_index_insuarance,:);
                
                [S,f] = mtspectrumc(objective_seg, obj.params);
                m_on(z1)               = mean(sum(S));
                
                m1(z1,1) = m_on(z1) - m_pre(z1);
                m1(z1,2) = m_pre(z1);
            end
                        m1_return = m1;

            % Here we identify the outliers
            % obj.sample_results_control(obj.n_iter,:,x) x=1: delta, x=2:
            % pre
            % obj.sample_results(obj.n_iter,:,x) x=1: delta, x=2:pre
%             if size(sample_results_control,1)>0
%                 s1 = size(sample_results_control,1);
%                 s2 = size(sample_results_control,2);
%                 delta_all_control = reshape(sample_results_control(:,:,1),s1*s2,1);
%                 delta_all_control(isnan(delta_all_control)) = [];
%                 pre_all_control = reshape(sample_results_control(:,:,2),s1*s2,1);
%                 pre_all_control(isnan(pre_all_control)) = [];
%             end
%             if size(sample_results,1)>0
%                 s1 = size(sample_results,1);
%                 s2 = size(sample_results,2);
%                 delta_all_stim = reshape(sample_results(:,:,1),s1*s2,1);
%                 delta_all_stim(isnan(delta_all_stim)) = [];
%                 pre_all_stim = reshape(sample_results(:,:,2),s1*s2,1);
%                 pre_all_stim(isnan(delta_all_stim)) = [];
%             end
%             fold = 100;% for outlier removal
%             if size(sample_results_control,1)>0 || size(sample_results,1)>0
%                 delta_min_control = prctile(delta_all_control,25);
%                 delta_max_control = prctile(delta_all_control,75);
%                 pre_min_control = prctile(pre_all_control,25);
%                 pre_max_control = prctile(pre_all_control,75);
%                 
%                 delta_min_stim = prctile(delta_all_stim,25);
%                 delta_max_stim = prctile(delta_all_stim,75);
%                 pre_min_stim = prctile(pre_all_stim,25);
%                 pre_max_stim = prctile(pre_all_stim,75);
%                 
%                 if stim_tag == 0 %control
%                     pre_outlier = find(m1(:,2)>pre_max_control+fold*(pre_max_control-pre_min_control) | m1(:,2)<pre_min_control-fold*(pre_max_control-pre_min_control));
%                     delta_outlier = find(m1(:,1)>delta_max_control+fold*(delta_max_control-delta_min_control) | m1(:,1)<delta_min_control-fold*(delta_max_control-delta_min_control));
%                 else
%                     pre_outlier = find(m1(:,2)>pre_max_stim+fold*(pre_max_stim-pre_min_stim) | m1(:,2)<pre_min_stim-fold*(pre_max_stim-pre_min_stim));
%                     delta_outlier = find(m1(:,1)>delta_max_stim+fold*(delta_max_stim-delta_min_stim) | m1(:,1)<delta_min_stim-fold*(delta_max_stim-delta_min_stim));
%                 end
%                 outlier_detected = [pre_outlier; delta_outlier];
%                 outlier_detected = unique(outlier_detected);
%                 if ~isempty(outlier_detected)
%                     fprintf('outlier detected')
%                     outlier_detected
%                     
%                     m1_return(outlier_detected,:) = NaN;
%                     m1(outlier_detected,:) = [];
%                 end
%             end
           
            %%%%% outlier ends
            p = polyfit(m1(:,2),m1(:,1),1);
%             m2 = abs(p(2)^2/p(1));
%             m2 = 
           
%             if exist('plot_flag', 'var') && plot_flag
%                 figure(1)
%                 a = obj.DATA_BUFFER.raw(obj.DATA_BUFFER.fst:obj.DATA_BUFFER.lst,8);
%                 plot((1:size(a,1))/obj.data_sampling_frequency, a)
%                 hold on
% 
%                 plot(double([start_index start_index])/obj.data_sampling_frequency,[-1e-4 1e-4 ], 'r-')
%                 plot(double([end_index end_index])/obj.data_sampling_frequency,[-1e-4 1e-4 ], 'r-')
%                 hold off
%      
%                 drawnow
%              
%             end
% 
%  
%             segment_ca3 = objective_data(:,ca3_idx);
%             segment_ca1 = objective_data(:,ca1_idx);
%             objective_data(isnan(objective_data)) = [];
%             [S,f] = mtspectrumc(objective_data, obj.params);
%             params2 = obj.params;
%             params2.fpass = [1 100];
%             [S2,f2] = mtspectrumc(objective_data, params2);
%             figure(2)
%             subplot(3,1,1)
%             plot(f2,mean(S2,2))
%             subplot(3,1,2)
%             plot(objective_segment(:,1))
%             subplot(3,1,3)
%             plot(objective_data(:,1))
%             drawnow
%             m               = mean(sum(S));
%             if isnan(m)
%                 error('nan')
%             end
%             obj.METRIC_BUFFER.append(m);
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

