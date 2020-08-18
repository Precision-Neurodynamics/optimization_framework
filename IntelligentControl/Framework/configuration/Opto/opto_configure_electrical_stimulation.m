function [optimization_object, stimulation_manager, metric_objects] = opto_configure_bayesian_optimization_controller( TD, DEBUG)

temp = datestr(now,2);
temp(strfind(temp,'/')) =[]; % Today date
animal_id                                   = 'RAT83';
result_dir                                  = ['results/' animal_id '/bayesian_optimization'];
experiment_name                             = 'CTZ-pos';%'PiSM';%'Train_opt_IISremove';%'IIS_test';'4-10Hz_fitmax_2param_Freq_PW_OF_area_delta_trial1';%'6-10Hz_max_2param_OF_delta_trial1';%'test_contoller_2';%
if strcmp(animal_id, '') ||  strcmp(experiment_name, '')
    [animal_id, experiment_name]                = get_experiment_info(DEBUG);    
end

if DEBUG
    experiment_name = [experiment_name 'DEBUG'];
end

time_str                                    = datestr(now, 30);
log_pattern                                 = [result_dir '/' experiment_name '-%s_%s'];
exp_directory                               = sprintf(log_pattern, animal_id, time_str);
mkdir(exp_directory);
% opto
%
% Configure the stimulation_object
%
stimulation_manager                         = opto_stimulator_3();
stimulation_manager.TD                      = TD;
stimulation_manager.device_name             = TD.GetDeviceName(0);
stimulation_manager.sampling_frequency      = TD.GetDeviceSF(stimulation_manager.device_name);
stimulation_manager.stimulation_channels    = [10];
            
stimulation_manager.headstage_type          = 'ZC16-OB1-Ch32';%'RA16Z_CH';%
stimulation_manager.electrode_location      = 'R_HPC';
stimulation_manager.logging_directory       = exp_directory;
stimulation_manager.tank_name               = strcat('C:\TDT\OpenEx\MyProjects\CustomStimActiveX_Opto\DataTanks\CustomStimActiveX_Opto_DT1_',temp);%'C:\TDT\OpenEx\Tanks\Data_Tank_2017_01_20';%'E:\ARN050\ARN050';%
stimulation_manager.block_name              = get_block_name(stimulation_manager.tank_name);

stimulation_manager.animal_id               = animal_id;
stimulation_manager.experiment_name         = experiment_name;
stimulation_manager.experiment_start_time   = posixtime(datetime('now'));
stimulation_manager.display_log_output      = 0;
stimulation_manager.initialize();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% model_directory     = 'C:\Users\TDT\Documents\IntelligentControl\Sang_optim_code\';
% model_name          = 'PiSM_071119';
recording_channels  = [1:16];%[1:16];%[2 4 6 8 9 11 13 15];
sampling_frequency  = stimulation_manager.sampling_frequency;
% metric_type         = 'PSD'; %1.PSD, 2.PiSM 3.EGM
stimulation_manager.stimulation_type        = 'biphasic';% 'train';%'train';%
% metric_def          = [4 10]; %1.band for PSD,
stimulation_frequency = 10;
stimulation_length = 5;
metric_channel = 9;
metric              = opto_evoked_potential(sampling_frequency, recording_channels, stimulation_frequency, stimulation_length,metric_channel);
metric_objects      = {metric};
% deltaorraw          = 'delta';%'complex';%'delta';
% maxormin            = 'maximize';

% IIS_remove_flag = 1; %1 for IIS remove, 0 for not

% params = load('C:\Users\TDT\Documents\IntelligentControl\results\EPI045\Baseline-EPI045_20191007T150626\Sth_stats.mat');
% save([exp_directory,'\Sth_stats.mat'],'params');
% if IIS_remove_flag == 1
%     metric_objects{1}.IIS_remove_flag = 1; 
%     metric_objects{1}.S_th = params.S_th;
% end
% if strcmp(metric_type,'PiSM')
%     metric_objects{1}.NM = params.stats;
% end

stimulation_manager.stimulation_amplitude   = 3; %EPI043 473 % EPI042 4.63 % EPI039 4.92 % EPI40 4.88 % EPI044 5
% stimulation_manager.stimulation_time_s        = 0; % Starting delay, [sec]
% stimulation_manager.evaluate_delay_s          = 0; % Delay after stimulation finish, [sec]
stimulation_manager.stimulation_frequency_pulse           = stimulation_frequency;%      = [50 100];%[11 12 13 14 15]; %[35]; % %
% stimulation_manager.duration                  = stimulation_length;
stimulation_manager.stimulation_pulse_width_pulse               = 0.1*10^-3;%    = [2 4].*0.001; % ms
%  optimizer.n_repetitions             =60;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


optimization_object                         = opto_electrical_stimulation();%opto_bayesian_optimization_controller_4_fixed();
optimization_object.objective_function      = metric; 
% optimization_object.objective_type          = deltaorraw;
% optimization_object.optimization_direction  = maxormin;%'maximize';

% optimization_object.gp_model                = gp_model;
optimization_object.TD                      = TD;
optimization_object.device_name             = TD.GetDeviceName(0);
optimization_object.sampling_frequency      = TD.GetDeviceSF(optimization_object.device_name);
% optimization_object.stimulation_parameter   = optimparam;%{'pulse_frequency','train_frequency'};%


optimization_object.logging_directory       = exp_directory;


%%%%%%%%%%%%%%%%%%%%%%%%%%%

optimization_object.stimulation_time_s      = 0;
stimulation_manager.stimulation_duration    = stimulation_length;
optimization_object.objective_window_s      = stimulation_manager.stimulation_duration;
optimization_object.evaluate_delay_s        = 15;
optimization_object.stimulator              = stimulation_manager;

% optimization_object.n_burn_in               =10; % = 10 originally

optimization_object.initialize();
end

