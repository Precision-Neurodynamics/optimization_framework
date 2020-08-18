function [ optimization_object, stimulation_manager, metric_objects ] = configure_bayesian_optimization( TD, DEBUG )

result_dir                                  = 'results/ARN048/bayesian_stim';
animal_id                                   = '048';
experiment_name                             = 'bayesian_fa_maximize_delta_power';
if strcmp(animal_id, '') ||  strcmp(experiment_name, '')
    [animal_id, experiment_name]                = get_experiment_info(DEBUG);    
end

if DEBUG
    experiment_name = [experiment_name 'DEBUG'];
end

time_str                                    = datestr(now, 30);
log_pattern                                 = [result_dir '/' experiment_name '-ARN%s_%s'];
exp_directory                               = sprintf(log_pattern, animal_id, time_str);
mkdir(exp_directory);

optimization_object                     = bayesian_optimization();

%
% Configure the stimulation_object
%
stimulation_manager                         = stimulator();
stimulation_manager.TD                      = TD;
stimulation_manager.device_name             = TD.GetDeviceName(0);
stimulation_manager.sampling_frequency      = TD.GetDeviceSF(stimulation_manager.device_name);
stimulation_manager.stimulation_channels    = [ 1 3 5 7];

stimulation_manager.stimulation_frequency   = 200;
stimulation_manager.stimulation_duration    = 1;
stimulation_manager.stimulation_amplitude   = 1.16;
stimulation_manager.stimulation_pulse_width = 2/stimulation_manager.sampling_frequency; % 81 microsecond pulse-width
            
stimulation_manager.stimulation_type        = 'synchronous';
stimulation_manager.headstage_type          = 'RA16Z_CH';
stimulation_manager.electrode_location      = 'R_HPC';
stimulation_manager.logging_directory       = exp_directory;
stimulation_manager.tank_name               = 'Data_Tank_2016_11_09';
stimulation_manager.block_name              = get_block_name(stimulation_manager.tank_name);

stimulation_manager.animal_id               = animal_id;
stimulation_manager.experiment_name         = experiment_name;
stimulation_manager.experiment_start_time   = posixtime(datetime('now'));
stimulation_manager.display_log_output      = 0;
stimulation_manager.initialize();



%
% Objective function
%
metric                                  = spectral_power(stimulation_manager.sampling_frequency,[11 9 15 13], exp_directory);
metric_objects                          = {metric};

%
% Optimizer model
%
gp_model                                = gp_object();
gp_model.lower_bound                    = [0 0];
gp_model.upper_bound                    = [5 300];

gp_model.initialize_default(2);

%
% Configure optimizer
%
optimization_object.gp_model            = gp_model;
optimization_object.TD                  = TD;
optimization_object.device_name         = TD.GetDeviceName(0);
optimization_object.sampling_frequency  = TD.GetDeviceSF(optimization_object.device_name);

optimization_object.control_time        = 20;
optimization_object.lower_bound         = gp_model.lower_bound;
optimization_object.upper_bound         = gp_model.upper_bound;
% optimization_object.x0                  = [5 5];
optimization_object.n_burn_in           = 3;
optimization_object.initialize();
end

