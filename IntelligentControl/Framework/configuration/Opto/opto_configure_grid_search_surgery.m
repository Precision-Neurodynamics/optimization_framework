function [optimizer, stimulation_manager, metric_objects, video_objects] = opto_configure_grid_search_surgery(TD, DEBUG)
temp = datestr(now,2);
temp(strfind(temp,'/')) =[]; % Today date

%
% Configure logging
%
animal_id                                   = 'EPI047';
experiment_name                             = '0mm';%'6p3mm_3p71';
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

% video_filename                              = 'Z:\Sang_video\test_opto_1.avi';

%
% Configure the stimulation_object
%
stimulation_manager                         = opto_stimulator_3();
stimulation_manager.stimulation_type        = 'standard';%'biphasic';%'calibration';%'standard';%'train';% % Only for opto_grid_search_3

stimulation_manager.TD                      = TD;
stimulation_manager.device_name             = TD.GetDeviceName(0);
stimulation_manager.sampling_frequency      = TD.GetDeviceSF(stimulation_manager.device_name);
stimulation_manager.stimulation_channels    = 10;

stimulation_manager.headstage_type          = 'ZC16-OB1';
stimulation_manager.electrode_location      = 'HPC';
stimulation_manager.logging_directory       = exp_directory;
stimulation_manager.tank_name               = strcat('C:\TDT\OpenEx\MyProjects\CustomStimActiveX_Opto\DataTanks\CustomStimActiveX_Opto_DT1_',temp);%'C:\TDT\OpenEx\Tanks\Data_Tank_2017_01_20';%'E:\ARN050\ARN050';%
% stimulation_manager.tank_name               = strcat('C:\TDT\OpenEx\MyProjects\OpenExProject9\DataTanks\Op9_DT1_',temp);%'C:\TDT\OpenEx\Tanks\Data_Tank_2017_01_20';%'E:\ARN050\ARN050';%

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
% metric_2        = bipolar(stimulation_manager.sampling_frequency,[2 4], exp_directory);
% metric_objects  = {metric_1, metric_2};
metric_objects  = {metric_1};

%
% Configure the optimization object
%
optimizer = opto_grid_search_3();
optimizer.TD                        = TD;

optimizer.n_samples                 = 1; %%% THIS LINE SAYS WHERE TO START THE STIMULATION
optimizer.stimulation_time_s        = 10; % Starting delay, [sec]
optimizer.evaluate_delay_s          = 20; % Delay after stimulation finish, [sec]
optimizer.frequency_pulse           = [17];%      = [50 100];%[11 12 13 14 15]; %[35]; % %
optimizer.frequency_train           = [0];%      = [5 7 11];
optimizer.duration                  = [10];
optimizer.width_pulse               = [5]*10^-3;%[0.2]*10^-3;%    = [2 4].*0.001; % ms
optimizer.width_train               =  [1];%    = [25 50 75].*0.001; % ms
optimizer.amplitude                 = [4.6];%[4.6];
optimizer.n_repetitions             = 1;
optimizer.random_flag = 1;
optimizer.combvec_flag = 0;
optimizer.rep_flag = 0;

optimizer.stim_channels             = [10];
optimizer.n_repetitions             = 1;
optimizer.logging_directory         = exp_directory;
optimizer.display_log_output        = 'simple';
optimizer.stimulator                = stimulation_manager;

optimizer.initialize();

end

