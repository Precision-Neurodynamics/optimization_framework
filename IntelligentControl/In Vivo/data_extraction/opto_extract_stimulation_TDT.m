function  opto_extract_stimulation_TDT

% Create table
results_home    = 'C:\Users\TDT\Documents\IntelligentControl\results\EPI047\';%\bayesian_optimization\';%C:\Users\TDT\Documents\IntelligentControl\results\ARN053\grid\'%C:\Users\TDT\Documents\IntelligentControl\Framework\results\ARN050\Control\';%'results\ARN048\synchronous\';
% results_home = 'Z:\extracted_data\EPI033\040819\';
save_home       = 'Z:\extracted_data\EPI047\';%'E:\ARN050\Extracted\';%
directories     = {'Compet-EPI047_20191112T174818'};
% tank_home =  'C:\TDT\OpenEx\MyProjects\OpenExProject9\DataTanks\OP9_DT1_040319'; %;'C:\TDT\OpenEx\MyProjects\CustomStimActiveX\DataTanks\CustomStimActiveX_DT1_030617'
tank_home =  'C:\TDT\OpenEx\MyProjects\CustomStimActiveX_Opto\DataTanks\CustomStimActiveX_Opto_DT1_111219'; %;'C:\TDT\OpenEx\MyProjects\CustomStimActiveX\DataTanks\CustomStimActiveX_DT1_030617'
% tank_home =  'C:\TDT\OpenEx\MyProjects\Optical_Imaging_Sang\DataTanks\Optical_Imaging_Sang_DT1_092418'; %;'C:\TDT\OpenEx\MyProjects\CustomStimActiveX\DataTanks\CustomStimActiveX_DT1_030617'
% tank_home = 'Z:\Opto_CustomStimActiveX_Backup\CustomStimActiveX_Opto_DT1_100319';
parameter       = 'Compet';%'Compet-Theta';%'Theta-stim';%'7Hzstim';%'Grid_Search';%'Seiz_C2';%'Compet_train';%'Compet_standard';%%'Stim';%'BO_train';%
search_type     = '111219';

% parameter         = 'Seiz';
% search_type       = 'C2';
% offset                = -15;
% duration              = 15+8.4+15;
% offset              = -8;%-8;
% duration            = 24;%24;
offset              = -5;%-8;%-11.4;%5;%40;%-20;%-1;%-4;%
duration            = 30;%24;%8.4+11.4;%60;%60;%30;%15;% 6;%
Version = 1; %1:Regular, 2: NOR/Seizure
N_seg = 60;

% Take relevant directories and create stimulation table
experiment_table = table();
for c1 = 1:numel(directories)
    
    t = readtable([results_home directories{c1} '\stimulation_table.csv']);
    
%     if strcmpi(t.block_name{1}(1:5),'Block')
        experiment_table = [experiment_table; t];
%     end
end
save(sprintf('%s/experiment_table_%s_%s.mat', save_home, parameter,search_type), 'experiment_table')

% Extract data


% recording_channels  = [1:17];


%% Regular version
if Version == 1
for c1 = 1:size(experiment_table,1)
    stim_start = experiment_table.stimulation_time(c1);
    
    t1          = stim_start + offset;
    t2          = t1 + duration;
    file_name   = sprintf('%s\\%s_%s_%d.mat',save_home,parameter, search_type, c1);
   
    try
        d               = TDT2mat(tank_home, experiment_table.block_name{c1}, 'T1', t1, 'T2', t2, 'VERBOSE', 0);
%         d               = TDT2mat('ARN042', 'Block-12', 'STORE', 'Wave', 'T1', t1, 'T2', t2, 'VERBOSE', 0);
        data            = d.streams.Wave.data;
        stim            = d.streams.Stim.data;
        stimulation_uid = experiment_table.stimulation_uid;
        if exist('stim')
        save_segment(file_name, data,stim, t1, t2,stim_start, stimulation_uid)
        else
        save_segment(file_name, data, [], t1, t2,stim_start, stimulation_uid)
        end
    catch    
        fprintf('stimulation %d could not be extracted\n', c1);
    end
end

%% Long verision (segment)
else
for c1 = 1:N_seg
    stim_start = experiment_table.stimulation_time(1) + duration*(c1-1);
%     stim_start = duration*(c1-1);
    t1          = stim_start + offset;
    t2          = t1 + duration;
    file_name   = sprintf('%s\\%s_%s_%d.mat',save_home,parameter, search_type, c1);
   
    try
        d               = TDT2mat(tank_home, experiment_table.block_name{1}, 'T1', t1, 'T2', t2, 'VERBOSE', 0);
%         d               = TDT2mat(tank_home, 'Block-8', 'T1', t1, 'T2', t2, 'VERBOSE', 0);
%         d               = TDT2mat('ARN042', 'Block-12', 'STORE', 'Wave', 'T1', t1, 'T2', t2, 'VERBOSE', 0);
        data            = d.streams.Wave.data;
        stim            = d.streams.Stim.data;
        stimulation_uid = experiment_table.stimulation_uid;
        if exist('stim')
        save_segment(file_name, data,stim, t1, t2,stim_start, stimulation_uid)
        else
        save_segment(file_name, data, [], t1, t2,stim_start, stimulation_uid)
        end
    catch    
        fprintf('stimulation %d could not be extracted\n', c1);
    end
end
end

end

function save_segment(file_name, data,stim, t1, t2,stim_start, stimulation_uid)
if exist('stim')
    save(file_name, 'data', 'stim','t1', 't2','stim_start', 'stimulation_uid');
else
    save(file_name, 'data', 't1', 't2','stim_start', 'stimulation_uid');
end
end
function average_power = get_average_power(d,~)
    recording_channels  = [2 4 6 8 9 11 13 15];

    data                = d.streams.Wave.data;
    params.Fs           = d.streams.Wave.fs;
    params.fpass        = [4 10];
    params.tapers       = [3 5];
    
    S                   = mtspectrumc(data(recording_channels,:)',params);
    average_power       = mean(sum(S));
end