function open_channels(TD, device_name, channels)

% disp('opening channels')

for c1 = 1:size(channels,2);
    TD.WriteTargetVEX([device_name '.stim_buff~' num2str(channels(c1))], 0, 'F32',  10000*ones(1,10));
    TD.SetTargetVal([device_name '.dur~' num2str(channels(c1))], 10);
end

end

