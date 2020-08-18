function [optimizer, stimulation_manager, metric_objects] = opto_configure_grid_search_video(TD, DEBUG)

%
% Configure logging
%
animal_id                                   = 'EPI015';
experiment_name                             = 'Stim_shortGrid';
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

video_filename                              = 'Z:\Sang_video\test_opto_0427_1.avi';

%
% Configure the stimulation_object
%
stimulation_manager                         = opto_stimulator();
stimulation_manager.TD                      = TD;
stimulation_manager.device_name             = TD.GetDeviceName(0);
stimulation_manager.sampling_frequency      = TD.GetDeviceSF(stimulation_manager.device_name);
stimulation_manager.stimulation_channels    = 10;

stimulation_manager.headstage_type          = 'ZC16-OB1';
stimulation_manager.electrode_location      = 'HPC';
stimulation_manager.logging_directory       = exp_directory;
stimulation_manager.tank_name               = 'C:\TDT\OpenEx\MyProjects\CustomStimActiveX_Opto\DataTanks\CustomStimActiveX_Opto_DT1_042717';%'C:\TDT\OpenEx\Tanks\Data_Tank_2017_01_20';%'E:\ARN050\ARN050';%
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
% metric_2        = bipolar(stimulation_manager.sampling_frequency,[2 4], exp_directory);
% metric_objects  = {metric_1, metric_2};
metric_objects  = {metric_1};
% Video
% video        = opto_video_recording(video_filename); 
% video_objects = {video};

%
% Configure the optimization object
%
optimizer = opto_grid_search_1();
optimizer.TD                        = TD;

% optimizer.stimulation_time_s        = 20; % Starting delay, [sec]
% optimizer.evaluate_delay_s          = 20; % Delay after stimulation finish, [sec]

% optimizer.stimulation_time_s        = 0;
% optimizer.evaluate_delay_s          = 0;

optimizer.n_samples                 = 1; %%% THIS LINE SAYS WHERE TO START THE STIMULATION


% optimizer.stimulation_time_s        = 20; % Starting delay, [sec]
% optimizer.evaluate_delay_s          = 20; % Delay after stimulation finish, [sec]
% optimizer.frequency                 = [5 7 11 17 23 35 42]; %[7]; %
% optimizer.duration                  = [20];
% optimizer.width                     = [2 5 10]; % ms
% optimizer.amplitude                 = [5 4.5 4.1];
% optimizer.n_repetitions             = 1;


% Short grid
optimizer.stimulation_time_s        = 2; % Starting delay, [sec]
optimizer.evaluate_delay_s          = 2; % Delay after stimulation finish, [sec]
optimizer.frequency                 = [5 7 11 17 23 35 42]; %[7]; %
optimizer.duration                  = [2];
optimizer.width                     = [2 5 10]; % ms
optimizer.amplitude                 = [5 4.5 4.1];
optimizer.n_repetitions             = 10;


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

