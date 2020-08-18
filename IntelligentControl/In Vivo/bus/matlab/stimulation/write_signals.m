function write_signals( TD, device_name, channels, signals )
%WRITE_SIGNALS Summary of this function goes here
%   Detailed explanation goes here

for c1 = 1:length(channels)
    write_signal(TD, device_name, channels(c1), signals(c1,:));
end


end

