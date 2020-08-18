function [optimizer, stimulation_manager, metric_objects, display_objects] = opto_configure_grid_search_3(TD, DEBUG)

%
% Configure logging
%
temp = datestr(now,2);
temp(strfind(temp,'/')) =[]; % Today date

animal_id                                   = 'ARN084';
experiment_name                             = 'Compet';%'Baseline';%'Implant';%'Theta-stim';%'Compet-Theta-train-delta';%'Compet-standard';%'Compet-PiSM';%'Shortgrid-baseline';'Compet_standard';%'Grid_Search';%'Compet_train';%'Test1120_Grid';%'Competition_BO_6-10Hz_max';%'Seiz_C2';%'Seiz_C2';
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
cd('C:\Users\Zarif Rahman\Documents\CodeBaseDev\IntelligentControl');
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

stimulation_manager.stimulation_type        = 'standard';%'calibration';%'standard';%'train';% % Only for opto_grid_search_3
stimulation_manager.headstage_type          = 'ZC16-OB1';
stimulation_manager.electrode_location      = 'HPC';
stimulation_manager.logging_directory       = exp_directory;


stimulation_manager.tank_name               = strcat('C:\TDT\OpenEx\MyProjects\CustomStimActiveX_Opto\DataTanks\CustomStimActiveX_Opto_DT1_',temp);%'C:\TDT\OpenEx\Tanks\Data_Tank_2017_01_20';%'E:\ARN050\ARN050';%
%%stimulation_manager.block_name              = get_block_name_opto(stimulation_manager.tank_name);
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


% Seiz - train
% stimulation_manager.stimulation_type        = 'train';%'calibration';%'standard';%'train';% % Only for opto_grid_search_3
% optimizer.stimulation_time_s        = 0; % Starting delay, [sec]
% optimizer.evaluate_delay_s          = 0; % Delay after stimulation finish, [sec]
% optimizer.frequency_pulse           = [92];%      = [50 100];%[11 12 13 14 15]; %[35]; % %
% optimizer.frequency_train           = [7.4];%      = [5 7 11];
% optimizer.duration                  = [60];
% optimizer.width_pulse               =  [4*10^-3];%    = [2 4].*0.001; % ms
% optimizer.width_train               =  [75*10^-3];%    = [25 50 75].*0.001; % ms
% optimizer.amplitude                 = [5];%[4.1];
% optimizer.n_repetitions             =60;
% optimizer.random_flag = 0;
% optimizer.combvec_flag = 1;
% optimizer.rep_flag = 1;

% Baseline
%  optimizer.stimulation_time_s        = 0; % Starting delay, [sec]
%  optimizer.evaluate_delay_s          = 0; % Delay after stimulation finish, [sec]
%  optimizer.frequency_pulse           = [7];%      = [50 100];%[11 12 13 14 15]; %[35]; % %
%  optimizer.frequency_train           = [0];%      = [5 7 11];
%  optimizer.duration                  = [60];
%  optimizer.width_pulse               =  [10*10^-3];%    = [2 4].*0.001; % ms
%  optimizer.width_train               =  [1];%    = [25 50 75].*0.001; % ms
%  optimizer.amplitude                 = [0];%[4.63];4.73:EPI043
%  optimizer.n_repetitions             =10;
%  optimizer.random_flag = 0;
%  optimizer.combvec_flag = 1;
%  optimizer.rep_flag = 1;

% Seiz - standard
% optimizer.stimulation_time_s        = 0; % Starting delay, [sec]
% optimizer.evaluate_delay_s          = 0; % Delay after stimulation finish, [sec]
% optimizer.frequency_pulse           = [7];%      = [50 100];%[11 12 13 14 15]; %[35]; % %
% optimizer.frequency_train           = [0];%      = [5 7 11];
% optimizer.duration                  = [3];
% optimizer.width_pulse               =  [10*10^-3];%    = [2 4].*0.001; % ms
% optimizer.width_train               =  [1];%    = [25 50 75].*0.001; % ms
% optimizer.amplitude                 = [4.63];%EPI042 4.63 // 4.73:EPI043
% optimizer.n_repetitions             = 60;
% optimizer.random_flag = 0;
% optimizer.combvec_flag = 1;
% optimizer.rep_flag = 1;

