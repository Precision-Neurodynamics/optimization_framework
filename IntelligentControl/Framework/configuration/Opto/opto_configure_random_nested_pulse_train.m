function [optimization_object, stimulation_manager, metric_objects] = opto_configure_random_nested_pulse_train( TD, DEBUG)

temp = datestr(now,2);
temp(strfind(temp,'/')) =[]; % Today date
animal_id                                   = 'ARN084';
result_dir                                  = ['results/' animal_id '/bayesian_optimization'];
experiment_name                             = 'random_nested_pulse_train';
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
            
stimulation_manager.headstage_type          = 'ZC16-OB1-16CH';
stimulation_manager.electrode_location      = 'R_HPC';
stimulation_manager.logging_directory       = exp_directory;
stimulation_manager.tank_name               = strcat('C:\TDT\OpenEx\MyProjects\CustomStimActiveX_Opto\DataTanks\CustomStimActiveX_Opto_DT1_',temp);
stimulation_manager.block_name              = get_block_name(stimulation_manager.tank_name);

stimulation_manager.animal_id               = animal_id;
stimulation_manager.experiment_name         = experiment_name;
stimulation_manager.experiment_start_time   = posixtime(datetime('now'));
stimulation_manager.display_log_output      = 0;
stimulation_manager.initialize();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parameter definition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
model_directory     = ''; %Only for PriSM optimization
model_name          = ''; %Only for PriSM optimization

recording_channels  = [1:1:12 14:1:16]; % Channel 13 is broken on headstage
sampling_frequency                      = stimulation_manager.sampling_frequency;
metric_type                             = 'PSD';
stimulation_manager.stimulation_type  	= 'train';
metric_def                              = [33 50];
metric                                  = opto_model_state(sampling_frequency, recording_channels, metric_def, metric_type, [model_directory model_name]);
metric_objects                          = {metric};
delta_or_raw                            = 'raw';
max_or_min                              = 'maximize';

target_metric       = NaN;%%

lower_bound         = [4.01        35                 5                  2/1000        20/1000];
upper_bound         = [4.84        100                12                 10/1000       80/1000];
optim_param         = {'amplitude','pulse_frequency', 'train_frequency','pulse_width', 'train_width'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

gp_model                        = opto_gp_object();
gp_model.lower_bound            = lower_bound;
gp_model.upper_bound            = upper_bound;
gp_model.initialize_default(size(gp_model.lower_bound,2));
gp_model.acquisition_function = 'UCB';

%
% Configure Bayesian optimization object
%
optimization_object                         = opto_bayesian_optimization_controller();
optimization_object.objective_function      = metric; 
optimization_object.objective_type          = delta_or_raw;
optimization_object.target_metric           = target_metric;
optimization_object.optimization_direction  = max_or_min;

optimization_object.gp_model                = gp_model;
optimization_object.TD                      = TD;
optimization_object.device_name             = TD.GetDeviceName(0);
optimization_object.sampling_frequency      = TD.GetDeviceSF(optimization_object.device_name);
optimization_object.stimulation_parameter   = optim_param;


optimization_object.n_parameters            = numel(optimization_object.stimulation_parameter);
optimization_object.lower_bound             = gp_model.lower_bound;
optimization_object.upper_bound             = gp_model.upper_bound;
optimization_object.logging_directory       = exp_directory;


%%%%%%%%%%%%%%%%%%%%%%%%%%%

optimization_object.stimulation_time_s      = 5;
stimulation_manager.stimulation_duration    = 5;
optimization_object.objective_window_s      = stimulation_manager.stimulation_duration;
optimization_object.evaluate_delay_s        = 10;
optimization_object.stimulator              = stimulation_manager;

optimization_object.n_burn_in               = 10; 

optimization_object.initialize();
end

