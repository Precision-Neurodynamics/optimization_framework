classdef opto_granger_causality < handle
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
        function obj = opto_granger_causality(TD_FS, channels, ~)
            obj.data_sampling_frequency             = TD_FS;
            obj.channels                            = channels;
            
            obj.DATA_BUFFER_DURRATION               = 15;
            obj.DATA_VEC_SIZE                       = size(channels,1);
            obj.DATA_BUFFER_SIZE                    = obj.DATA_BUFFER_DURRATION*TD_FS;
            obj.DATA_BUFFER                         = circVBuf(int64(obj.DATA_BUFFER_SIZE),...
                                                    int64(obj.DATA_VEC_SIZE), 0);
            
            obj.metric_sampling_frequency           = 4;
            obj.METRIC_BUFFER_DURRATION             = 20;
            obj.METRIC_BUFFER_VEC_SIZE              = 2;
            obj.METRIC_BUFFER_SIZE                  = obj.METRIC_BUFFER_DURRATION*obj.metric_sampling_frequency;
            obj.METRIC_BUFFER                       = circVBuf(int64(obj.METRIC_BUFFER_SIZE),...
                                                        int64(obj.METRIC_BUFFER_VEC_SIZE), 0);
            obj.name                                = sprintf('Granger Causality');
            
        end
        
        function update_buffer(obj, new_data, update_time)
            obj.data_update_time = update_time;
            
            %             new_data    = new_data - repmat(mean(new_data),size(new_data,1),1);
            %             new_data    = new_data ./ repmat(std(new_data),size(new_data,1),1);
            
            channel   = new_data(:,obj.channels);
            obj.DATA_BUFFER.append(channel);
        end
        
        function m = get_metric(obj,window_start_time, window_end_time, plot_flag)
            if nargin == 2 % obj counts as an nargin
                start_index = obj.DATA_BUFFER.lst - window_start_time * obj.data_sampling_frequency;
                end_index   = obj.DATA_BUFFER.lst;
            else
                start_index         = obj.DATA_BUFFER.lst - obj.DATA_BUFFER.fst - (obj.data_update_time - window_start_time) * obj.data_sampling_frequency ;
                end_index           = obj.DATA_BUFFER.lst - obj.DATA_BUFFER.fst - (obj.data_update_time - window_end_time) * obj.data_sampling_frequency + 0;
            end
            
            objective_segment   = obj.DATA_BUFFER.raw(start_index:end_index,:);
            
            if exist('plot_flag', 'var') && plot_flag
                a = obj.DATA_BUFFER.raw(obj.DATA_BUFFER.fst:obj.DATA_BUFFER.lst,1);
                plot((1:size(a,1))/obj.data_sampling_frequency, a)
                hold on

                plot(double([start_index start_index])/obj.data_sampling_frequency,[-1e-4 1e-4 ], 'r-')
                plot(double([end_index end_index])/obj.data_sampling_frequency,[-1e-4 1e-4 ], 'r-')
                hold off
     
                drawnow
             
            end
            
            channel_a   = objective_segment(:,1);
            channel_b   = objective_segment(:,2);
            X = [channel_a';channel_b'];
            %             [cxy,~]      = mscohere(channel_a,channel_b, [], [],5:10,obj.sampling_frequency);
            % GC calculation
            regmode   = 'OLS';  % VAR model estimation regression mode ('OLS', 'LWR' or empty for default)
            icregmode = 'LWR';  % information criteria regression mode ('OLS', 'LWR' or empty for default)
            momax     = 30;     % maximum model order for model order estimation
            if ~exist('morder')
                [AIC,BIC] = tsdata_to_infocrit(X,momax,icregmode);
                [~,bmo_BIC] = min(BIC);
                morder = bmo_BIC;
            end
            
            [F,A,SIG] = GCCA_tsdata_to_pwcgc(X,morder,regmode);
            assert(~isbad(A),'VAR estimation failed');
            assert(~isbad(F,false),'GC calculation failed');
            G_index = (F(1,2)-F(2,1))/(F(2,1)+F(1,2));
            obj.METRIC_BUFFER.append(G_index);
            m = G_index;
        end
        
        function update_metric(~)
            
        end
    end
    
end

