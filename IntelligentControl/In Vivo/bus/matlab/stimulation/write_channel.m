function write_channel(TD, channel, signal )

TD.write(['stim_buff~' num2str(channel)], signal);
TD.write(['dur~' num2str(channel)], numel(signal));

disp('allow time for channel to switch from open to closed')
pause(.05)
end

