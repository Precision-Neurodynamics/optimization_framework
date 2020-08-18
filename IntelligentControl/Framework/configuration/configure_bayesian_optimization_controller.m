function [optimization_object, stimulation_manager, metric_objects] = configure_bayesian_optimization_controller( TD, DEBUG, animal_id )

result_dir                                  = ['results/' animal_id '/bayesian_optimization'];
experiment_name                             = 'random_search_admets_amplitude-duration-frequency';
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

%
% Configure the stimulation_object
%
stimulation_manager                         = open_stimulator();
stimulation_manager.TD                      = TD;
stimulation_manager.device_name             = TD.GetDeviceName(0);
stimulation_manager.sampling_frequency      = TD.GetDeviceSF(stimulation_manager.device_name);
stimulation_manager.stimulation_channels    = [ 1 3 5 7 10 12 14 16];

stimulation_manager.stimulation_frequency   = 7;
stimulation_manager.stimulation_duration    = 120;
stimulation_manager.stimulation_amplitude   = 1.16;
stimulation_manager.stimulation_pulse_width = 10/stimulation_manager.sampling_frequency; % 820 microsecond pulse-width
            
stimulation_manager.stimulation_type        = 'synchronous';
stimulation_manager.headstage_type          = 'RA16Z_CH';
stimulation_manager.electrode_location      = 'R_HPC';
stimulation_manager.logging_directory       = exp_directory;
stimulation_manager.tank_name               = 'CustomStimActiveX_DT1_073018';
stimulation_manager.block_name              = get_block_name(stimulation_manager.tank_name);

stimulation_manager.animal_id               = animal_id;
stimulation_manager.experiment_name         = experiment_name;
stimulation_manager.experiment_start_time   = posixtime(datetime('now'));
stimulation_manager.display_log_output      = 0;
stimulation_manager.initialize();

%
% Configure the metrics and objective function
%
model_directory     = 'Framework\Signal_processing\objective_function_models\';
model_name          = 'ARN053_ADMETS_logistic_regression_model.mat';
recording_channels  = [2 4 6 8 9 11 13 15];
sampling_frequency  = stimulation_manager.sampling_frequency;
metric              = model_state(sampling_frequency, recording_channels, exp_directory, [model_directory model_name]);
metric_objects      = {metric};

%
% Configure surrogate model
%
gp_model                        = gp_object();
% gp_model.lower_bound            = [1 15 4];
% gp_model.upper_bound            = [4 120 10];
gp_model.lower_bound            = [0 .1 3];
gp_model.upper_bound            = [6 10 11];
gp_model.initialize_default(2);

%
% Configure Bayesian optimization object
%
% model_file                                  = 'results/ARN053/bayesian_optimization/bayesian_optimization_admets_duration_amplitude-ARN053_20170330T115426/model.mat';
% gg = load(model_file);
optimization_object                         = bayesian_optimization_controller();
optimization_object.objective_function      = metric; 
optimization_object.objective_window_s      = 1;
optimization_object.objective_type          = 'delta';
optimization_object.optimization_direction  = 'maximize';

optimization_object.gp_model                = gp_model;
optimization_object.TD                      = TD;
optimization_object.device_name             = TD.GetDeviceName(0);
optimization_object.sampling_frequency      = TD.GetDeviceSF(optimization_object.device_name);

 optimization_object.stimulation_parameter   = {'amplitude', 'duration', 'frequency'};
% optimization_object.stimulation_parameter   = {'amplitude', 'duration'};

optimization_object.n_parameters            = numel(optimization_object.stimulation_parameter);
% optimization_object.lower_bound             = [1 15 4];
% optimization_object.upper_bound             = [4 120 10];

optimization_object.lower_bound             = [0 .1  3];
optimization_object.upper_bound             = [6 10 11];

optimization_object.logging_directory       = exp_directory;

% optimization_object.stimulation_time_s      = 275;
optimization_object.stimulation_time_s      = 10;
optimization_object.evaluate_delay_s        = optimization_object.objective_window_s + 1;
optimization_object.stimulator              = stimulation_manager;

optimization_object.n_burn_in               = 250;
optimization_object.initialize();
end

