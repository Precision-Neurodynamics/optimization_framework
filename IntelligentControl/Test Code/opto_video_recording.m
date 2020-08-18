classdef opto_video_recording < handle

    
    properties
    filename
    vid
    diskLogger
    end
    
    methods 
        function obj = opto_video_recording(filename)
            tic
            imaqreset;
            toc
            tic
            obj.vid = videoinput('winvideo',1,'RGB24_320x240');
            toc
            obj.filename = filename';
%             src = getselectedsource(obj.vid);
            obj.vid.framesPerTrigger = Inf;
            preview(obj.vid);
            start(obj.vid);
            obj.diskLogger = VideoWriter(filename);
            open(obj.diskLogger);
        end
        function write_recording(obj) % At the end of the experiment
            vid = obj.vid;
            diskLogger = obj.diskLogger;
            data = getdata(obj.vid, obj.vid.FramesAvailable);
            numFrames = size(data, 4);
            for ii = 1:numFrames
                writeVideo(diskLogger, data(:,:,:,ii));
            end
        end
        function close_recording(obj)
            diskLogger = obj.diskLogger;
            vid = obj.vid;
            close(diskLogger);
            stoppreview(vid);
            stop(vid);
            closepreview;
        end
    end
end