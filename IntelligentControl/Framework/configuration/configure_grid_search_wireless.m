function [optimizer, stimulation_manager, metric_objects] = configure_grid_search_wireless(TD, DEBUG, animal_id)

%
% Configure logging
%

%%% ADMETS Experiments
% experiment_name                             = 'ADMETS_I8_2-2_pre_sham';
% experiment_name                             = 'ADMETS_I8_2-2_stimulation';
% experiment_name                             = 'ADMETS_I8_2-2_post_sham';

%%% NOR Experiments
% experiment_name                             = 'ADMETS_I8_NOR_pre_control';
% experiment_name                             = 'ADMETS_I8_NOR_experiment_stim';
% experiment_name                             = 'ADMETS_I8_NOR_experiment_sham';
% experiment_name                             = 'ADMETS_I8_NOR_pos_control';

%%% Grid Search Experiments
% experiment_name                             = 'ADMETS_I8_grid_search_frequency_amplitude';
% experiment_name                             = 'ADMETS_I8_grid_search_duration_amplitude';
experiment_name                             = 'ADMETS_I8_grid_search_wireless';


if strcmp(animal_id, '') ||  strcmp(experiment_name, '')
    [animal_id, experiment_name]            = get_experiment_info(DEBUG);    
end

if DEBUG
    experiment_name = [experiment_name 'DEBUG'];
end
result_dir                                  = ['results/' animal_id '/grid'];
time_str                                    = datestr(now, 30);
log_pattern                                 = [result_dir '/' experiment_name '-%s_%s'];
exp_directory                               = sprintf(log_pattern, animal_id, time_str);
mkdir(exp_directory)

%
% Configure 
%
stimulation_manager                         = stimulator();
stimulation_manager.TD                      = TD;
stimulation_manager.device_name             = TD.GetDeviceName(0);
stimulation_manager.sampling_frequency      = TD.GetDeviceSF(stimulation_manager.device_name);
% stimulation_manager.stimulation_channels    = [1 16 ];
% stimulation_manager.stimulation_channels    = [3 14 ];
% stimulation_manager.stimulation_channels    = [5 12 ];
stimulation_manager.stimulation_channels    = [7 10 ];

stimulation_manager.stimulation_type        = 'bipolar';
stimulation_manager.headstage_type          = 'RA16Z_CH';
stimulation_manager.electrode_location      = 'HPC';
stimulation_manager.logging_directory       = exp_directory;
stimulation_manager.tank_name               = 'CustomStimActiveX_DT1_050317';                  %%%%%% Change Each Day
stimulation_manager.block_name              = get_block_name(stimulation_manager.tank_name);
stimulation_manager.initialize();

stimulation_manager.animal_id                = animal_id;
stimulation_manager.experiment_name          = experiment_name;
stimulation_manager.experiment_start_time    = posixtime(datetime('now'));
stimulation_manager.display_log_output       = 'simple';

%
% Configure the metrics and objective function
%
% metric_1        = bipolar_spectral_power(stimulation_manager.sampling_frequency,[2 4; 6 8; 11 9;15 13], exp_directory);
% metric_2        = bipolar(stimulation_manager.sampling_frequency,[2 4], exp_directory);
% metric_objects  = {metric_1, metric_2};
metric_objects  = {};

%
% Configure the optimization object
%
optimizer = grid_search();
optimizer.TD                        = TD;
optimizer.stimulation_time_s        = 5;
optimizer.evaluate_delay_s          = 5;

optimizer.n_samples                 = 1; %%% THIS LINE SAYS WHERE TO START THE STIMULATION

% Fine grids
% duration  = [0.1  0.25 0.5  0.75 1.0  1.25 1.5  2   2.5  3   3.5  4 ]
% frequency = [4, 10, 15, 30, 45, 60, 80, 100, 150, 200, 250, 300] 
% amplitude = [1 3 5 7 10]

% optimizer.frequency                 = [7];
% optimizer.duration                  = [1];
optimizer.amplitude                 = [ 200 400];

optimizer.frequency                 = [ 16 32]; %[7, 25,  50, 100, 200, 300];
optimizer.duration                  = .5;

optimizer.n_repetitions             = 5;
optimizer.width                     = 3/stimulation_manager.sampling_frequency;
optimizer.logging_directory         = exp_directory;
optimizer.display_log_output        = 'simple';
optimizer.stimulator                = stimulation_manager;

optimizer.initialize();

end

