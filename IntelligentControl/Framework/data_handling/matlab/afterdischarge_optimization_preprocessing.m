function afterdischarge_optimization_preprocessing( )
fs = 6103;

fid = fopen('data/ARN038_pre_stimulation_dataset/afterdischarge_optimization_log_ARN038.csv');
C = textscan(fid,'%f %f %f %s %f %f %f %f %f %f','Delimiter',',','headerlines', 1);
fclose(fid);

run_cycle_time = C{1};
cycle_start_time = C{2};
stimulation_time = C{3};

for c1 = 1:53
    
    switch(c1)
        case 1
            load('/Users/mconnolly/Dropbox/stimulation data/ARN 038 AD Optimization/ARN038_MainDataTank_Block-19.mat');
            data_all = data;
        case 19
            load('/Users/mconnolly/Dropbox/stimulation data/ARN 038 AD Optimization/ARN038_MainDataTank_Block-20.mat');
            data_all = data;
        case 28
            load('/Users/mconnolly/Dropbox/stimulation data/ARN 038 AD Optimization/ARN038_MainDataTank_Block-21.mat');
            data_all = data;
        case 39
            load('/Users/mconnolly/Dropbox/stimulation data/ARN 038 AD Optimization/ARN038_MainDataTank_Block-22.mat');
            data_all = data;
    end
  
    
    cycle_start     = floor((cycle_start_time(c1)-run_cycle_time(c1))*fs);
    stim_start      = floor((stimulation_time(c1)-run_cycle_time(c1))*fs);
    stim_end        = floor(stim_start + 5*fs);
    segment_end     = floor(stim_end + 10*fs);
    segment_start   = stim_start - 10*fs;
    cycle_end       = floor(cycle_start+300*fs);
    
    
%     data = data_all(:,segment_start:stim_start);
%     data = data_all(:,stim_end:segment_end);
    
%     save(['/Users/mconnolly/Dropbox/Intelligent Control Repository/data/ARN038_post_stimulation_dataset/' ...
%          sprintf('ARN038_poststimulation_10s_segment-%d',c1)], 'data')
%     save(['/Users/mconnolly/Dropbox/Intelligent Control Repository/data/ARN038_pre_stimulation_dataset/' ...
%          sprintf('ARN038_prestimulation_10s_segment-%d',c1)], 'data')
end
end
