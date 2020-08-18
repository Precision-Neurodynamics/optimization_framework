function stim_signal = opto_generate_calibration(f_sample, duration, amplitude, n_channels  )
%GENERATE_BIPHASIC Summary of this function goes here
%   Detailed explanation goes here



t   = 0:1/f_sample:duration ;
stim_signal = amplitude * ones(1,length(t));
stim_signal = repmat(stim_signal,n_channels,1);

end
