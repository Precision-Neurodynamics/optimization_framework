    function extract_stimulation_TDT_2(trial_name)
%EXTRACT_STIMULATION_TDT_2 Summary of this function goes here
%   Detailed explanation goes here
recording_channels    = [2 4 6 8 9 11 13 15];
stimulating_channels  = [1 3 5 7 10 12 14 16];

if nargin < 1
    trial_name          = 'Block-1';
end

save_dir            = 'C:\Users\TDT\Desktop\Extracted Data';
save_path           = [save_dir trial_name '.mat'];
stimulation_table   = readtable(['C:\TDT\OpenEx\MyProjects\CustomStimActiveX\DataTanks\CustomStimActiveX_DT1_021219\' trial_name filesep 'stimulation_table.csv']);

if size(stimulation_table,1) == 0
    return
end

block_name          = stimulation_table.block_name{1};
tank_name           = stimulation_table.tank_name{1};
tic

d                   = TDT2mat(tank_name, block_name, 'STORE', 'Wave', 'Channel', recording_channels(1), 'VERBOSE', 0);

lfp_data            = nan(size(recording_channels,2), size(d.streams.Wave.data,2));
for c1 = 1:size(recording_channels,2)
    d = TDT2mat(tank_name, block_name, 'STORE', 'Wave', 'Channel', recording_channels(c1), 'VERBOSE', 0);
    fs = d.streams.Wave.fs;
    d = double(d.streams.Wave.data);
    lfp_data(c1,:) = d; %resample(d, 1000, round(fs));
end

for c1 = 1:size(stimulating_channels,2)
    s_stim      = TDT2mat(tank_name, block_name, 'STORE', 'Stim', 'Channel', stimulating_channels(c1), 'VERBOSE', 0);
    s_sign      = TDT2mat(tank_name, block_name, 'STORE', 'Sign', 'Channel', stimulating_channels(c1), 'VERBOSE', 0);
    
    s_stim = double(s_stim.streams.Stim.data);
    s_sign = double(s_sign.streams.Sign.data);
    
    stim_data(c1,:)     = s_stim; %resample(d, 1000, round(fs));
    signal_data(c1,:)   = s_sign; %resample(d, 1000, round(fs));
end

% figure
% plot(stim_data');
% title(trial_name);
save(save_path, 'lfp_data', 'stim_data', 'signal_data', 'stimulation_table');
toc
end