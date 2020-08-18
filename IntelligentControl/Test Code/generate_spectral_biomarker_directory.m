function biomarker_table = generate_spectral_biomarker_directory( directory, tag )
%GENERATE_SPECTRAL_BIOMARKER_DIRECTROY Summary of this function goes here
%   Detailed explanation goes here

tag = 'get_average_theta_power_bipolar_pre';
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
offset              = -3;
parfor c1 = 1:n_files
    file_name = d(c1).name;
    if strfind(file_name, 'amplitude_grid');
        data_struct = load([directory file_name]);
        
        l_index             = experiment_table.stimulation_time == data_struct.stim_start;
        sampling_frequency  = experiment_table.sampling_frequency(l_index);
        duration            = experiment_table.stimulation_duration(l_index);
        
        stimulation_start   = data_struct.stim_start - data_struct.t1;
        stimulation_end     = stimulation_start+duration;       
        
        if offset < 0
            segment_start       = floor((stimulation_start + offset)*sampling_frequency);
            segment_stop        = floor(stimulation_start*sampling_frequency);
        elseif offset > 0
            segment_start       = floor((stimulation_end+offset)*sampling_frequency);
            segment_stop        = floor((segment_start + window)*sampling_frequency);
        end
       
        segment                 = data_struct.data(:,segment_start:segment_stop);
           
        stimulation_time(c1)    = experiment_table.stimulation_time(l_index);
        
        biomarkers(c1)          = feval(biomarker_function, segment, sampling_frequency);

        c1
    end
end
stimulation_time    = stimulation_time(~isnan(stimulation_time));
biomarkers          = biomarkers(~isnan(biomarkers));
 
biomarker_table     = table(stimulation_time, biomarkers, 'VariableNames', {'stimulation_time', tag});
file_name           = sprintf('biomarker_%s_window-%d.mat', tag, window);
save([directory file_name], 'biomarker_table');
end

function biomarker  = get_average_theta_power_bipolar(segment, sampling_frequency)
params.tapers   = [3 5];
params.fpass    = [4 100];
params.Fs       = sampling_frequency;
bipolar_ref     = [2 1; 4 3; 5 6; 7 8];

% Normalize signals
segment     = segment - repmat(mean(segment,2),1,size(segment,2));
segment     = segment ./ repmat(std(segment,[],2),1,size(segment,2));

% Re-reference signals
segment     = segment(bipolar_ref(:,1),:) - segment(bipolar_ref(:,2),:);

S           = mtspectrumc(segment',params);
biomarker   = mean(sum(S));
end

