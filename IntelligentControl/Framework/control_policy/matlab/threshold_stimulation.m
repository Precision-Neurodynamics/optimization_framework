function threshold_stimulation(TD, data_buffer)
% Debug parameters
display         = 1;            % 1 = on, 0 = off

% Aquisition parameters
read_channel    = 2;   
f_sample        = TD.FS{1};     % Hertz  
read_length     = 1;            % Seconds (relevant buffer history)
n_samples       = read_length * f_sample;  

% Control parameters
threshold       = 1e-5;         % V^2
stim_refractory = 2;            % Seconds
lower_band      = 500;          % Hertz
upper_band      = 550;          % Hertz

% stimulation parameters
f_stimulation   = 20;           % Hertz
duration        = .5;           % Seconds
amplitude       = 3;            % Volts
width           = .001;         % Seconds
stim_channel    = 3;

% Collect recent data (see circVbuff documentation)
last_idx        = data_buffer.lst;
first_idx       = last_idx - int64(n_samples) + 2;
recent_data     = data_buffer.raw(first_idx:last_idx,:);

% Check for sufficient amount of data
if toc > n_samples/f_sample
    
    % Process data
    psd             = abs(fftshift(fft(recent_data(:,read_channel))))/n_samples;
    dF              = f_sample/n_samples;
    f               = -f_sample/2:dF:f_sample/2-dF;
    
    f_lower         = find(f > lower_band,1);
    f_upper         = find(f > upper_band,1) - 1;
    
    signal_power    = sum(psd(f_lower:f_upper));
    output          = sprintf('Power = %.4e\n', signal_power);
    disp(output);
    
    if sum(isnan(signal_power)) == 0 ... % Sufficient data in buffer
       && signal_power > threshold ...
       && toc > stim_refractory          % Refractory period over
   
        stim_signal = generate_biphasic(f_sample, f_stimulation, duration, amplitude, width);
  
        write_signal(TD, stim_channel, stim_signal);

        stimulate(TD);

        open_channels(TD, stim_channel);
        
        tic % Update refractory counter
    end
end
   
end