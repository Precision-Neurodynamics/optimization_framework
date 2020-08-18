function extract_optimization(blocks, ARN, experiment_tag, stimulation_data_home,  tank)

active_ch   = [2, 4, 6, 8, 9,  11, 13, 15];
active_ch   = [1];
passive_ch  = [1, 3, 5, 7, 10, 12, 14, 16];


if isempty(ARN)
    ARN = '000';
end

if isempty(experiment_tag)
    experiment_tag = 'Test';
end

if isempty(tank)
    tank = 'MainDataTank';
end

if isempty(stimulation_data_home)
    stimulation_data_home = 'C:\\Users\\TDT\\Documents\\IntelligentControl\\stimulation_data';
end

data_dir = sprintf([stimulation_data_home '\\ARN%s'], ARN); 

if ~exist(data_dir, 'dir')
   mkdir(data_dir); 
end


for block_n = blocks
    
    block   = ['Block-' num2str(block_n)];
    data    = [];
    
    for c1 = 1:length(active_ch)
        d           = TDT2mat(tank, block, 'CHANNEL', active_ch(c1), 'STORE', 'Sign');
        data(c1,:)  = d.streams.Wave.data;         
    end
    
    posix_start = posixtime(datetime([d.info.date ' ' d.info.starttime]));
    s  = sprintf('ARN%s_%s_%s_%s.mat',ARN, experiment_tag, tank, block);
   
    save([data_dir '\\' s], 'data', 'posix_start');
end