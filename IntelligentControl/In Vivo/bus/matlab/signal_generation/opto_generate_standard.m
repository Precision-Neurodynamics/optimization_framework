function stim_signal = opto_generate_standard(f_sample, pulse_frequency, duration, amplitude, pulse_width, n_channels  )
%   Detailed explanation goes here

if pulse_width>1-10^-10
    error('Wrong pulse width too big!')
end
t   = 0:1/f_sample:duration ;
dP = pulse_width/2:1/pulse_frequency:duration+pulse_width/2;
yP = amplitude*pulstran(t,dP,'rectpuls',pulse_width);

stim_signal = yP;
stim_signal = repmat(stim_signal,n_channels,1);

end
