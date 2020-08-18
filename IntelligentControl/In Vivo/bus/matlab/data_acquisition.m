close all; clear all; clc;

TD = TDEV();
TD.preview;

NCHAN = 16;
MAX_BUFFER_SIZE = 100000;

filePath = 'C:\Users\TDT\Desktop\Mark_ActiveX\';
filePath = strcat(filePath, 'fnoise.F64');
fnoise = fopen(filePath,'w');

npts = length(TD.read('buff'));

% serial buffer will be divided into two buffers A & B
bufpts = npts/2; 
t=(1:bufpts)/TD.FS{1};

curindex = TD.read('index');

% main looping section
for i = 1:10  

    % wait until done writing A
    while(curindex < bufpts)
        curindex = TD.read('index');
        pause(.05);
    end

    % read segment A
    noise = TD.read('buff', 'SIZE', bufpts);
    disp(['Wrote ' num2str(fwrite(fnoise,noise,'float64')) ' points to file']);

    % checks to see if the data transfer rate is fast enough
    curindex = TD.read('index');
    disp(['Current buffer index: ' num2str(curindex)]);
    if(curindex < bufpts)
        warning('Transfer rate is too slow');
    end

    % wait until start writing A 
    while(curindex > bufpts)
        curindex = TD.read('index');
        pause(.05);
    end

    % read segment B
    noise = TD.read('buff', 'OFFSET', bufpts, 'SIZE', bufpts);
    disp(['Wrote ' num2str(fwrite(fnoise,noise,'float64')) ' points to file']);

    % make sure we're still playing A 
    curindex = TD.read('index');
    disp(['Current index: ' num2str(curindex)]);
    if(curindex > bufpts)
        warning('Transfer rate too slow');
    end
   
end

TD.idle;
fclose(fnoise);

