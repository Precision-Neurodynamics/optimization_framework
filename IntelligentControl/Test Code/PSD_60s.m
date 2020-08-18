% PSD_60s (ford,Ch,Fs,bs,os,as)
function [psd_bs, psd_os, psd_as, f_bs] = PSD_60s (ford,Ch,Fs,bs,os,as)
psd_bs = [];
psd_os = [];
psd_as = [];
f_bs = [];
%% File Loading and length check
% check if total length is less than bs+os+as
if ~exist('Fs')
    Fs = 24414.0625;
end
if isstr(ford)
    a = load(ford);
    if ~isfield(a,'data')
        afn = fieldnames(a);
        ag = getfield(a,afn{1});
        dataraw = ag.streams.Wave.data;
    else
        dataraw = a.data;
    end
elseif isstruct(ford)
    if ~isfield(ford,'data')
        afn = fieldnames(ford);
        ag = getfield(ford,'streams');
        dataraw = ag.Wave.data;
    else
        dataraw = ford.data;
    end
else
    dataraw = ford;
end

LT = length(dataraw(1,:))/ Fs;

if bs+os+as > LT
    error('The sum of inputs (bs,os,as) is longer than total length of the data');
end

%% Channel selection & Downsample
DS_factor = 10;
data_bds(1,:) = mean(dataraw(Ch,:),1);

if Fs>20000
data(:,:) = downsample(data_bds(:,:),DS_factor);
Fs = Fs/DS_factor;
else
    data(1,:) = data_bds(1,:);
end

figure
subplot(2,1,1)
plot(1/Fs*(1:1:length(data(1,:))),data(1,:))
axis([0 1/Fs*length(data(1,:)) -inf inf])
hold on

%% Data dividing
BL = floor(Fs * bs);
OL = floor(Fs * os);
AL = floor(Fs * as);

data_bs = data(1,1:BL);
data_os = data(1,BL+1:BL+OL);
data_as = data(1,BL+OL+1:BL+OL+AL);

% plot(1/Fs*(1:1:length(data_bs(1,:))),data_bs(1,:))
plot(1/Fs*(length(data_bs(1,:))+1:1:length(data_bs(1,:))+length(data_os(1,:))),data_os(1,:),'r')
plot(1/Fs*(length(data_bs(1,:))+length(data_os(1,:))+1:1:length(data_bs(1,:))+length(data_os(1,:))+length(data_as(1,:))),data_as(1,:),'g')


%% Power Spectral Density
subplot(2,1,2)
hold on
if bs>0
[psd_bs,f_bs] = pwelch(data_bs,[],[],round(Fs*2),Fs);
plot(f_bs(6:201),psd_bs(6:201))
end
if os>0
[psd_os,f_os] = pwelch(data_os,[],[],round(Fs*2),Fs);
plot(f_os(6:201),psd_os(6:201),'r')
end
if as>0
[psd_as,f_as] = pwelch(data_as,[],[],round(Fs*2),Fs);
plot(f_as(6:201),psd_as(6:201),'g')
end

% subplot(2,1,2)
% plot(f_bs(2:201),psd_bs(2:201))
% hold on
% plot(f_os(2:201),psd_os(2:201),'r')
% plot(f_as(2:201),psd_as(2:201),'g')
legend('Before Stim','On Stim','After Stim')


