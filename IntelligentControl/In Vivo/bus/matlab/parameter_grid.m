close all; clc; 

% TD = TDEV();

ARN             = 'ARN035';
STIM_CHANNELS   = [1, 3, 5, 7, 10, 12, 14, 16];
READ_CHANNELS   = [2, 4, 6, 8, 9,  11, 13, 15];

stim_record     = ['Afterdischarge-Threshold_' ARN '_' date '.csv'];

duration        = 4;
width           = 0.01;
amplitude       = 1.0; 

pre_stim_interval   = 28;
post_stim_interval  = 28;
kindle_channels     = [5, 12, 5, 5, 5, 12, 12, 12, 12, 5, 12, 12, 12, 5, 5, 5];  
f_stimulation       = [5, 50, 110, 95, 20, 5, 95, 80, 20, 80, 65, 35, 110, 65, 50, 35];

kindle_channels     = [5];  
f_stimulation       = [35];
for c1 = 1:size(f_stimulation,2)
    
    TD.record;
    
    open_channels(TD, STIM_CHANNELS);
    
    TD.write('mon_bank' , ceil((max(kindle_channels(c1)))/8)-1)

    pause(pre_stim_interval - duration/2);

    f_sample = TD.FS{1};
    
    signal = generate_biphasic(f_sample, f_stimulation(c1), duration, amplitude, width);
   
    write_signal(TD, kindle_channels(c1), signal);
   
    stimulate_and_wait(TD, kindle_channels(c1));
   
    open_channels(TD, kindle_channels(c1));
   
    pause(post_stim_interval - duration/2);
   
    TD.idle
    
    disp('finished')
        
end




