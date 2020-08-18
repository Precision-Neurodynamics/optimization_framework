function [optimization_object, stimulation_manager, metric_objects] = opto_configure_cross_entropy(TD, DEBUG)
%
% Configure logging
%
animal_id                                   = 'EPI016';
result_dir                                  = ['results/' animal_id];
experiment_name                             = '6-10Hz_min_2param_exp';
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
stimulation_manager                         = opto_stimulator();
stimulation_manager.TD                      = TD;
stimulation_manager.device_name             = TD.GetDeviceName(0);
stimulation_manager.sampling_frequency      = TD.GetDeviceSF(stimulation_manager.device_name);
stimulation_manager.stimulation_channels    = [10];

stimulation_manager.stimulation_frequency   = 35;
stimulation_manager.stimulation_amplitude   = 4;
stimulation_manager.stimulation_pulse_width = 10; % 81 microsecond pulse-width
            
stimulation_manager.stimulation_type        = 'opto';
stimulation_manager.headstage_type          = 'ZC16-OB1';
stimulation_manager.electrode_location      = 'R_HPC';
stimulation_manager.logging_directory       = exp_directory;
stimulation_manager.tank_name               = 'C:\TDT\OpenEx\MyProjects\CustomStimActiveX_Opto\DataTanks\CustomStimActiveX_Opto_DT1_061017';
stimulation_manager.block_name              = get_block_name(stimulation_manager.tank_name);

stimulation_manager.animal_id               = animal_id;
stimulation_manager.experiment_name         = experiment_name;
stimulation_manager.experiment_start_time   = posixtime(datetime('now'));
stimulation_manager.display_log_output      = 0;
stimulation_manager.initialize();
%
% Configure the metrics and objective function
%
metric                                      = opto_spectral_power(stimulation_manager.sampling_frequency,[1:3 5:16], exp_directory);
% metric                                      = opto_coherence(stimulation_manager.sampling_frequency,[5;6], exp_directory);
metric_channel                              =[6;7];
% metric                                      = opto_granger_causality(stimulation_manager.sampling_frequency,metric_channel, exp_directory);


metric_objects                              = {metric};

%
% Configure the optimization object
%
optimization_object                           = opto_cross_entropy_optimization();
optimization_object.TD                        = TD;
optimization_object.device_name               = TD.GetDeviceName(0);
optimization_object.sampling_frequency        = TD.GetDeviceSF(optimization_object.device_name);
optimization_object.objective_function        = metric; 
optimization_object.objective_type            = 'delta';%'delta'; 'raw';
optimization_object.optimization_direction    = 'maximize';%'maximize'; 'minimize';

% Sampling distribution
optimization_object.stimulation_parameter     = {'amplitude', 'frequency'};
% optimization_object.state_threshold           = 7.7e-8;
optimization_object.distribution              = 'gaussian';
optimization_object.learning_rate             = .8;
optimization_object.n_parameters              = numel(optimization_object.stimulation_parameter);
optimization_object.lower_bound               = [3.6 5]; % 0];
optimization_object.upper_bound               = [4.6 55]; %1e-7];
optimization_object.logging_directory         = exp_directory;

optimization_object.stimulation_time_s        = 5; % Before stim waiting time
stimulation_manager.stimulation_duration    = 3;
optimization_object.objective_window_s = stimulation_manager.stimulation_duration;
optimization_object.evaluate_delay_s          = 0; % After stim delay
optimization_object.samples_per_cycle         = 50;
optimization_object.n_elite_samples           = 5;
optimization_object.stimulator                = stimulation_manager;

optimization_object.initialize();
end