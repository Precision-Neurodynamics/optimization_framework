function [optimization_object, stimulation_manager, metric_objects] = opto_configure_bayesian_optimization_controller2( TD, DEBUG)

temp = datestr(now,2);
temp(strfind(temp,'/')) =[]; % Today date
animal_id                                   = 'EPI047';
result_dir                                  = ['results/' animal_id '/bayesian_optimization'];
experiment_name                             = 'Gamma2000';%'PiSM';%'Train_opt_IISremove';%'IIS_test';'4-10Hz_fitmax_2param_Freq_PW_OF_area_delta_trial1';%'6-10Hz_max_2param_OF_delta_trial1';%'test_contoller_2';%
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
% Parameter definition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
model_directory     = 'C:\Users\TDT\Documents\IntelligentControl\Sang_optim_code\'; %Only for PriSM optimization
model_name          = 'PiSM_071119'; %Only for PriSM optimization
recording_channels  = [1:1:12 14:1:16];
sampling_frequency  = stimulation_manager.sampling_frequency;
metric_type         = 'PSD'; %1.PSD, 2.PiSM 3.EGM (PSD for theta and gamma)
stimulation_manager.stimulation_type        = 'standard';% 'train';%'train';%
metric_def          = [33 50]; %1.band for PSD
metric              = opto_model_state(sampling_frequency, recording_channels, metric_def, metric_type, [model_directory model_name]);
metric_objects      = {metric};
delta_or_raw        = 'target';%'complex';%'delta';
maxormin            = 'minimize';
if strcmp(delta_or_raw,'target') == 1
    target_metric = 1.6807e-10 *20;%% %%%%%%%%%%%%%%%%%%%%% 
else
    target_metric = NaN;%%
end

IIS_remove_flag = 0; %1 for IIS remove, 0 for not

params = load('C:\Users\TDT\Documents\IntelligentControl\results\EPI044\Baseline-EPI044_20190920T151214\Sth_stats.mat'); %Only for epileptic rats
save([exp_directory,'\Sth_stats.mat'],'params');
if IIS_remove_flag == 1
    metric_objects{1}.IIS_remove_flag = 1; 
    metric_objects{1}.S_th = params.S_th;
end
if strcmp(metric_type,'PiSM')
    metric_objects{1}.NM = params.stats;
end
stimulation_manager.stimulation_amplitude   = 5; %EPI043 473 % EPI042 4.63 % EPI039 4.92 % EPI40 4.88 % EPI044 5
if strcmp(stimulation_manager.stimulation_type,'standard')
    lower_bound         = [4.01   5 2*10^-3];%[35 5];%
    upper_bound         = [4.84 42 10*10^-3];%[100 11];%
    stimulation_manager.stimulation_pulse_width_pulse   = 0;%4*10^-3;%
    stimulation_manager.stimulation_pulse_width_train   = 1;%75*10^-3;%
    optimparam = {'amplitude','pulse_frequency','pulse_width_pulse'};%{'pulse_frequency','train_frequency'};%
elseif strcmp(stimulation_manager.stimulation_type,'train')
    lower_bound         = [35 5];%[   2 1*10^-3];%
    upper_bound         = [100 11];%[100 8*10^-3];%
    stimulation_manager.stimulation_pulse_width_pulse   = 4*10^-3;%0;%
    stimulation_manager.stimulation_pulse_width_train   = 75*10^-3;%1;%
    optimparam = {'pulse_frequency','train_frequency'};%{'pulse_frequency','pulse_width_pulse'};%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%
gp_model                        = opto_gp_object();
gp_model.lower_bound            = lower_bound;%[35 5];%[4.01 5 2];
gp_model.upper_bound            = upper_bound;%[100 11];%[4.83 42 10]; %EPI018 : 4.4, %EPI016 : 4.6, %EPI015 : 5 (based on commutator) EPI019 : 4.2
gp_model.initialize_default(size(gp_model.lower_bound,2));
gp_model.acquisition_function = 'UCB';
%
% Configure Bayesian optimization object
%
% model_file                                  = 'results/ARN053/bayesian_optimization/bayesian_optimization_admets_duration_amplitude-ARN053_20170330T115426/model.mat';
% gg = load(model_file);
optimization_object                         = opto_bayesian_optimization_controller();%opto_bayesian_optimization_controller_4_fixed();
optimization_object.objective_function      = metric; 
optimization_object.objective_type          = delta_or_raw;
optimization_object.target_metric           = target_metric;
optimization_object.optimization_direction  = maxormin;%'maximize';

optimization_object.gp_model                = gp_model;
optimization_object.TD                      = TD;
optimization_object.device_name             = TD.GetDeviceName(0);
optimization_object.sampling_frequency      = TD.GetDeviceSF(optimization_object.device_name);
optimization_object.stimulation_parameter   = optimparam;%{'pulse_frequency','train_frequency'};%


optimization_object.n_parameters            = numel(optimization_object.stimulation_parameter);
optimization_object.lower_bound             = gp_model.lower_bound;
optimization_object.upper_bound             = gp_model.upper_bound;
optimization_object.logging_directory       = exp_directory;


%%%%%%%%%%%%%%%%%%%%%%%%%%%

optimization_object.stimulation_time_s      = 5;
stimulation_manager.stimulation_duration    = 5;
optimization_object.objective_window_s      = stimulation_manager.stimulation_duration;
optimization_object.evaluate_delay_s        = 20;
optimization_object.stimulator              = stimulation_manager;

optimization_object.n_burn_in               =10; % = 10 originally

% gp_folder = 'C:\Users\TDT\Documents\IntelligentControl\results\EPI047\bayesian_optimization\Gamma2000-EPI047_20191112T171315\';
% gp_model = load([gp_folder,'\gp_model.mat']);
% user_define_length = 23;
% gp_model = gp_model.gp_temp;
% gp_model.x_data = gp_model.x_data(1:user_define_length,:);
% gp_model.y_data = gp_model.y_data(1:user_define_length,:);
% optimization_object.initialize(gp_model);

optimization_object.initialize();
end

