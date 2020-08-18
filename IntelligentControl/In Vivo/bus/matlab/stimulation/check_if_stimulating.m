function v = check_if_stimulating( TD, device_name, channels )
%CHECK_IF_STIMULATING Summary of this function goes here
%   Detailed explanation goes here

v = 0;
for c1 = 1:numel(channels)
    v = v + TD.ReadTargetVEX([device_name '.not_done~' num2str(channels(c1))], 0, 1, 'F32', 'F32');
end

end

