function biomarker_table = generate_spectral_biomarker_directory( directory, tag )
%GENERATE_SPECTRAL_BIOMARKER_DIRECTROY Summary of this function goes here
%   Detailed explanation goes here

tag = 'get_average_theta_power_bipolar';
biomarker_function = @get_average_theta_power_bipolar;

directory       = 'Z:\extracted_data\ARN045\1D_Amplitude\amplitude_grid_1_post\';
data            = [];

experiment_table = [];
load([directory 'experiment_table.mat']);
d = dir(directory);

n_files             = numel(d);
biomarkers          = nan(n_files,1);
stimulation_time    = nan(n_files,1);
window              = 3;
parfor c1 = 1:n_files
    file_name = d(c1).name;
    if strfind(file_name, 'amplitude_grid');
        data_struct = load([directory file_name]);
        
        l_index             = experiment_table.stimulation_time == data_struct.stim_start;
        sampling_frequency  = experiment_table.sampling_frequency(l_index);
        duration            = experiment_table.stimulation_duration(l_index);
        
        stimulation_start   = data_struct.stim_start - data_struct.t1;
        stimulation_end     = stimulation_start+duration + 0.002;       
        
        pre_stimulation_start       = floor((stimulation_start - window)*sampling_frequency);
        pre_stimulation_stop        = floor(stimulation_start*sampling_frequency);
        
        post_stimulation_start      = floor(stimulation_end*sampling_frequency);
        post_stimulation_stop       = floor((stimulation_end + window)*sampling_frequency);
        
        pre_stimulation_segment     = data_struct.data(:,pre_stimulation_start:pre_stimulation_stop);
        post_stimulation_segment    = data_struct.data(:,post_stimulation_start:post_stimulation_stop);
        
        
        stimulation_time(c1)        = experiment_table.stimulation_time(l_index);
        
        biomarkers(c1)              = feval(biomarker_function, ...
            pre_stimulation_segment, post_stimulation_segment, sampling_frequency);
%         t = (1:length(data(1,:)))/sampling_frequency;
%         plot(t, data(1,:))
%         hold on
%         plot(t(pre_stimulation_start:pre_stimulation_stop), pre_stimulation_segment(1,:));
%         plot([stim_start stim_start] - t1, [-0.01 0.01])
%         plot([stimulation_end stimulation_end] - t1, [-0.01 0.01])
%         hold off
        c1
    end
end
stimulation_time    = stimulation_time(~isnan(stimulation_time));
biomarkers          = biomarkers(~isnan(biomarkers));
 
biomarker_table     = table(stimulation_time, biomarkers);
file_name           = sprintf('biomarker_%s_window-%d.mat', tag, window);
save([directory file_name], 'biomarker_table');
end

function biomarker  = get_average_theta_power(pre_stimulation_segment, post_stimulation_segment, sampling_frequency)
params.tapers   = [3 5];
params.fpass    = [4 100];

params.Fs       = sampling_frequency;
pre_S           = mtspectrumc(pre_stimulation_segment',params);
post_S          = mtspectrumc(post_stimulation_segment',params);

delta_S         = post_S - pre_S;
biomarker       = mean(sum(delta_S));
end

function biomarker  = get_average_theta_power_bipolar(pre_stimulation_segment, post_stimulation_segment, sampling_frequency)
params.tapers   = [3 5];
params.fpass    = [4 100];
params.Fs       = sampling_frequency;
bipolar_ref     = [2 1; 4 3; 5 6; 7 8];

% Normalize signals
pre_stimulation_segment     = pre_stimulation_segment - repmat(mean(pre_stimulation_segment,2),1,size(pre_stimulation_segment,2));
post_stimulation_segment    = post_stimulation_segment - repmat(mean(post_stimulation_segment,2),1,size(post_stimulation_segment,2));

pre_stimulation_segment     = pre_stimulation_segment ./ repmat(std(pre_stimulation_segment,[],2),1,size(pre_stimulation_segment,2));
post_stimulation_segment    = post_stimulation_segment ./ repmat(std(post_stimulation_segment,[],2),1,size(post_stimulation_segment,2));

% Re-reference signals
pre_stimulation_segment     = pre_stimulation_segment(bipolar_ref(:,1),:) - pre_stimulation_segment(bipolar_ref(:,2),:);
post_stimulation_segment    = post_stimulation_segment(bipolar_ref(:,1),:) - post_stimulation_segment(bipolar_ref(:,2),:);

pre_S           = mtspectrumc(pre_stimulation_segment',params);
post_S          = mtspectrumc(post_stimulation_segment',params);

delta_S         = post_S - pre_S;
biomarker       = mean(sum(delta_S));
end

