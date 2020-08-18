close all; clear all; clc;

TD = TDEV();

STIM_CHANNELS   = [1, 3, 5, 7, 10, 12, 14, 16];
READ_CHANNELS   = [2, 4, 6, 8, 9,  11, 13, 15];


f_stimulation   = 10;
duration        = 10;
width           = 0.001;
amplitude       = 1; 

stim_interval   = 5*6;
kindle_channel  = 12;  
iterations      = 50;

for c1 = 1:iterations
    
    TD.preview;
    TD.write('mon_bank' , ceil((kindle_channel)/8)-1)
    f_sample = TD.FS{1};
    
    open_channels(TD, STIM_CHANNELS);
   
    signal = generate_biphasic(f_sample, f_stimulation, duration, amplitude, width);
   
    write_channel(TD, kindle_channel, signal);
   
    stimulate_and_wait(TD, kindle_channel);
   
    open_channels(TD, kindle_channel);
   
    pause(stim_interval - duration);
   
    TD.idle
    
    disp('finished')
end