%Compet-train
% stimulation_manager.stimulation_type        = 'train';%'calibration';%'standard';%'train';% % Only for opto_grid_search_3
% optimizer.stimulation_time_s        = 8; % Starting delay, [sec]
% optimizer.evaluate_delay_s          = 8; % Delay after stimulation finish, [sec]
% optimizer.frequency_pulse           = [65.9 67.2 65.9];%      = [50 100];%[11 12 13 14 15]; %[35]; % %
% optimizer.frequency_train           = [7.7 5.2 7.7];%      = [5 7 11];
% optimizer.duration                  = [8 8 8];
% optimizer.width_pulse               =  [4 4 4]*10^-3;%    = [2 4].*0.001; % ms
% optimizer.width_train               =  [75 75 75]*10^-3;%    = [25 50 75].*0.001; % ms
% optimizer.amplitude                 = [5 5 0];%
% optimizer.n_repetitions             = 30;
% optimizer.random_flag = 1;
% optimizer.combvec_flag = 0;
% optimizer.rep_flag = 0;

% Compet-standard
optimizer.stimulation_time_s        = 3; % Starting delay, [sec]
optimizer.evaluate_delay_s          = 3; % Delay after stimulation finish, [sec]
optimizer.frequency_pulse           = [15];%      = [50 100];%[11 12 13 14 15]; %[35]; % %
optimizer.frequency_train           = [0 0 0];%      = [5 7 11];
optimizer.duration                  = [20];
optimizer.width_pulse               = [7.5]*10^-3;%    = [2 4].*0.001; % ms
optimizer.width_train               =  [0 0 0];%    = [25 50 75].*0.001; % ms
optimizer.amplitude                 = [4.8208];%
optimizer.n_repetitions             = 10;
optimizer.random_flag = 1;
optimizer.combvec_flag = 0;
optimizer.rep_flag = 1;





% Standard-sequence
% optimizer.stimulation_time_s        = 20; % Starting delay, [sec]
% optimizer.evaluate_delay_s          = 20; % Delay after stimulation finish, [sec]
% optimizer.frequency_pulse           = [5 7 11 17 23 29 35 42];%      = [50 100];%[11 12 13 14 15]; %[35]; % %
% optimizer.frequency_train           = [0];%      = [5 7 11];
% optimizer.duration                  = [20];
% optimizer.width_pulse               =  [4*10^-3];%    = [2 4].*0.001; % ms
% optimizer.width_train               =  [1];%    = [25 50 75].*0.001; % ms
% optimizer.amplitude                 = [0 4.01 4.22 4.42 4.63 4.83];%[4.1];
% optimizer.N_seg                     = 5;
% optimizer.sequence                  = 1;
% optimizer.n_repetitions             = 120;
% optimizer.random_flag = 0;
% optimizer.combvec_flag = 1;
% optimizer.rep_flag = 1;

% optimizer.stimulation_time_s        = 8; % Starting delay, [sec]
% optimizer.evaluate_delay_s          = 8; % Delay after stimulation finish, [sec]
% optimizer.frequency_pulse           = [5 11 23 35 42 57 69 81];%      = [50 100];%[11 12 13 14 15]; %[35]; % %
% optimizer.frequency_train           = [0];%      = [5 7 11];
% optimizer.duration                  = [8];
% optimizer.width_pulse               =  [2 5 10]*10^-3;%    = [2 4].*0.001; % ms
% optimizer.width_train               =  [1];%    = [25 50 75].*0.001; % ms
% optimizer.amplitude                 = [5];%[4.6];
% optimizer.n_repetitions             = 8;
% optimizer.random_flag = 2;
% optimizer.combvec_flag = 1;
% optimizer.rep_flag = 0;



% Calibration - set the stimulationtype to 'calibration'
% optimizer.stimulation_time_s        = 0; % Starting delay, [sec]
% optimizer.evaluate_delay_s          = 0; % Delay after stimulation finish, [sec]
% optimizer.frequency_pulse           = [37.9 9.85 37.9];%      = [50 100];%[11 12 13 14 15]; %[35]; % %
% optimizer.frequency_train           = [0 0 0];%      = [5 7 11];
% optimizer.duration                  = [15 15 15];
% optimizer.width_pulse               =  [3.5*10^-3 7.1*10^-3 3.5*10^-3];%    = [2 4].*0.001; % ms
% optimizer.width_train               =  [1 1 1];%    = [25 50 75].*0.001; % ms
% optimizer.amplitude                 = [5 4.5 4];%[4.6];
% optimizer.n_repetitions             = 1;
% optimizer.random_flag = 0;
% optimizer.combvec_flag = 0;
% optimizer.rep_flag = 0;


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

