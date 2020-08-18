function stim_signal = generate_biphasic(f_sample, f_stimulation, duration, amplitude, width, n_channels  )
%GENERATE_BIPHASIC Summary of this function goes here
%   Detailed explanation goes here


if f_sample*width/2 < 1
    stim_signal = zeros(1,floor(f_sample*duration));
    
    
elseif f_stimulation > 0
    
    t   = 0:1/f_sample:duration + width/2;
    d1  = 0: 1/f_stimulation :duration;
    d2  = width/2: 1/f_stimulation :duration+ width/2;
    y1  = 0.5*amplitude*pulstran(t,d1,'rectpuls', width/2);
    y2  = -0.5*amplitude*pulstran(t,d2,'rectpuls', width/2);

    stim_signal = y1+y2;
else
    stim_signal = zeros(1,floor(f_stimulation*duration));
end

stim_signal = repmat(stim_signal,n_channels,1);

end
