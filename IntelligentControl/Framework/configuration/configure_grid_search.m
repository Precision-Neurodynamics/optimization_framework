function [optimizer, stimulation_manager, metric_objects] = configure_grid_search(TD, DEBUG, animal_id)

%
% Configure logging
%

%%% ADMETS Experiments
% experiment_name                             = 'ADMETS_I8_2-2_pre_sham';
 %experiment_name                             = 'ADMETS_I8_2-2_stimulation';
% experiment_name                             = 'ADMETS_I8_2-2_post_sham';


%%% NOR Experiments
% experiment_name                             = 'ADMETS_I8_NOR_pre_control';
% experiment_name                             = 'ADMETS_I8_NOR_experiment_stim';
% experiment_name                             = 'ADMETS_I8_NOR_experiment_sham';
% experiment_name                             = 'ADMETS_I8_NOR_pos_control';
% experiment_name                             = 'ADMETS_I8_NOR_real_time_opt';

%%% Grid Search Experiments
% experiment_name                             = 'ADMETS_I8_grid_search_frequency_amplitude';
% experiment_name                             = 'ADMETS_I8_grid_search_duration_amplitude';
% experiment_name                             = 'ADMETS_I8_grid_search_duration_amplitude';

% experiment_name                             = '5V_ADMETS_5-5_2m';
% experiment_name                             = 'Sham_ADMETS_5-5';
% experiment_name                             = 'Baseline';
% experiment_name                             = '2V_ADMES_60-0';
experiment_name                             = 'PCN_ADMETS_TEST';


if strcmp(animal_id, '') ||  strcmp(experiment_name, '')
    [animal_id, experiment_name]            = get_experiment_info(DEBUG);    
end

if DEBUG
    experiment_name = [experiment_name 'DEBUG'];
end
result_dir            	= ['results/' animal_id '/grid'];
time_str                = datestr(now, 30);
log_pattern             = [result_dir '/' experiment_name '-%s_%s'];
exp_directory           = sprintf(log_pattern, animal_id, time_str);
mkdir(exp_directory)

[~, tank_name]          = fileparts(TD.GetTankName);     
block_name              = get_block_name(tank_name);
%
% Configure open-loop stimulation
%

stimulation_manager                         = open_stimulator();
stimulation_manager.TD                      = TD;
stimulation_manager.device_name             = TD.GetDeviceName(0);
stimulation_manager.sampling_frequency      = TD.GetDeviceSF(stimulation_manager.device_name);

%
% sequence order
% stimulation_manager.stimulation_channels    = [1 3 5 7 10 12 14 16 ]; %

%
% shuffled order
stimulation_manager.stimulation_channels    = [16 12 14 1 5 7 3 10 ];
stimulation_manager.stimulation_phase       = 'C';

stimulation_manager.stimulation_type        = 'asynchronous';
stimulation_manager.headstage_type          = 'RA16Z_CH';
stimulation_manager.electrode_location      = 'HPC';
stimulation_manager.logging_directory       = exp_directory;
stimulation_manager.tank_name               = tank_name;                  
stimulation_manager.block_name              = block_name;
stimulation_manager.initialize();

stimulation_manager.animal_id               = animal_id;
stimulation_manager.experiment_name         = experiment_name;
stimulation_manager.experiment_start_time   = posixtime(datetime('now'));
stimulation_manager.display_log_output      = 'simple';

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
optimizer.stimulation_time_s        = 180;
optimizer.evaluate_delay_s          = 180;

optimizer.n_samples                 = 1;  %%% THIS LINE SAYS WHERE TO START THE STIMULATION

% Fine grids
% duration  = [0.1  0.25 0.5  0.75 1.0  1.25 1.5  2   2.5  3   3.5  4 ]
% frequency = [4, 10, 15, 30, 45, 60, 80, 100, 150, 200, 250, 300] 
% amplitude = [1 3 5 7 10]

optimizer.amplitude                 = 1;

optimizer.frequency                 = [7]; %[7, 25,  50, 100, 200, 300];
optimizer.duration                  = [660];

% optimizer.stim_channels             = [1,3,5,7,10,12,14,16];
optimizer.stim_channels             = stimulation_manager.stimulation_channels;
optimizer.n_repetitions             = 1;
optimizer.width                     = 10/stimulation_manager.sampling_frequency;
optimizer.logging_directory         = exp_directory;
optimizer.display_log_output        = 'simple';
optimizer.stimulator                = stimulation_manager;

optimizer.initialize();

end

