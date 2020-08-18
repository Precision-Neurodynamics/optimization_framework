function [controller, stimulation_manager, metric_objects] = configure_pid_control(TD, DEBUG)
%
% Configure logging
%
result_dir                                  = 'results/ARN045/pid_control';
animal_id                                   = '045';
experiment_name                             = 'pid_control_theta_NOR11';
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
stimulation_manager.stimulation_channels    = 1;

% CHANGE THIS BACK
stimulation_manager.stimulation_frequency   = 200;
stimulation_manager.stimulation_duration    = 1;
stimulation_manager.stimulation_amplitude   = 1;
stimulation_manager.stimulation_pulse_width = 2/stimulation_manager.sampling_frequency; % 80 microsecond pulse-width
            
stimulation_manager.stimulation_type        = 'synchronous';
% stimulation_manager.stimulation_mode        = 'unipolar';
stimulation_manager.headstage_type          = 'RA16Z_CH';
stimulation_manager.electrode_location      = 'R_HPC';
stimulation_manager.logging_directory       = exp_directory;
stimulation_manager.tank_name               = 'ARN045_20160718';
stimulation_manager.block_name              = get_block_name(stimulation_manager.tank_name);

stimulation_manager.animal_id               = animal_id;
stimulation_manager.experiment_name         = experiment_name;
stimulation_manager.experiment_start_time   = posixtime(datetime('now'));
stimulation_manager.display_log_output      = 0;
stimulation_manager.initialize();
%
% Configure the metrics and objective function
%
metric_1        = spectral_power(stimulation_manager.sampling_frequency,[2 4 6 8 11 9 15 13], exp_directory);
metric_2        = bipolar(stimulation_manager.sampling_frequency,[2 4], exp_directory);
metric_objects  = {metric_1};

%
% Configure the optimization object
%
controller                          = pid_controller();
controller.TD                       = TD;
controller.device_name              = TD.GetDeviceName(0);
controller.sampling_frequency       = TD.GetDeviceSF(controller.device_name);
controller.pv_function              = metric_1; 

controller.stimulation_parameter    = 'amplitude';
controller.Kp                       = 5e7;
controller.Ki                       = 5e7;
controller.Kd                       = 0;
controller.setpoint                 = 1e-8;
controller.setpoint_time            = 0 ;
controller.lower_bound              = 0;
controller.upper_bound              = 10;
controller.logging_directory        = exp_directory;

controller.evaluate_delay_s         = .1;
controller.pv_window_s              = 1;

controller.stimulator               = stimulation_manager;

controller.initialize();

end

