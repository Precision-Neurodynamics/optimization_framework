function write_signal( TD, device_name, channel, signal )

TD.WriteTargetVEX([device_name '.stim_buff~' num2str(channel)], 0, 'F32',   [0 signal ]);
TD.SetTargetVal([device_name '.dur~' num2str(channel)],1+numel(signal));

end

