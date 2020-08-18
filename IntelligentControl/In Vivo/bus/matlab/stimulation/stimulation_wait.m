function stimulation_wait(TD, channels)
%STIMULATION_WAIT Summary of this function goes here
%   Detailed explanation goes here

n_channels = size(channels,1);

% disp('waiting for stim to complete')
while 1
    v = 0;
    for c1 = 1:n_channels
        v = v + TD.read(['not_done~' num2str(channels(c1))]);
    end
    if v == 0
        break
    end
    pause(.1)
end

% disp('stim done')
end

