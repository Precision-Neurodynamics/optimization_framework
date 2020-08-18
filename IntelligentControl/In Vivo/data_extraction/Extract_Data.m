active_ch = [2, 4, 6, 8, 9, 11, 13, 15];
passive_ch = [1, 3, 5, 7, 10, 12, 14, 16];
ARN = '045';
experiment_tag = 'jmalcom_granger_causality_baseline';
date = '2016-06-30';
tank = 'ARN045';

for block_n = [53]
    
    block   = ['Block-' num2str(block_n)];
    data    = [];
    
    for c1 = 1:length(active_ch)
        d           = TDT2mat(tank, block, 'CHANNEL', active_ch(c1), 'STORE', 'Wave');
        data(c1,:)  = d.streams.Wave.data;         
    end
    
    s  = sprintf('C:\\Users\\TDT\\Dropbox\\ARN 045 Granger Causality\\ARN%s_%s_%s.mat'...
                ,ARN, tank, block);
   
    save(s, 'data');
end