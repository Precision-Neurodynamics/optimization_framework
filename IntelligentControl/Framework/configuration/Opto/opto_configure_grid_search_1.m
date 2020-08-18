function [optimizer, stimulation_manager, metric_objects, display_objects] = opto_configure_grid_search_1(TD, DEBUG)

%
% Configure logging
%
temp = datestr(now,2);
temp(strfind(temp,'/')) =[]; % Today date

animal_id                                   = 'ferrule';%'EPI024';
experiment_name                             = 'Compet';%'Grid Search';%'Competition_BO_6-10Hz_max';%'Seiz_C2';%'Seiz_C2';
video_name                                  = strcat('Z:\Sang_video\Seiz_',temp);

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
stimulation_manager                         = opto_stimulator();
stimulation_manager.TD                      = TD;
stimulation_manager.device_name             = TD.GetDeviceName(0);
stimulation_manager.sampling_frequency      = TD.GetDeviceSF(stimulation_manager.device_name);
stimulation_manager.stimulation_channels    = 10;

stimulation_manager.stimulation_type        = 'ferrule'; % Only for opto_grid_search_3
stimulation_manager.headstage_type          = 'ZC16-OB1';
stimulation_manager.electrode_location      = 'HPC';
stimulation_manager.logging_directory       = exp_directory;

stimulation_manager.tank_name               = strcat('C:\TDT\OpenEx\MyProjects\CustomStimActiveX_Opto\DataTanks\CustomStimActiveX_Opto_DT1_',temp);%'C:\TDT\OpenEx\Tanks\Data_Tank_2017_01_20';%'E:\ARN050\ARN050';%
% stimulation_manager.tank_name               = strcat('C:\TDT\OpenEx\MyProjects\Optical_Imaging_Sang\DataTanks\Optical_Imaging_Sang_DT1_',temp);%'C:\TDT\OpenEx\Tanks\Data_Tank_2017_01_20';%'E:\ARN050\ARN050';%

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
% display_objects = [];

%
% Configure the optimization object
%
optimizer = opto_grid_search_1();

% optimizer.objective_function        = metric; 
optimizer.TD                        = TD;
optimizer.n_samples                 = 1; %%% THIS LINE SAYS WHERE TO START THE STIMULATION
optimizer.video_filename = video_name;
% optimizer.objective_function      = metric_2;

% optimizer.stimulation_time_s        = 20; % Starting delay, [sec]
% optimizer.evaluate_delay_s          = 20; % Delay after stimulation finish, [sec]

% optimizer.stimulation_time_s        = 0;
% optimizer.evaluate_delay_s          = 0;

% Ferrule calibration
optimizer.stimulation_time_s        = 0; % Starting delay, [sec]
optimizer.evaluate_delay_s          = 0; % Delay after stimulation finish, [sec]
optimizer.frequency                 = [1]; %[35]; % %
optimizer.duration                  = [10];
optimizer.width                     = [999.9]; % ms
optimizer.amplitude                 = [5 4.5 4];
optimizer.n_repetitions             = 1;
optimizer.random_flag = 0;
optimizer.combvec_flag = 1;
optimizer.rep_flag = 1;

% Grid - EPI 022
% optimizer.stimulation_time_s        = 5; % Starting delay, [sec]
% optimizer.evaluate_delay_s          = 5; % Delay after stimulation finish, [sec]
% optimizer.frequency                 = [5.8 5.8]; %[7]; %
% optimizer.duration                  = [5 5];
% optimizer.width                     = [6.2 6.2]; % ms
% optimizer.amplitude                 = [5 0];
% optimizer.n_repetitions             = 40;
% optimizer.random_flag = 2; %0 for no random, %any integer for random seed
% optimizer.combvec_flag = 0; %0 for aligned, 1 for all combination
% optimizer.rep_flag = 0; %0 for grid, %1 for seizure experiment


% seizure
% optimizer.stimulation_time_s        = 10; % Starting delay, [sec]
% optimizer.evaluate_delay_s          = 10; % Delay after stimulation finish, [sec]
% optimizer.frequency                 = [3 7 11 13 17 35];%[11 12 13 14 15]; %[35]; % %
% optimizer.duration                  = [10];
% optimizer.width                     = [10]; % ms
% optimizer.amplitude                 = [1.2];%[4.1];
% optimizer.n_repetitions             = 3;
% optimizer.random_flag = 1;
% optimizer.combvec_flag = 1;
% optimizer.rep_flag = 1;

% optimizer.stimulation_time_s        = 20; % Starting delay, [sec]
% optimizer.evaluate_delay_s          = 50; % Delay after stimulation finish, [sec]
% optimizer.frequency                 = [10 2 55]; %[7]; %
% optimizer.duration                  = [20 20 20];
% optimizer.width                     = [10 10 10]; % ms
% optimizer.amplitude                 = [3 4.4 4.2118];
% optimizer.n_repetitions             = 10;

% % GRID
% optimizer.stimulation_time_s        = 8.4; % Starting delay, [sec]
% optimizer.evaluate_delay_s          = 8.4*2; % Delay after stimulation finish, [sec]
% optimizer.frequency                 = [2 7 12 17 22 27 32 37 45 55]; %[7]; %
% optimizer.duration                  = [8.4];
% optimizer.width                     = [2 5 8 10]; % ms
% % optimizer.amplitude                 = [4.6 4.3 4]; %EPI016 intensity
% optimizer.amplitude                 = [3.9 4.0 4.1 4.2]; %EPI019 intensity
% optimizer.n_repetitions             = 1;


%Short grid
% optimizer.stimulation_time_s        = 6; % Starting delay, [sec]
% optimizer.evaluate_delay_s          = 6; % Delay after stimulation finish, [sec]
% optimizer.frequency                 = [5 7 11 17 23 35 42]; %[7]; %
% optimizer.duration                  = [12];
% optimizer.width                     = [2 5 10]; % ms
% optimizer.amplitude                 = [4.6 4.3 4];
% optimizer.n_repetitions             = 10;


% optimizer.TD.SetTargetVal([stimulation_manager.device_name '.nPeriod'],stimulation_manager.sampling_frequency/optimizer.frequency);
% optimizer.TD.SetTargetVal([stimulation_manager.device_name '.nPulses'],optimizer.frequency * optimizer.duration);
% % optimizer.width                     = 2/stimulation_manager.sampling_frequency;
% optimizer.TD.SetTargetVal([stimulation_manager.device_name '.nDur-A'],stimulation_manager.sampling_frequency/1000*optimizer.width);
% optimizer.TD.SetTargetVal([stimulation_manager.device_name '.nDur-B'],5); % Useless
% optimizer.TD.SetTargetVal([stimulation_manager.device_name '.Amp-A'],optimizer.amplitude);


% optimizer.frequency                 = 300;
% optimizer.duration                  = 1;
% optimizer.amplitude                 = .5: .5:10;

% optimizer.stim_channels             = [1 3 5 7];
optimizer.stim_channels             = [10];
optimizer.logging_directory         = exp_directory;
optimizer.display_log_output        = 'simple';
optimizer.stimulator                = stimulation_manager;

optimizer.initialize();

end

