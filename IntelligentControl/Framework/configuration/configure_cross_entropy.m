function [optimization_object, stimulation_manager, metric_objects] = configure_cross_entropy(TD, DEBUG, animal_id)
%
% Configure logging
%
result_dir                                  = ['results/ARN' animal_id '/cross_entropy'];

experiment_name                             = 'cross_entropy_fad_rand_stim';
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

%
% Configure the stimulation_object
%
stimulation_manager                         = stimulator();
stimulation_manager.TD                      = TD;
stimulation_manager.device_name             = TD.GetDeviceName(0);
stimulation_manager.sampling_frequency      = TD.GetDeviceSF(stimulation_manager.device_name);
stimulation_manager.stimulation_channels    = [ 1 3 5 7 10 12 14 16];

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
% Configure the metrics and objective function
%
metric                                      = spectral_power(stimulation_manager.sampling_frequency,[2 4 6 8 9 11 13 15], exp_directory);
metric_objects                              = {metric};

%
% Configure the optimization object
%
optimization_object                           = cross_entropy_optimization();
optimization_object.TD                        = TD;
optimization_object.device_name               = TD.GetDeviceName(0);
optimization_object.sampling_frequency        = TD.GetDeviceSF(optimization_object.device_name);
optimization_object.objective_function        = metric; 
optimization_object.objective_window_s        = .5;
optimization_object.objective_type            = 'delta';
optimization_object.optimization_direction    = 'maximize';

% Sampling distribution
optimization_object.stimulation_parameter     = {'amplitude', 'frequency', 'duration'};
optimization_object.state_threshold           = 7.7e-8;
optimization_object.distribution              = 'gaussian';
optimization_object.learning_rate             = .8;
optimization_object.n_parameters              = numel(optimization_object.stimulation_parameter);
optimization_object.lower_bound               = [0 7   0];
optimization_object.upper_bound               = [1 300 7];
optimization_object.logging_directory         = exp_directory;

optimization_object.calibration_time_s        = 5;
optimization_object.stimulation_time_s        = 10;
optimization_object.evaluate_delay_s          = .5;
optimization_object.samples_per_cycle         = 50;
optimization_object.n_elite_samples           = 5;
optimization_object.stimulator                = stimulation_manager;

optimization_object.initialize();
end