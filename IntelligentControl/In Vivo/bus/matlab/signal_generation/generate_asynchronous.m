function stim_matrix = generate_asynchronous(sampling_frequency,     ...
                                stimulation_frequency,  ...
                                duration,               ...
                                amplitude,              ...
                                pulse_width,            ...
                                n_channels)

stim_order  = [1 5 2 6 3 7 4 8] ;
s           = generate_biphasic(sampling_frequency, stimulation_frequency, duration*2, amplitude, pulse_width,1);
stim_matrix = zeros(n_channels,size(s,2));

for c1 = 1:n_channels
    
    start_sample                    = floor((c1-1)*sampling_frequency/stimulation_frequency/n_channels + 1);
    offset_stim                     = [zeros(1,start_sample-1) s];
    stim_matrix(stim_order(c1),:)   = offset_stim(1:size(stim_matrix,2));
    
end


stim_matrix = [stim_matrix(:,1:floor(sampling_frequency*duration)) ones(n_channels,100)*0 ];

end

