function  extract_data_model(tag, animal_id, experiment_date, experiment_name)
dbstop if error

%  tag                     = 'grid';
% tag                     = 'bayesian_optimization';
% animal_id               = 'ARN059';
% experiment_date         = '2017_11_15';
% experiment_name         = 'random_search_admets_amplitude-duration_PID-12-ARN059_20171115T153636';

data_directory          = ['Z:\extracted_data\' animal_id '\' experiment_date '\' experiment_name '\'];
drop_box                = 'C:\Users\TDT\Dropbox\';
resample_rate           = 2000;

load(sprintf('%sexperiment_table_%s.mat', data_directory, tag));
d                       = dir(data_directory);

n_files                 = numel(d);
x_data                  = [];
time_data               = [];

index                   = 1;

for c1 = 1:n_files

    file_name = d(c1).name;
    if isempty(strfind(file_name, tag)) || ~isempty(strfind(file_name, 'experiment_table'));
        continue
    end

    load([data_directory file_name], 'stim_start', 't1');

    table_index             = experiment_table.stimulation_time == stim_start;
    table_row               = experiment_table(table_index,:);
    sampling_frequency      = table_row.sampling_frequency;
    stimulation_duration    = table_row.stimulation_duration;
    stimulation_amplitude   = table_row.stimulation_amplitude_a*2;
    stimulation_frequency   = table_row.pulse_frequency;


    fprintf('Segment: %d/%d\n',c1, n_files);

    xxx = load([data_directory file_name]);

    stimulation_start       = stim_start - t1;
   
    data                    = resample_data(xxx.data, sampling_frequency, resample_rate);
    
    model_data{index}       = data;             
    x_data                  = [x_data ; stimulation_duration, stimulation_amplitude, stimulation_frequency];
    time_data               = [time_data; stimulation_start];
    
    index                   = index + 1;
end

save(sprintf('%s/model_data_%s.mat', data_directory,experiment_name), 'model_data', 'x_data', 'time_data', '-v7.3')
save(sprintf('%s/model_data_%s.mat', drop_box, experiment_name ), 'model_data', 'x_data', 'time_data', '-v7.3')

end


function data_r = resample_data(data, sampling_frequency,  resample_rate)

for c1 = 1:size(data,1)
    data_r(c1,:) = resample(double(data(c1,:)), floor(resample_rate), floor(sampling_frequency));
end

end

function d_filt = filter_data(d, sampling_frequency)

low_pass        = 60;

[z,p,k]         = butter(15,low_pass/sampling_frequency*2);
soshi           = zp2sos(z,p,k);
d_filt          = sosfilt(soshi,d')';


end
