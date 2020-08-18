close all; clear all; clc;

TD = TDEV();
TD.preview;

NCHAN = 16;
MAX_BUFFER_SIZE = 100000;

disp('opening all channels')
for i = 1:NCHAN
    TD.write(['buff~' num2str(i)], MAX_BUFFER_SIZE*ones(1,10));
    TD.write(['dur~' num2str(i)], 1);
end

disp('write custom stim to channel 4')


arr = [zeros(1,1) ones(1,100) -ones(1,100)];
TD.write('buff~4', arr);
TD.write('dur~4', numel(arr));

disp('allow time for channel to switch from open to closed')
pause(.05)

disp('triggering stim')
TD.trig('trig_stim');

disp('waiting for stim to complete')
while 1
    v = 0;
    for i = 1:NCHAN
        v = v + TD.read(['not_done~' num2str(i)]);
    end
    if v == 0
        break
    end
    pause(.1)
end
disp('stim done')

disp('opening all channels')
for i = 1:NCHAN
    TD.write(['buff~' num2str(i)], 10000*ones(1,10));
    TD.write(['dur~' num2str(i)], 1);
end

TD.idle
