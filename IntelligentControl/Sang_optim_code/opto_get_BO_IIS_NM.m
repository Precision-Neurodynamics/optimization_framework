
% This is for preparing IIS threshold and normalization features

function [S_th, stats] = opto_get_BO_IIS_NM

%% Part 1 data preparation
if ~exist('W')
W = 0.5;
end
if ~exist('MW')
MW = 0.1;
end
if ~exist('Fs')
    Fs = 2000;
end
directories     = 'C:\Users\TDT\Documents\IntelligentControl\results\EPI045\Baseline-EPI045_20191007T150626';
offset              = 0;%-5;%40;%-20;%-1;%-4;%11.4;
duration            = 60;%60;%30;%60;%15;% 6;%8.4+11.4;
experiment_table = readtable([directories '\stimulation_table.csv']);
tank_home =  'C:\TDT\OpenEx\MyProjects\CustomStimActiveX_Opto\DataTanks\CustomStimActiveX_Opto_DT1_100719'; %;'C:\TDT\OpenEx\MyProjects\CustomStimActiveX\DataTanks\CustomStimActiveX_DT1_030617'
Seizout = [];
Chout = [13];%%%%%%%%%%%%%%%%%%%%%%%%%%%%
effc1 = [2:4:58];

todel = [34];%%%%%%%%%%%%%%%%%%%%%%%%%%
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

paramssp.Fs                           = Fs;
paramssp.tapers                       = [3 5];
paramssp.fpass                        = [3 30];


%% Part 2. IIS threshold calculation
Coeff = 0.2;
w_out = 2;%1.5;
S_sum_stack = [];
for i=1:1:length(out)
[S_raw, t, f] = mtspecgramc(out{i}', [W MW], paramssp);
% S = mean(S_raw,3); % these values will be coming as an input
S_sum = squeeze(sum(S_raw,2)); %t by channel % these values will be coming as an input
S_sum_stack = [S_sum_stack; S_sum];
end

% S_th = median(S_sum_stack,1)+Coeff*std(S_sum_stack,1) % these values will be coming as an input

% S_th = median(S_sum_stack,1)+Coeff*std(S_sum_stack,1)

for j=1:1:size(S_sum_stack,2)
    Y_min = prctile(S_sum_stack(:,j),25);
    Y_max = prctile(S_sum_stack(:,j),75);
    S_th(j) = Y_max + w_out*(Y_max-Y_min);
end
S_th

%% Part 3. Get features for PiSM normalization
Wfeat = 5;
% Seizout = [109:110 120:130 170:180];

featout = TeNT_Grid_getFeatures_IIS(out,Wfeat,Seizout,Chout,'grid',Wfeat,'grid',S_th,20,20,20);
featall = [];
for i=1:1:length(featout)
    if ~isempty(featout{i}.PSD)
        PSDCA1 = squeeze(nanmean(featout{i}.PSD(:,1:2:15,:),2));
        PSDCA3 = squeeze(nanmean(featout{i}.PSD(:,2:2:16,:),2));
        COH = squeeze(nanmean(featout{i}.COH(:,:,:),2));
        PHI = squeeze(nanmean(featout{i}.PHI(:,:,:),2));
        if size(PSDCA1,2) == 1
            PSDCA1 = PSDCA1';
            PSDCA3 = PSDCA3';
            COH = COH';
            PHI = PHI';
        end
        featall = [featall; [PSDCA1 PSDCA3 COH PHI]];
    end
end
for i=1:1:size(featall,2)
    tonan = find(Isoutlier(featall(:,i)));
    temp = featall(:,i);
    temp(tonan) = nan;
    meanN(i) = nanmean(temp);
    stdN(i) = nanstd(temp);
end
stats.meanN = meanN;
stats.stdN = stdN;
save([directories,'\Sth_stats.mat'],'stats','S_th');
end

function [av]=Isoutlier(FF)
  mk=median(FF);
  M_d=mad(FF,1);
  c=-1/(sqrt(2)*erfcinv(3/2));
  smad=c*M_d;
  tsmad=3*smad;
  av=(abs(FF-mk)>=tsmad);
 end
