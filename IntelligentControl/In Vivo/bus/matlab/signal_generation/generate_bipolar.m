function stim_matrix = generate_bipolar( sampling_frequency,     ...
                                stimulation_frequency,  ...
                                duration,               ...
                                amplitude,              ...
                                pulse_width,            ...
                                n_pairs)


% Channels is an Nx2 matrix where each row represents a bipolar pair, the
% first column being the cathode and the second column the anode


% t                   = 0:1/sampling_frequency:duration + pulse_width;
% stimulation_times   = 0: 1/stimulation_frequency :duration;
% anode               = 0.5*amplitude*pulstran(t,stimulation_times,'rectpuls', pulse_width);
% cathode             = -1*anode;

anode               = generate_biphasic(sampling_frequency, stimulation_frequency, duration, amplitude, pulse_width, n_pairs  );
cathode             = -1*anode;

stim_matrix(2:2:n_pairs*2, :) = repmat(cathode, n_pairs, 1);
stim_matrix(1:2:n_pairs*2, :) = repmat(anode, n_pairs, 1);

end

