function signal_stimulation_N(TD, varargin )

if mod(nargin, 2) ~= 1
    return;
end

channels = cell2mat(varargin(1:2:nargin-1))';
signals  = varargin(2:2:nargin-1);

open_channels(TD, channels);

write_channels(TD, channels, signals);

open_channels(TD, channels);
end

