classdef opto_model_state < handle
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
        metric_type
        IIS_remove_flag
        S_th % for IIS removal
        NM % for PiSM model
    end
    
    methods
        function obj = opto_model_state(TD_FS, channels, metric_def, metric_type, model_location)
            obj.data_sampling_frequency             = TD_FS;
            obj.channels                            = channels;
            obj.metric_type                         = metric_type;
            obj.DATA_BUFFER_DURRATION               = 120;
            obj.DATA_VEC_SIZE                       = size(channels,2);
            obj.DATA_BUFFER_SIZE                    = obj.DATA_BUFFER_DURRATION*TD_FS;
            obj.DATA_BUFFER                         = circVBuf(int64(obj.DATA_BUFFER_SIZE),...
                int64(obj.DATA_VEC_SIZE), 0);
            
            obj.metric_sampling_frequency           = 4;
            obj.METRIC_BUFFER_DURRATION             = 25;
            obj.METRIC_BUFFER_VEC_SIZE              = 1;
            obj.METRIC_BUFFER_SIZE                  = obj.METRIC_BUFFER_DURRATION*obj.metric_sampling_frequency;
            obj.METRIC_BUFFER                       = circVBuf(int64(obj.METRIC_BUFFER_SIZE),...
                int64(obj.METRIC_BUFFER_VEC_SIZE), 0);
            
            obj.params.Fs                           = 2000;
            obj.params.tapers                       = [3 5];%[3 5];
            if strcmp(metric_type,'PSD') == 1
                obj.params.fpass                        = metric_def;%[40 45];
            elseif strcmp(metric_type,'Model') == 1
                obj.params.fpass = [0.1 300];
            end
            if ~isempty(model_location)
                obj.model_coefficients                  = load(model_location);
            end
            obj.name                                = sprintf('Opto gamma [33-50Hz] max');
            
        end
        
        function update_buffer(obj, new_data, update_time)
            
            obj.data_update_time    = update_time;
            channel_a               = new_data(:,obj.channels);
            
            obj.DATA_BUFFER.append(channel_a);
            
        end
        
        function m = get_metric(obj,window_start_time, window_end_time, plot_flag)
            
            %             if nargin == 2 % just window_start_time
            %                 start_index = obj.DATA_BUFFER.lst - window_start_time * obj.data_sampling_frequency;
            %                 end_index   = obj.DATA_BUFFER.lst;
            %                 objective_segment = obj.DATA_BUFFER.raw(start_index:end_index,:);
            %
            %             else % window_start_time and window_end_time
            %                 start_index         = obj.DATA_BUFFER.lst - obj.DATA_BUFFER.fst - (obj.data_update_time - window_start_time) * obj.data_sampling_frequency ;
            %                 end_index           = obj.DATA_BUFFER.lst - obj.DATA_BUFFER.fst - (obj.data_update_time - window_end_time) * obj.data_sampling_frequency + 0;
            %                 temp_seg = obj.DATA_BUFFER.raw(obj.DATA_BUFFER.fst:obj.DATA_BUFFER.lst,:);
            %                 objective_segment   = temp_seg(start_index:end_index,:);
            %             end
            start_index         = obj.DATA_BUFFER.lst - obj.DATA_BUFFER.fst - (obj.data_update_time - window_start_time) * obj.data_sampling_frequency ;
            end_index           = obj.DATA_BUFFER.lst - obj.DATA_BUFFER.fst - (obj.data_update_time - window_end_time) * obj.data_sampling_frequency;
            temp_seg = obj.DATA_BUFFER.raw(obj.DATA_BUFFER.fst:obj.DATA_BUFFER.lst,:);
            if end_index>size(temp_seg,1)
                end_index = size(temp_seg,1);
            end
            objective_segment   = temp_seg(start_index:end_index,:);
            
            if exist('plot_flag', 'var') && plot_flag
                figure(1)
                a = obj.DATA_BUFFER.raw(obj.DATA_BUFFER.fst:obj.DATA_BUFFER.lst,8);
                plot((1:size(a,1))/obj.data_sampling_frequency, a); xlabel('Time (s)'); ylabel('Amplitude (?v)'); title('Voltage Recording');
                hold on
                plot(double([start_index start_index])/obj.data_sampling_frequency,[-1e-4 1e-4 ], 'r-')
                plot(double([end_index end_index])/obj.data_sampling_frequency,[-1e-4 1e-4 ], 'r-')
                hold off
                drawnow
            end
            
            temp = resample(objective_segment(:,1), 2000, floor(obj.data_sampling_frequency));
            objective_data = nan(size(temp,1),16);
            for c1 = 1:size(obj.channels,2)
                objective_data(:,obj.channels(c1)) = resample(objective_segment(:,c1), 2000, floor(obj.data_sampling_frequency));
            end
            
            %%%%%%%%%%%%%%%%%%%% IIS detetion %%%%%%%%%%%%%%%%%%%%%%%%%
            tempdata = objective_data';
            Cheff = obj.channels;
            Fs = 2000;
            if obj.IIS_remove_flag == 1
                MWIIS = 0.1;
                WIIS = 0.5;
                IISW = 0:MWIIS:floor(size(tempdata,2)/Fs);
                %%%%%%% IIS detect %%%%%%%
                IISW_flag(1:length(IISW)-1,1) = 1;
                IIS_detected = BO_IIS_detect_power(tempdata(Cheff,:),obj.S_th(Cheff),WIIS,MWIIS,2000,0);
                for c1=1:1:length(Cheff)
                    IIS{c1} = round(IIS_detected.time_Sp_final{c1},1);
                    for c2=1:1:size(IIS{c1},1)
                        startI = round(round(IIS{c1}(c2,1),2)/MWIIS)+1;
                        endI = round(round(IIS{c1}(c2,2),2)/MWIIS);
                        IISW_flag(startI:endI,1) = 0;
                    end
                end
                %%% IISW_flag = IIS alltogether
                IIS_flag = find(IISW_flag == 0);
                
                %%% IIS removal
                for i1=1:1:length(IIS_flag)
                    tempdata(:,round(IISW(IIS_flag(i1))*Fs)+1:round(IISW(IIS_flag(i1)+1)*Fs)) = NaN;
                end
                
                todel = find(isnan(tempdata(1,:)));
                tempdata(:,todel) = [];
                objective_data = tempdata';
            end
            %%%%%%%%%%%%%%%%%%%%% IIS done %%%%%%%%%%%%%%%%%%%%%%%%%
            
            if strcmp(obj.metric_type,'PSD') == 1
                %%Changed if size(objective_data,1)>Fs*3 due to Turbo Mode%
                if size(objective_data,1)>Fs*0.3
                [S,f] = mtspectrumc(objective_data, obj.params);
                S = real(S);
                params2 = obj.params;
                params2.fpass = [1 100];
                [S2,f2] = mtspectrumc(objective_data, params2);
                S2 = real(S2);
                figure(2)
                subplot(3,1,1)
                plot(f2,nanmean(S2,2)); xlabel('Frequency'); ylabel('Amplitude');
                title('Power Spectral Density');
                subplot(3,1,2)
                plot(objective_segment(:,1)); xlabel('Samples'); ylabel('Amplitude');
                subplot(3,1,3)
                plot(objective_data(:,1)); xlabel('Samples'); ylabel('Amplitude');
                drawnow
                m               = nanmean(nansum(S,2),1);
                else
                    m = nan;
                end
                
            elseif strcmp(obj.metric_type,'PiSM') == 1
                Ch_CA3 = [];
                Ch_CA1 = [];
                for c1 = 1:size(obj.channels,2)
                    if mod(obj.channels(c1),2) == 0
                        Ch_CA3(end+1) = obj.channels(c1);
                    else
                        Ch_CA1(end+1) = obj.channels(c1);
                    end
                end
                if size(objective_data,1)>Fs*3 % at least 3 second of non-IIS
                PSDCA1 = get_PSD_1Hz(objective_data,Ch_CA1);
                PSDCA3 = get_PSD_1Hz(objective_data,Ch_CA3);
                [COH,PHI] = get_COH_1Hz(objective_data,Ch_CA1,Ch_CA3);
                feat = [PSDCA1 PSDCA3 COH PHI];
                feat = (feat-obj.NM.meanN)./obj.NM.stdN;
                for i=1:1:length(feat)
                    if abs(feat(i))>3
                        feat(i) = sign(feat(i))*3; % all feat suppressed to be maximum at 3
                    end
                end
                m = feat*obj.model_coefficients.beta1;
                else
                    m = nan;
                end
            elseif strcmp(obj.metric_type,'EGM') == 1
                Ch_CA3 = [];
                Ch_CA1 = [];
                for c1 = 1:size(obj.channels,2)
                    if mod(obj.channels(c1),2) == 0
                        Ch_CA3(end+1) = obj.channels(c1);
                    else
                        Ch_CA1(end+1) = obj.channels(c1);
                    end
                end
                if size(objective_data,1)>Fs*3
                PSDCA1 = get_PSD_1Hz(objective_data,Ch_CA1);
                PSDCA3 = get_PSD_1Hz(objective_data,Ch_CA3);
                [COH,PHI] = get_COH_1Hz(objective_data,Ch_CA1,Ch_CA3);
                feat = [PSDCA1 PSDCA3 COH PHI];
                feat = (feat-obj.model_coefficients.meanN)./obj.model_coefficients.stdN;
                for i=1:1:length(feat)
                    if abs(feat(i))>3
                        feat(i) = sign(feat(i))*3; % all feat suppressed to be maximum at 3
                    end
                end
                m = feat*obj.model_coefficients.beta1;
                else
                    m = nan;
                end
            end
            obj.METRIC_BUFFER.append(m);
        end
        
        %         function features = bin_data(~, data, f)
        %            features = [];
        %            for c2 = 1:size(data,3)
        %                channel_features = [];
        %                for c1 = 1:49
        %                    idx = f > c1 & f < (c1+1);
        %                    power_bin = squeeze(sum(data(:,idx,c2),2));
        %
        %                    channel_features(:, c1) = power_bin;
        %                end
        %                features = [features, channel_features];
        %            end
        %         end
        
    end
    
end

