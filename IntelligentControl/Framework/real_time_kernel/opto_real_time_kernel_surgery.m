function opto_real_time_kernel_surgery(TD)
close all;  
clc;  
dbstop if error;


DEBUG           = 0;
% EXPERIMENT_TYPE = 'grid_search';
EXPERIMENT_TYPE = 'grid_search3'; 
% EXPERIMENT_TYPE = 'open_loop';
% EXPERIMENT_TYPE = 'pid_controller';
% EXPERIMENT_TYPE = 'cross_entropy';
% EXPERIMENT_TYPE = 'bayesian_optimization';

%%%%%%%%%%%%%%%%%%%%%%%%%%
% Configure TDT Settings %
%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('TD', 'var')
    TD          = connect_to_TDT();
end

device_name = TD.GetDeviceName(0);
TD_FS       = TD.GetDeviceSF(device_name);
finishup    = onCleanup(@() clean_up(TD));

TD_BUFFER_TIME          = 1; % Seconds (Control policy checked at TD_BUFFER_TIME/2)
TD_READ_BUFFER_SIZE     = 16*floor(TD_FS*TD_BUFFER_TIME);
TD.SetTargetVal([device_name '.read_durr'], TD_READ_BUFFER_SIZE); % DOES NOT WORK! Need to modify circuit directly

% Get acquisition circuit variables
n_read_pts      = TD_READ_BUFFER_SIZE;
n_buff_pts      = n_read_pts/2; 
curindex        = TD.ReadTargetVEX([device_name '.read_index'], 0, 1, 'F32', 'F32');
buffer_offset   = n_buff_pts;

if DEBUG
    button = questdlg('You are starting in DEBUG mode','Are you sure you want to continue?');
    switch button 
        case 'Cancel'
            return;
        case 'No'
            return;
    end
    
    TD.SetSysMode(2);
else
    TD.SetSysMode(3);
end
pause(0.5);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Configure Experiment Objects %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
optimization_object = [];
tic
switch EXPERIMENT_TYPE 
    case 'grid_search'
        [optimization_object, ~, metric_objects] = ...
            opto_configure_grid_search_surgery(TD, DEBUG);
        display_objects = metric_objects;
    case 'grid_search3'
        [optimization_object, ~, metric_objects] = ...
            opto_configure_grid_search_surgery(TD, DEBUG); %1 is for NOR, conventional grid search.. %3 is for train pulse

    case 'cross_entropy'
        [optimization_object, ~, metric_objects] = ...
            opto_configure_cross_entropy(TD, DEBUG);
    case 'pid_controller'
        [optimization_object, ~, metric_objects] = ...
            configure_pid_control(TD, DEBUG);
%         display_objects = metric_objects;
    case 'bayesian_optimization'
        [optimization_object, ~, metric_objects] = ...
            configure_bayesian_optimization(TD, DEBUG);
%         display_objects = metric_objects;
end

while ~optimization_object.optimization_done
    
    if buffer_offset == 0 % Second half of buffer

        % Check if second half of buffer is full
        while(curindex >= n_buff_pts)

            curindex = TD.ReadTargetVEX([device_name '.read_index'], 0, 1, 'F32', 'F32');
        end
        buffer_offset = n_buff_pts;
 
    else % First half of buffer

        % Check if first half of buffer is full
        while(curindex < n_buff_pts)
            curindex = TD.ReadTargetVEX([device_name '.read_index'], 0, 1, 'F32', 'F32');
        end
        buffer_offset = 0; 
        
    end
    
    % Read data from buffer and reshape
    new_data    = TD.ReadTargetVEX([device_name '.read_buff'], ...
        buffer_offset, n_buff_pts, 'F32', 'F32');   
    new_data    = reshape(new_data, 16, n_buff_pts/16)';
    
    % Update metrics
    for c1 = 1:size(metric_objects,2)
        metric_objects{c1}.update_buffer(new_data, get_current_time(TD, device_name, TD_FS));
    end
    
    % Iterate optimization step
    optimization_object.optimize();

    % Display metrics
    if exist('display_objects', 'var')
        display_objects{c1}.update_buffer(new_data, 0);
%         realtime_metric_display(display_objects, new_data); 
        display_objects{c1}.display_metric();
    end
    % Video
%     video_objects{1}.write_recording();
    
end  % End While
% video_objects{1}.close_recording();
t = readtable([optimization_object.logging_directory '\stimulation_table.csv']);
stim_start = t.stimulation_time;
t1 = stim_start-10;
t2 = t1+30;
d = TDT2mat(optimization_object.stimulator.tank_name, t.block_name{1}, 'STORE', 'Wave', 'T1', t1, 'T2', t2, 'VERBOSE', 0);
Fs = 24414.0625;
PSD_60s(d.streams.Wave.data(:,1:Fs*30),8,Fs,10,10,5); %data,channel,Fs,baseline time, stim time, post time
PSD_60s(d.streams.Wave.data(:,1:Fs*30),11,Fs,10,10,5);


% spectrogram_60s(d.streams.Wave.data,24414.0625,15);
% spectrogram_60s(d.streams.Wave.data,24414.0625,4);
% 
TD.SetSysMode(0)

end

 function t = get_current_time(TD,device_name, sampling_frequency)
     t = TD.ReadTargetVEX([device_name '.current_time'], 0, 1, 'I32', 'F64')/sampling_frequency;
 end
        
function clean_up(TD)
    TD.SetSysMode(0);
    
    fclose('all');
%     close all;
end
