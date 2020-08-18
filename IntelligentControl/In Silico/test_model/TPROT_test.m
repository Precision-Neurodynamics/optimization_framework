function  TPROT_test(TD)
close all;  clc; 
dbstop if error;
DEBUG = 1;
% Set up connection
if ~exist('TD', 'var')
    TD = TDEV();
end

%%%%%%%%%%%%%%%%%%%%%%%
% Logging Information %
%%%%%%%%%%%%%%%%%%%%%%%
animal_id       = '000';
result_dir      = 'results';
experiment_name = 'stimulation_test';
time_str        = datestr(now, 30);

start_time      = posixtime(datetime('now'));

if DEBUG
    log_header  = [experiment_name '_DEBUG'];
    TD.preview
else
    log_header  = experiment_name;
    TD.record
end
log_pattern     = [result_dir '/' log_header '-ARN%s_%s'];
exp_directory   = sprintf(log_pattern, animal_id, time_str);

mkdir(exp_directory);
time_fid        = fopen([exp_directory '/start_time.csv'], 'a');
fprintf(time_fid,'%f',start_time);
TD_FS           = TD.FS{1};


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Configure Experiment Objects %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
metric_1  	= bipolar_spectral_power(TD_FS,[2 4; 6 8; 11 9;15 13], exp_directory);
metric_2    = bipolar(TD_FS,[2 4], exp_directory);
% correlation_1       = correlation(TD_FS,[4 13], exp_directory);
% pass_through_1  = pass_through(TD_FS,4, exp_directory);
% pass_through_2  = pass_through(TD_FS,13, exp_directory);

metric_objects  = {metric_1, metric_2};

% Configure optimization
optimization_object = cross_entropy_optimization(TD_FS, metric_1, exp_directory, DEBUG);

%%%%%%%%%%%%%%%%%%%%%%%%%%
% Configure TDT Settings %
%%%%%%%%%%%%%%%%%%%%%%%%%%
TD_BUFFER_TIME          = 1; % Seconds (Control policy checked at TD_BUFFER_TIME/2)
TD_READ_BUFFER_SIZE     = 16*ceil(TD_FS*TD_BUFFER_TIME);
STIM_CHAN               = [1 3 5 7 10 12 14 16];
TD.write('read_durr', TD_READ_BUFFER_SIZE);


% Open all stimulation channels
open_channels(TD, STIM_CHAN);

% Get acquisition circuit variables
n_read_pts      = TD_READ_BUFFER_SIZE;
n_buff_pts      = n_read_pts/2; 
curindex        = TD.read('read_index');
buffer_offset   = n_buff_pts;
while ~optimization_object.optimization_done
    
    if buffer_offset == 0 % Second half of buffer
        % Check if second half of buffer is full
        while(curindex > n_buff_pts)
            curindex = TD.read('read_index');
            pause(.05);
        end
        
        buffer_offset = n_buff_pts;
    else % First half of buffer
        
        % Check if first half of buffer is full
        while(curindex < n_buff_pts)
            curindex = TD.read('read_index');
            pause(.05);
        end
            
        buffer_offset = 0;
    end
  
    % Read data from buffer and reshape
    new_data    = reshape(TD.read('read_buff', 'SIZE', n_buff_pts, 'OFFSET', buffer_offset), 16, n_buff_pts/16)';
    
    % Update metrics
    for c1 = 1:size(metric_objects,2)
        metric_objects{c1}.update_buffer(new_data);
    end
    
    % Display metrics
    if exist('metric_objects', 'var')
        realtime_metric_display(metric_objects); 
    end
    
    % Iterate optimization step
    optimization_object.optimize(TD);

end  % End While

TD.idle
end

