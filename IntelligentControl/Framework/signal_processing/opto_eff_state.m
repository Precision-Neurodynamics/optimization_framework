classdef opto_eff_state < handle
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
        metric_band
        model_coefficients
        bin_min
        bin_max
    end
    
    methods
        function obj = opto_eff_state(TD_FS,channels,metric_band);
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
        
        function m = get_metric(obj,window_start_time, window_end_time)
            tic
            ca3_idx = [1 2 3 4];
            ca1_idx = [8 7 6 5];
            
            if ~isempty(obj.data_update_time)
                start_index         = obj.DATA_BUFFER.lst - obj.DATA_BUFFER.fst - (obj.data_update_time - window_start_time) * obj.data_sampling_frequency ;
                end_index           = obj.DATA_BUFFER.lst - obj.DATA_BUFFER.fst - (obj.data_update_time - window_end_time) * obj.data_sampling_frequency + 0;
                temp_seg = obj.DATA_BUFFER.raw(obj.DATA_BUFFER.fst:obj.DATA_BUFFER.lst,:);
                objective_segment   = temp_seg(start_index:end_index,:);
                ds_factor = 24;
            objective_data = objective_segment(1:24:round(size(objective_segment,1)/ds_factor)*ds_factor+1);
 
%             segment_ca3 = objective_data(:,ca3_idx);
%             segment_ca1 = objective_data(:,ca1_idx);
%             objective_data(isnan(objective_data)) = [];
            [S,f] = mtspectrumc(objective_data, obj.params);
            m               = mean(sum(S));
            obj.METRIC_BUFFER.append(m);
            toc
            else
                m = 0;
            end
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

