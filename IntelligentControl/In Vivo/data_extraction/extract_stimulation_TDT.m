function  extract_stimulation_TDT(experiment_dir)

s                   = strsplit(experiment_dir, '');
save_dir            = 'C:\Users\TDT\Desktop\Extracted Data';
save_path           = [save_dir s{end} '.mat'];


experiment_table    = readtable([experiment_dir filesep 'stimulation_table.csv']);
tank_name           = experiment_table.tank_name{1};

% save(sprintf('%s/experiment_table_%s.mat', save_dir, tag), 'experiment_table')

% Extract data
window                  = 1;
recording_channels      = [2 4 6 8 9 11 13 15];
stimulating_channels    = [1 7];

for c1 = 1:size(experiment_table,1)
    tic
    stim_start      = experiment_table.stimulation_time(c1);
    stim_dur        = experiment_table.stimulation_duration(c1);
    t1              = stim_start - window;
    t2              = stim_start + stim_dur + window;
    
    d               = TDT2mat(tank_name, experiment_table.block_name{c1}, 'T1', t1, 'T2', t2, 'Verbose', 0);
    lfp_data{c1}    = double(d.streams.Wave.data(recording_channels,:));
    stim_data{c1}   = double(d.streams.Stim.data(stimulating_channels,:));
    signal_data{c1} = double(d.streams.Sign.data(stimulating_channels,:));
    
    segment_start_time(c1)  = t1;
    segment_end_time(c1)    = t2;
    
    fprintf('Extracted Trial %d in %.3f seconds\n', c1, toc)
end

save(save_path, 'lfp_data', 'stim_data', 'signal_data', 'segment_start_time', 'segment_end_time');
end

function save_segment(file_name, data, t1, t2,stim_start, stimulation_uid)

save(file_name, 'data','t1', 't2','stim_start', 'stimulation_uid');

end
