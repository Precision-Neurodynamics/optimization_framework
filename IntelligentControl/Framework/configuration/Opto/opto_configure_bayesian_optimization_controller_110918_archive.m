function [optimization_object, stimulation_manager, metric_objects] = opto_configure_bayesian_optimization_controller( TD, DEBUG)

temp = datestr(now,2);
temp(strfind(temp,'/')) =[]; % Today date
animal_id                                   = 'EPI033';
result_dir                                  = ['results/' animal_id '/bayesian_optimization'];
experiment_name                             = 'Standard_50I';%'Train_opt_IISremove';%'IIS_test';'4-10Hz_fitmax_2param_Freq_PW_OF_area_delta_trial1';%'6-10Hz_max_2param_OF_delta_trial1';%'test_contoller_2';%
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

% stimulation_manager.stimulation_frequency   = 7;


% stimulation_manager.stimulation_pulse_width = 1.3; % 820 microsecond pulse-width
            
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

%
% Configure the metrics and objective function
%

% metric                                      = opto_spectral_power(stimulation_manager.sampling_frequency,[1:3 5:16], exp_directory);
% metric_objects      = {metric};
model_directory     = '';%'Framework\Signal_processing\objective_function_models\';
model_name          = '';%'ARN053_ADMETS_logistic_regression_model.mat';
recording_channels  = [1:16];%[1:16];%[2 4 6 8 9 11 13 15];
S_th = 10^-1*[0.3846    0.2653    0.3969    0.3254    0.3844    0.3070    0.3799    0.3003    0.3829    0.2974    0.3476    0.2873  0.3608    0.2945    0.3798    0.2739];
sampling_frequency  = stimulation_manager.sampling_frequency;
metric_band         = [4 10];
metric              = opto_model_state_5(sampling_frequency, recording_channels, metric_band,exp_directory, [model_directory model_name]);
metric_objects      = {metric};

%
% Configure surrogate model
%
gp_model                        = opto_gp_object();
gp_model.initialize_default(size(gp_model.lower_bound,2));
gp_model.acquisition_function = 'EI';
%
% Configure Bayesian optimization object
%
% model_file                                  = 'results/ARN053/bayesian_optimization/bayesian_optimization_admets_duration_amplitude-ARN053_20170330T115426/model.mat';
% gg = load(model_file);
optimization_object                         = opto_bayesian_optimization_controller_5();%opto_bayesian_optimization_controller_4_fixed();
optimization_object.objective_function      = metric; 
optimization_object.objective_type          = 'delta';
optimization_object.optimization_direction  = 'maximize';%'maximize';
optimization_object.S_th = S_th;

optimization_object.gp_model                = gp_model;
optimization_object.TD                      = TD;
optimization_object.device_name             = TD.GetDeviceName(0);
optimization_object.sampling_frequency      = TD.GetDeviceSF(optimization_object.device_name);

stimulation_manager.stimulation_type        = 'standard';%'train';%
optimization_object.stimulation_parameter   = {'pulse_frequency','pulse_width_pulse'};%{'pulse_frequency','train_frequency'};%
gp_model.lower_bound                        = [   2 1*10^-3];%[35 5];%
gp_model.upper_bound                        = [100 8*10^-3];%[100 11];% %EPI018 : 4.4, %EPI016 : 4.6, %EPI015 : 5 (based on commutator) EPI019 : 4.2
stimulation_manager.stimulation_amplitude   = 4.83; % EPI029 4.83 % EPI28 4.74
stimulation_manager.stimulation_pulse_width_pulse   = 4*10^-3;
stimulation_manager.stimulation_pulse_width_train   = 1;%75*10^-3;%
% stimulation_manager.frequency_train = 0;


optimization_object.n_parameters            = numel(optimization_object.stimulation_parameter);
optimization_object.lower_bound             = gp_model.lower_bound;
optimization_object.upper_bound             = gp_model.upper_bound;
optimization_object.logging_directory       = exp_directory;

optimization_object.stimulation_time_s      = 15;
stimulation_manager.stimulation_duration    = 3;
optimization_object.objective_window_s      = stimulation_manager.stimulation_duration;
optimization_object.evaluate_delay_s        = 0;
optimization_object.stimulator              = stimulation_manager;
optimization_object.O_Window = 2.4;

optimization_object.n_burn_in               =10; % = 10 originally
optimization_object.samples_per_cycle       =10;
% gp_model = load('C:\Users\TDT\Documents\IntelligentControl\results\EPI022\bayesian_optimization\Standard-EPI022_20180428T135217\gp_model.mat');
% gp_model = gp_model.gp_model;
% optimization_object.initialize(gp_model);
optimization_object.initialize();
end

