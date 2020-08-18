clc; clear; close all
tank_name               = 'C:\TDT\OpenEx\MyProjects\CustomStimActiveX\DataTanks\CustomStimActiveX_DT1_021420';
block_name              = 'Block-1';
tank_name_simple        = 'CustomStimActiveX_DT1_021420';

save_dir                = 'C:\Users\TDT\Desktop\Extracted Data\';
save_path               = [save_dir tank_name_simple '_' block_name '.mat'];

% Extract data
recording_channels      = [2 4 6 8 9 11 13 15];
stimulating_channels    = [1 3 5 7 10 12 14 16];
   
for c1 = 1:size(recording_channels,2)
    c1
    d                       = TDT2mat(tank_name, block_name, 'STREAM', 'Wave', 'CHANNEL', recording_channels(c1), 'VERBOSE', 0);
    lfp_data_long	     	= double(d.streams.Wave.data(1,:));
    lfp_data(c1,:)          = resample(lfp_data_long', 2000, 24414) ;
    
    d                       = TDT2mat(tank_name, block_name, 'STREAM', 'Stim', 'CHANNEL', stimulating_channels(c1), 'VERBOSE', 0);
    stim_data_long          = double(d.streams.Stim.data(1,:));
    stim_data(c1,:)         = resample(stim_data_long', 2000, 24414) ;

end

save(save_path, 'lfp_data', 'stim_data');