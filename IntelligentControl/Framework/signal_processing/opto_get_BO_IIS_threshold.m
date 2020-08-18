

function S_th = opto_get_BO_IIS_threshold
Coeff = 0.2;
w_out = 1.5;
directories     = 'C:\Users\TDT\Documents\IntelligentControl\results\EPI022\Compet_train_IISremov-EPI022_20180312T160055';
offset              = -5;%-5;%40;%-20;%-1;%-4;%11.4;
duration            = 60;%60;%30;%60;%15;% 6;%8.4+11.4;
experiment_table = readtable([directories '\stimulation_table.csv']);
tank_home =  'C:\TDT\OpenEx\MyProjects\CustomStimActiveX_Opto\DataTanks\CustomStimActiveX_Opto_DT1_031218'; %;'C:\TDT\OpenEx\MyProjects\CustomStimActiveX\DataTanks\CustomStimActiveX_DT1_030617'

for c1 = 1:1:5
    stim_start = experiment_table.stimulation_time(c1);
    
    t1          = stim_start + offset;
    t2          = t1 + duration;
%     file_name   = sprintf('%s\\%s_%s_%d.mat',save_home,parameter, search_type, c1);
   
        d               = TDT2mat(tank_home, experiment_table.block_name{c1}, 'T1', t1, 'T2', t2, 'VERBOSE', 0);
%         d               = TDT2mat('ARN042', 'Block-12', 'STORE', 'Wave', 'T1', t1, 'T2', t2, 'VERBOSE', 0);
        temp            = d.streams.Wave.data(:,:);
        for i=1:1:size(temp,1)
            out{c1}(i,:) = resample(double(squeeze(temp(i,:))),2000,24414);
        end
end
if ~exist('W')
W = 0.5;
end
if ~exist('MW')
MW = 0.1;
end
if ~exist('Fs')
    Fs = 2000;
end
paramssp.Fs                           = Fs;
paramssp.tapers                       = [3 5];
paramssp.fpass                        = [1 30];

S_sum_stack = [];
for i=1:1:length(out)
[S_raw, t, f] = mtspecgramc(out{i}', [W MW], paramssp);
% S = mean(S_raw,3); % these values will be coming as an input
S_sum = squeeze(sum(S_raw,2)); %t by channel % these values will be coming as an input
S_sum_stack = [S_sum_stack; S_sum];
end

% S_th = median(S_sum_stack,1)+Coeff*std(S_sum_stack,1) % these values will be coming as an input

S_th = median(S_sum_stack,1)+Coeff*std(S_sum_stack,1)

for j=1:1:size(S_sum_stack,2)
    Y_min = prctile(S_sum_stack(:,j),25);
    Y_max = prctile(S_sum_stack(:,j),75);
    S_th(j) = Y_max + w_out*(Y_max-Y_min);
end
end

