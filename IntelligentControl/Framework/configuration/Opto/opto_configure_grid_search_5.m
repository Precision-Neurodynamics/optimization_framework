function [optimizer, stimulation_manager, metric_objects, display_objects] = opto_configure_grid_search_3(TD, DEBUG)

%
% Configure logging
%
animal_id                                   = 'EPI019';
experiment_name                             = 'Test1120_Grid';%'Competition_BO_6-10Hz_max';%'Seiz_C2';%'Seiz_C2';
video_name                                  = 'Z:\Sang_video\Seizure_C2_0519.avi';

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
result_dir                                  = ['results/' animal_id];
time_str                                    = datestr(now, 30);
log_pattern                                 = [result_dir '/' experiment_name '-%s_%s'];
exp_directory                               = sprintf(log_pattern, animal_id, time_str);
mkdir(exp_directory)

% video_filename                              = 'Z:\Sang_video\test_opto_0427_1.avi';

%
% Configure the stimulation_object
%
stimulation_manager                         = opto_stimulator_3();
stimulation_manager.TD                      = TD;
stimulation_manager.device_name             = TD.GetDeviceName(0);
stimulation_manager.sampling_frequency      = TD.GetDeviceSF(stimulation_manager.device_name);
stimulation_manager.stimulation_channels    = 10;

stimulation_manager.stimulation_type        = 'train'; % Only for opto_grid_search_3
stimulation_manager.headstage_type          = 'ZC16-OB1';
stimulation_manager.electrode_location      = 'HPC';
stimulation_manager.logging_directory       = exp_directory;


stimulation_manager.tank_name               = 'C:\TDT\OpenEx\MyProjects\CustomStimActiveX_Opto\DataTanks\CustomStimActiveX_Opto_DT1_112017';%'C:\TDT\OpenEx\Tanks\Data_Tank_2017_01_20';%'E:\ARN050\ARN050';%
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
metric_2        = opto_eff_state(stimulation_manager.sampling_frequency,[1:16],[1 55]);
metric_objects  = {metric_1};
display_objects = metric_objects;
% display_objects = [];

%
% Configure the optimization object
%
optimizer = opto_grid_search_3();

% optimizer.objective_function        = metric; 
optimizer.TD                        = TD;
optimizer.n_samples                 = 1; %%% THIS LINE SAYS WHERE TO START THE STIMULATION
optimizer.video_filename = video_name;
% optimizer.objective_function      = metric_2;


% GRID
% optimizer.stimulation_time_s        = 20; % Starting delay, [sec]
% optimizer.evaluate_delay_s          = 60; % Delay after stimulation finish, [sec]
% optimizer.frequency                 = [7];%[11 12 13 14 15]; %[35]; % %
% optimizer.duration                  = [20];
% optimizer.width                     = [0.1 0.5 2 5 10 20 50]; % ms
% optimizer.amplitude                 = [4.5];%[4.1];
% optimizer.n_repetitions             = 5;

% NOR
optimizer.stimulation_time_s        = 5; % Starting delay, [sec]
optimizer.evaluate_delay_s          = 20; % Delay after stimulation finish, [sec]
optimizer.frequency_pulse                 = [50 100];%[11 12 13 14 15]; %[35]; % %
optimizer.frequency_train                 = [5 7 11];
optimizer.duration                  = [5];
optimizer.width_pulse                     = [2 4].*0.001; % ms
optimizer.width_train                     = [25 50 75].*0.001; % ms
optimizer.amplitude                 = [5];%[4.1];
optimizer.n_repetitions             = 3;



%Short grid
% optimizer.stimulation_time_s        = 6; % Starting delay, [sec]
% optimizer.evaluate_delay_s          = 6; % Delay after stimulation finish, [sec]
% optimizer.frequency                 = [5 7 11 17 23 35 42]; %[7]; %
% optimizer.duration                  = [12];
% optimizer.width                     = [2 5 10]; % ms
% optimizer.amplitude                 = [4.6 4.3 4];
% optimizer.n_repetitions             = 10;

optimizer.stim_channels             = [10];
optimizer.logging_directory         = exp_directory;
optimizer.display_log_output        = 'simple';
optimizer.stimulator                = stimulation_manager;

optimizer.initialize();

end

