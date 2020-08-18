
function  Record_extract_Sang

% tank_home =  'C:\Users\TDT\Documents\IntelligentControl\results\EPI040\Baseline-EPI040_20190527T104159'; %;'C:\TDT\OpenEx\MyProjects\CustomStimActiveX\DataTanks\CustomStimActiveX_DT1_030617'
tank_home = 'C:\TDT\OpenEx\Tanks\ImplantSurgeryTank';
save_home       = 'E:\rec';%'Z:\extracted_data\PTZ\0516';%'Z:\extracted_data\PTZ\';%'E:\ARN050\Extracted\';%
parameter       = 'Tank116';%'whatever you want to call'
search_type     = 'duringsurgery2';%'whatever you want to call'
c1 =1;
while 1
t1          = 60*(c1-1);
t2          = 60*c1;
file_name   = sprintf('%s\\%s_%s_%d.mat',save_home,parameter, search_type, c1);

d               = TDT2mat(tank_home, 'block-116', 'T1', t1, 'T2', t2, 'VERBOSE', 0);
data            = d.streams.Wave.data(1:16,:);
        save_segment(file_name, data, [], t1, t2,[], [])
c1 = c1+1;
end

end

function save_segment(file_name, data,stim, t1, t2,stim_start, stimulation_uid)
if exist('stim')
save(file_name, 'data', 'stim','t1', 't2','stim_start', 'stimulation_uid');
else
    save(file_name, 'data', 't1', 't2','stim_start', 'stimulation_uid');
end
end


