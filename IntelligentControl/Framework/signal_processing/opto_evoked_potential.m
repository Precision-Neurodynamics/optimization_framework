classdef opto_evoked_potential < handle
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
        metric_freq
        metric_length
        metric_channel
        IIS_remove_flag
        S_th % for IIS removal
        NM % for PiSM model
    end
    
    methods
        function obj = opto_evoked_potential(TD_FS, channels, metric_freq, metric_length, metric_channel)
            obj.data_sampling_frequency             = TD_FS;
            obj.channels                            = channels;
            obj.metric_freq                         = metric_freq;
            obj.metric_length                       = metric_length;
            obj.metric_channel                       = metric_channel;
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

            obj.name                                = sprintf('Evoked potential');
            
        end
        
        function update_buffer(obj, new_data, update_time)
            
            obj.data_update_time    = update_time;
            channel_a               = new_data(:,obj.channels);
            
            obj.DATA_BUFFER.append(channel_a);
            
        end
        
        function m = get_metric(obj,window_start_time, window_end_time, plot_flag,metric_type)
            
            
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
                plot((1:size(a,1))/obj.data_sampling_frequency, a)
                hold on
                plot(double([start_index start_index])/obj.data_sampling_frequency,[-1e-4 1e-4 ], 'r-')
                plot(double([end_index end_index])/obj.data_sampling_frequency,[-1e-4 1e-4 ], 'r-')
                hold off
                drawnow
            end
            
%             objective_data = nan(size(temp,1),16);
            for c1 = 1:size(obj.channels,2)
                objective_data(c1,:) = objective_segment(:,c1);%resample(objective_segment(:,c1), 2000, floor(obj.data_sampling_frequency));
            end
            %%%%%%%%% Evoked potential average %%%%%%%%%%
            Fs =24414;
            N = floor(obj.metric_length*obj.metric_freq);
            datarange = round(Fs*[0:1/obj.metric_freq:0+(N)/obj.metric_freq]);
%             [~,offset] = min(objective_data(2,1:round(24414/obj.metric_freq)));%1680;
%             datarange = (offset-40)+round(Fs*[0:1/obj.metric_freq:N/obj.metric_freq]);
%             dataleng = 0.1*2000; %0.05 sec = 50msec
            dataleng = round(0.015*Fs);
            clear m
            for i=1:1:N
                m(i,:,:) = objective_data(:,datarange(i)+1:datarange(i)+round(1/obj.metric_freq*Fs));
            end
%             [~,peakind] = max(mean(m(:,9,:),1));
%             clear m
%             for i=1:1:N
%                 m(i,:,:) = objective_data(:,datarange(i)+peakind+10^-3*Fs:datarange(i)+peakind+10^-3*Fs+dataleng);
%             end
            figure
%             if metric_type == 1 % positive
%                 plot(1/2000:1/2000:1/2000*size(m,2),mean(m,1),'b')
%             else
%                 plot(1/2000:1/2000:1/2000*size(m,2),mean(m,1),'r')
%             end
            subplot(4,2,1)
            plot(1/Fs:1/Fs:1/Fs*size(m,3),squeeze(mean(m(:,1,:),1)),'b')
%             ylim([-5 5]*10^-3)
            subplot(4,2,2)
            plot(1/Fs:1/Fs:1/Fs*size(m,3),squeeze(mean(m(:,4,:),1)),'b')
%             ylim([-5 5]*10^-3)
            subplot(4,2,3)
            plot(1/Fs:1/Fs:1/Fs*size(m,3),squeeze(mean(m(:,6,:),1)),'b')
%             ylim([-5 5]*10^-3)
            subplot(4,2,4)
            plot(1/Fs:1/Fs:1/Fs*size(m,3),squeeze(mean(m(:,8,:),1)),'b')
%             ylim([-5 5]*10^-3)
            subplot(4,2,5)
            plot(1/Fs:1/Fs:1/Fs*size(m,3),squeeze(mean(m(:,9,:),1)),'b')
%             ylim([-5 5]*10^-3)
            subplot(4,2,6)
            plot(1/Fs:1/Fs:1/Fs*size(m,3),squeeze(mean(m(:,11,:),1)),'b')
%             ylim([-5 5]*10^-3)
            subplot(4,2,7)
            plot(1/Fs:1/Fs:1/Fs*size(m,3),squeeze(mean(m(:,14,:),1)),'b')
%             ylim([-5 5]*10^-3)
            subplot(4,2,8)
            plot(1/Fs:1/Fs:1/Fs*size(m,3),squeeze(mean(m(:,15,:),1)),'b')
%             ylim([-5 5]*10^-3)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             obj.METRIC_BUFFER.append(m);
        end
        
    end
    
end

