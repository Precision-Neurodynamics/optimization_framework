function activex_test(TD)
stim_channels = 9;

device_name = TD.GetDeviceName(0);
TD_FS       = TD.GetDeviceSF(device_name);
TD.SetSysMode(2);

stimulation_frequency   = 7;
stimulation_duration    = 120; % seconds
delay                   = 1/(8*stimulation_frequency);

period  = floor(TD_FS / stimulation_frequency);
nPulses = stimulation_frequency * stimulation_duration;
n_delay = floor(TD_FS * delay);

signal = sin(1:1000/10);
TD.SetTargetVal('RZ2.buff', 1);

TD.SetTargetVal('RZ2.trig_stim', 1);
pause(0.1)
TD.SetTargetVal('RZ2.trig_stim', 0);

fprintf('Post-Stim\n');
TD.ReadTargetVEX('RZ2.not_done~1',0, 1, 'F32', 'F32')
pause(240)
for c1 = 1:size(stim_channels,2)
    TD.SetTargetVal(['RZ2.trig_stim~' num2str(stim_channels(c1))], 0);
end

end

function v = is_stimulating(obj)
    v = 0;
    for c1 = 1:numel(obj.stimulation_channels)
        v = v + obj.TD.ReadTargetVEX(...
            [obj.device_name '.not_done~' num2str(obj.stimulation_channels(c1))],...
            0, 1, 'F32', 'F32');
    end

end