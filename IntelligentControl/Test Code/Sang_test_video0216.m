imaqreset
vid = videoinput('winvideo',1,'RGB24_640x480');
filename = 'C:\Sang_temp\test4.avi';
src = getselectedsource(vid);
vid.framesPerTrigger = Inf;
diskLogger = VideoWriter(filename);
open(diskLogger);
preview(vid);
start(vid);
for i = 1:1:120
pause(1)
% data = getdata(vid, vid.FramesAvailable);
% numFrames = size(data, 4);
% for ii = 1:numFrames
% writeVideo(diskLogger, data(:,:,:,ii));
% end
% data = getdata(vid, vid.FramesAvailable);
% % numFrames = size(data, 4);
% for ii = 1:size(data, 4)
% writeVideo(diskLogger, data(:,:,:,ii));
% end
end
stoppreview(vid);
stop(vid);
tic
data = getdata(vid, vid.FramesAvailable);
toc
tic
numFrames = size(data, 4);
for ii = 1:numFrames
writeVideo(diskLogger, data(:,:,:,ii));
end
toc
close(diskLogger);
closepreview;