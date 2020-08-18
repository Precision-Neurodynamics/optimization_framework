classdef model_state < handle
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
        
        model_coefficients
        bin_min
        bin_max
    end
    
    methods
        function obj = model_state(TD_FS, channels, ~, model_location)
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
            obj.params.tapers                       = [3 5];
            obj.params.fpass                        = [1 50];
            obj.model_coefficients                  = load(model_location);
            obj.model_coefficients                  = obj.model_coefficients.g;
            obj.name                                = sprintf('ADMETS Logistic Regression Model');
            
        end
        
        function update_buffer(obj, new_data, update_time)

            obj.data_update_time    = update_time;
            channel_a               = new_data(:,obj.channels);
            
            obj.DATA_BUFFER.append(channel_a);

        end
        
        function m = get_metric(obj,window_start_time, window_end_time, plot_flag)
            ca3_idx = [1 2 3 4];
            ca1_idx = [8 7 6 5];
            
            if nargin == 2 % just window_start_time
                start_index = obj.DATA_BUFFER.lst - window_start_time * obj.data_sampling_frequency;
                end_index   = obj.DATA_BUFFER.lst;
            else % window_start_time and window_end_time
                start_index         = obj.DATA_BUFFER.lst - obj.DATA_BUFFER.fst - (obj.data_update_time - window_start_time) * obj.data_sampling_frequency ;
                end_index           = obj.DATA_BUFFER.lst - obj.DATA_BUFFER.fst - (obj.data_update_time - window_end_time) * obj.data_sampling_frequency + 0;
            end
            
            objective_segment   = obj.DATA_BUFFER.raw(start_index:end_index,:);
               
            if exist('plot_flag', 'var') && plot_flag
                a = obj.DATA_BUFFER.raw(obj.DATA_BUFFER.fst:obj.DATA_BUFFER.lst,8);
                plot((1:size(a,1))/obj.data_sampling_frequency, a)
                hold on

                plot(double([start_index start_index])/obj.data_sampling_frequency,[-1e-4 1e-4 ], 'r-')
                plot(double([end_index end_index])/obj.data_sampling_frequency,[-1e-4 1e-4 ], 'r-')
                hold off
     
                drawnow
             
            end
            
            for c1 = 1:size(obj.channels,2)
                objective_data(:,c1) = resample(objective_segment(:,c1), 2000, floor(obj.data_sampling_frequency));
                objective_data(:,c1) = objective_data(:,c1); % Convert to millivolts
            end
            
            segment_ca3 = objective_data(:,ca3_idx);
            segment_ca1 = objective_data(:,ca1_idx);
            
            [coherence_data,~,~,ca3_power, ca1_power,~,f] = cohgramc(segment_ca3, segment_ca1, [5 5], obj.params);
            
            power_data      = cat(3, ca3_power, flip(ca1_power,3));
            power_data      = obj.bin_data(power_data, f);
            coherence_data  = obj.bin_data(coherence_data, f);
            
            features        = [power_data, coherence_data];
%             scores          = glmval(obj.model_coefficients, features, 'logit');
            
            scores          = 1*features(:,213); 


            m               = mean(scores);
            
            obj.METRIC_BUFFER.append(m);
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

