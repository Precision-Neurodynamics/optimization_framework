function stimulate(TD, device_name)


% TD.trig('trig_stim');
TD.SetTargetVal([device_name '.trig_stim'], 1);
pause(.1)
TD.SetTargetVal([device_name '.trig_stim'], 0);

end

