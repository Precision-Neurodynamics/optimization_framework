
% This is for preparing IIS threshold and normalization features

function [S_th, stats] = opto_get_BO_PSD

%% Part 1 data preparation
if ~exist('W')
W = 5;
end
if ~exist('MW')
MW = 5;
end
if ~exist('Fs')
    Fs = 2000;
end
directories     = 'C:\Users\TDT\Documents\IntelligentControl\results\EPI047\Baseline-EPI047_20191112T160905';
offset              = 0;%-5;%40;%-20;%-1;%-4;%11.4;
duration            = 60;%60;%30;%60;%15;% 6;%8.4+11.4;
experiment_table = readtable([directories '\stimulation_table.csv']);
tank_home =  'C:\TDT\OpenEx\MyProjects\CustomStimActiveX_Opto\DataTanks\CustomStimActiveX_Opto_DT1_111219'; %;'C:\TDT\OpenEx\MyProjects\CustomStimActiveX\DataTanks\CustomStimActiveX_DT1_030617'
Seizout = [];
Chout = [13];%%%%%%%%%%%%%%%%%%%%%%%%%%%% to delete channel
effc1 = [1:10]; %%%%%%%%%%%%%%%%%%%%%%%%%%%% range of minutes to be searched

todel = [];%%%%%%%%%%%%%%%%%%%%%%%%%%
effc1(ismember(effc1 , todel)) = [];
j1 = 1;
for c1 = effc1%size(experiment_table,1) %5min is enough!!
    stim_start = experiment_table.stimulation_time(c1);
    
    t1          = stim_start + offset;
    t2          = t1 + duration;
%     file_name   = sprintf('%s\\%s_%s_%d.mat',save_home,parameter, search_type, c1);
   
        d               = TDT2mat(tank_home, experiment_table.block_name{c1}, 'T1', t1, 'T2', t2, 'VERBOSE', 0);
%         d               = TDT2mat('ARN042', 'Block-12', 'STORE', 'Wave', 'T1', t1, 'T2', t2, 'VERBOSE', 0);
        temp            = d.streams.Wave.data(:,:);
        for i=1:1:size(temp,1)
            out{j1}(i,:) = resample(double(squeeze(temp(i,:))),Fs,24414);
        end
        j1 = j1+1;
end

params.Fs                           = Fs;
params.tapers                       = [3 5];
params.fpass                        = [33 50];

%% Part 2. Calculate PSD
NW = floor(size(out{1},2)/(W*Fs));
j = 1;
for i=1:1:length(out)
    for i2=1:1:NW
        [PSDraw(j,:,:),fPSD] = mtspectrumc(out{i}(:,Fs*(i2-1)*W+1:Fs*i2*W)',params);
        j = j+1;
    end
end
PSDraw(:,Chout,:) = [];
PSD = mean(sum(PSDraw,3),2);
figure
plot(PSD)
median(PSD)
