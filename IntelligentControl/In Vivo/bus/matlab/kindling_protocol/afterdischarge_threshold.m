close all; clc; 

% TD = TDEV();

ARN             = 'ARN038';
STIM_CHANNELS   = [1, 3, 5, 7, 10, 12, 14, 16];
READ_CHANNELS   = [2, 4, 6, 8, 9,  11, 13, 15];

stim_record     = ['Afterdischarge-Threshold_' ARN '_' date '.csv'];

f_stimulation   = 20;
duration        = 2;
width           = 0.001;
amplitude       = 2:2:14;

pre_stim_interval   = 150;
post_stim_interval  = 150;
kindle_channels     = [1 3 5 7 10 12 14 16];  


for c1 = 1:size(amplitude,2)
    
    TD.record;
    
    open_channels(TD, STIM_CHANNELS);
    
    TD.write('mon_bank' , ceil((max(kindle_channels))/8)-1)

    pause(pre_stim_interval - duration/2);

    f_sample = TD.FS{1};
    
    signal = generate_biphasic(f_sample, f_stimulation, duration, amplitude(c1), width);
   
    write_signal(TD, kindle_channels, signal);
   
    stimulate_and_wait(TD, kindle_channels);
   
    open_channels(TD, kindle_channels);
   
    pause(post_stim_interval - duration/2);
   
    TD.idle
    
    disp('finished')
    
%     write_record(stim_record, f_stimulation, duration, width, amplitude, kindle_channels)
    
end




