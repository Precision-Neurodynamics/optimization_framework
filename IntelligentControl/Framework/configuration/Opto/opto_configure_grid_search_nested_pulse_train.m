function [optimizer, stimulation_manager, metric_objects, display_objects] = opto_configure_grid_search_nested_pulse_train(TD, DEBUG)

%
% Configure logging
%
temp = datestr(now,2);
temp(strfind(temp,'/')) =[]; % Today date

animal_id                                   = 'ARN084';
experiment_name                             = 'nested_frequency';
video_name                                  = strcat('Z:\Sang_video\',animal_id,'_',temp,'_',experiment_name,'.avi');

if exist(video_name)
    [a,b,c] = fileparts(video_name);
    video_name = strcat(a,'\',b,'_2',c);
end

if strcmp(animal_id, '') ||  strcmp(experiment_name, '')
    [animal_id, experiment_name]                = get_experiment_info(DEBUG);    
end

if DEBUG
    experiment_name = [experiment_name 'DEBUG'];
end

cd('C:\Users\TDT\Documents\IntelligentControl');

result_dir                                  = ['results/' animal_id];
time_str                                    = datestr(now, 30);
log_pattern                                 = [result_dir '/' experiment_name '-%s_%s'];
exp_directory                               = sprintf(log_pattern, animal_id, time_str);
mkdir(exp_directory)

%
% Configure the stimulation_object
%
stimulation_manager                         = opto_stimulator_3();
stimulation_manager.TD                      = TD;
stimulation_manager.device_name             = TD.GetDeviceName(0);
stimulation_manager.sampling_frequency      = TD.GetDeviceSF(stimulation_manager.device_name);
stimulation_manager.stimulation_channels    = 10;

stimulation_manager.stimulation_type        = 'train';
stimulation_manager.headstage_type          = 'ZC16-OB1';
stimulation_manager.electrode_location      = 'HPC';
stimulation_manager.logging_directory       = exp_directory;


stimulation_manager.tank_name               = strcat('C:\TDT\OpenEx\MyProjects\CustomStimActiveX_Opto\DataTanks\CustomStimActiveX_Opto_DT1_',temp);
stimulation_manager.block_name              = get_block_name_opto(stimulation_manager.tank_name);
stimulation_manager.initialize();

stimulation_manager.animal_id                = animal_id;
stimulation_manager.experiment_name          = experiment_name;
stimulation_manager.experiment_start_time    = posixtime(datetime('now'));
stimulation_manager.display_log_output       = 'simple';
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
%
% Configure the metrics and objective function
%
metric_1        = mt_spectrogram(stimulation_manager.sampling_frequency,1:16, exp_directory);
metric_objects  = {metric_1};
display_objects = metric_objects;

%
% Configure the optimization object
%
optimizer = opto_grid_search_3();

optimizer.TD                        = TD;
optimizer.n_samples                 = 1; %%% THIS LINE SAYS WHERE TO START THE STIMULATION
optimizer.video_filename = video_name;

%Compet-train
stimulation_manager.stimulation_type   	= 'train';
optimizer.stimulation_time_s            = 8; % Starting delay, [sec]
optimizer.evaluate_delay_s              = 8; % Delay after stimulation finish, [sec]
optimizer.frequency_pulse               = [65.9 67.2 65.9];     
optimizer.frequency_train               = [7.7  5.2  7.7];    
optimizer.duration                      = [8    8    8];
optimizer.width_pulse               = [4    4    4]*10^-3;
optimizer.width_train               = [75   75   75]*10^-3;
optimizer.amplitude                 = [5 5 0];
optimizer.n_repetitions             = 30;

optimizer.random_flag               = 1;
optimizer.combvec_flag              = 0;
optimizer.rep_flag                  = 0;


if strcmp(stimulation_manager.stimulation_type,'standard')==1
    if optimizer.combvec_flag == 1
    optimizer.width_train = 1;
    optimizer.frequency_train = 0;
    else
        optimizer.width_train = ones(1,length(optimizer.width_pulse));
        optimizer.frequency_train = zeros(1,length(optimizer.frequency_pulse));
    end
end
optimizer.stim_channels             = [10];
optimizer.logging_directory         = exp_directory;
optimizer.display_log_output        = 'simple';
optimizer.stimulator                = stimulation_manager;

optimizer.initialize();

end

