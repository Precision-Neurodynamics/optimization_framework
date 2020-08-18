% % Create table
% results_home = 'results/';
% 
% directories = {'grid_search_calibration_duration-ARN045_20160526T113958', ...
% 'grid_search_calibration_duration-ARN045_20160526T114303', ...
% 'grid_search_calibration_duration-ARN045_20160526T114550', ...
% 'grid_search_calibration_duration-ARN045_20160526T114955', ...
% 'grid_search_calibration_duration-ARN045_20160526T115311', ...
% 'grid_search_calibration_duration-ARN045_20160526T115525', ...
% 'grid_search_calibration_duration-ARN045_20160526T115653', ...
% 'grid_search_calibration_duration-ARN045_20160526T120152', ...
% 'grid_search_calibration_duration-ARN045_20160526T121427', ...
% 'grid_search_calibration_duration-ARN045_20160526T122120', ...
% 'grid_search_calibration_duration-ARN045_20160526T122416', ...
% 'grid_search_calibration_duration-ARN045_20160526T122655', ...
% 'grid_search_calibration_duration-ARN045_20160526T130546'};
% 
% Take relevant directories and create stimulation table
% experiment_table = table();
% for c1 = 1:numel(directories)
%     
%     t = readtable([results_home directories{c1} '/stimulation_table.csv']);
%     
%     if strcmp(t.block_name{1}(1:5),'Block')
%         experiment_table = [experiment_table; t];
%     end
% end
% Extract each stimulation
% 
% % Extract data
% offset = -5;
% duration = 20;
% for c1 = 1:length(experiment_table.animal_id)
%     stim_start = experiment_table.stimulation_time(c1)/experiment_table.sampling_frequency(c1);
%     
%     t1          = stim_start + offset;
%     t2          = t1 + duration;
%     d           = TDT2mat('MainDataTank', experiment_table.block_name{c1}, 'STORE', 'Wave', 'T1', t1, 'T2', t2);
%     data{c1}    = d.streams.Wave.data;
% end
% 
% Process
bipolar_channels = [2 4; 6 8; 11 9;15 13];
params.Fs       = experiment_table.sampling_frequency(1);
params.fpass    = [4 10];
params.tapers   = [3 5];

% Calculate metrics
theta_power = [];
for c1 = 1:numel(data)
    positive_channels   = data{c1}(bipolar_channels(:,1),:);
    negative_channels   = data{c1}(bipolar_channels(:,2),:);
    
    positive_channels   = positive_channels - repmat(mean(positive_channels), size(positive_channels,1), 1);
    positive_channels   = positive_channels ./ repmat(std(positive_channels), size(positive_channels,1),1);
    
    negative_channels   = negative_channels - repmat(mean(negative_channels), size(negative_channels,1), 1);
    negative_channels   = negative_channels ./ repmat(std(negative_channels), size(negative_channels,1),1);
    stimulation_segment = positive_channels-negative_channels;
    [S,time_t,f]             = mtspecgramc(stimulation_segment',[.25 .25], params);
    tp                  = mean(sum(S,2),3);
    theta_power(c1,:)   = tp;
end

%%
% Plot overlay
close all
durations = unique(experiment_table.stimulation_duration);
objective = [];
for c1 = 1:numel(durations)
    dur_index = experiment_table.stimulation_duration == durations(c1);
    theta_for_dur = theta_power(dur_index,:);
    mean_   = mean(abs(theta_for_dur));
    sigma_  = std(abs(theta_for_dur));
    
    stim_start          = 5;
    stim_stop           = 5+durations(c1);
    objective_stop      = stim_stop+5;
    objective_start_idx = find(time_t > stim_stop,1);
    objective_stop_idx = find(time_t > stim_stop + 5,1);
   
    subplot(3,3,c1)
    
    plot(time_t,mean_, 'linewidth', 2,'color', [0 0 0]);
    hold on
    plot(time_t,mean_ + sigma_, 'linewidth', .5,'color', [0 0 0], 'linestyle', '-');
    
    plot([5 5+durations(c1)], [.01 .01], 'linewidth', 2,'color', [1 0 0])
    plot(time_t,mean_ - sigma_, 'linewidth', .5,'color', [0 0 0], 'linestyle', '-');

    title(sprintf('Duration: %.2fs', durations(c1)));
    xlabel('seconds');
    ylabel('Normalized Theta Power');
    hold off
    if c1 == 1
       legend({'Mean','STD','Stimulation On'}); 
    end
end

%%
figure;
for c2 = 1:9
    for c1 = 1:numel(durations)
        dur_index       = experiment_table.stimulation_duration == durations(c1);
        theta_for_dur   = theta_power(dur_index,:);
        mean_           = mean(abs(theta_for_dur));
        sigma_          = std(abs(theta_for_dur));

        stim_start          = 5;
        stim_stop           = 5+durations(c1);
        objective_stop      = stim_stop+5;
        objective_start_idx = find(time_t > stim_stop,1);
        objective_stop_idx = find(time_t > stim_stop + c2,1);

        objective(:,c1) = mean(theta_for_dur(:,objective_start_idx:objective_stop_idx),2) ...
            - mean(theta_for_dur(:,1:20),2);
        
    end
    subplot(3,3,c2);
    errorbar(durations, mean(objective), std(objective), 'k-', 'linewidth',2)
    xlabel('Stimulation Duration (s)')
    title(sprintf('Average Theta Power across %ds post-stim', c2)); 
end



