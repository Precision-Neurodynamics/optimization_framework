function stim_signal = opto_generate_biphasic(f_sample, f_stimulation, duration, amplitude1, amplitude2, width1, width2, n_channels  )
%GENERATE_BIPHASIC Summary of this function goes here
%   Detailed explanation goes here


if f_sample*width1/2 < 1
    stim_signal = zeros(1,floor(f_sample*duration));
    
    
elseif f_stimulation > 0
    
    t   = 0:1/f_sample:duration + max(width1,width2);
    d1  = 0: 1/f_stimulation :duration;
    d2  = (width1+width2)/2: 1/f_stimulation :duration+ (width1+width2)/2;
    y1  = amplitude1*pulstran(t,d1,'rectpuls', width1);
    y2  = -amplitude2*pulstran(t,d2,'rectpuls', width2);

    stim_signal = y1+y2;
else
    stim_signal = zeros(1,floor(f_stimulation*duration));
end

stim_signal = repmat(stim_signal,n_channels,1);

end
