function [ ad_psd_features, group_data ] = get_MT_frequency_spectrum

% Get data
data_directory              = 'data/pre_stimulation_classification_dataset/';
file_list                   = dir(data_directory);
% f_sample                    = 6103;
f_sample                    = 24414;
max_f                       = 50;
bin_size                    = 1;
N_bins                      = max_f/bin_size;
row_idx                     = 1;

for c1 = 1:length(file_list)
    fname = file_list(c1).name;
    if strcmp(fname(1), '.') || strcmp(fname(1:2), 'ad')
        continue;
    end
    
    load([data_directory fname]);
%     data            = data(4,:);
%     data            = data - repmat(mean(data,2),1,size(data,2));
%     n_channels      = size(data,1);
%     params.Fs       = f_sample;
%     params.tapers   = [3 5];
%     [S, f]          = mtspectrumc(data', params);
% 
%     % Bin data
%     f_data = nan(N_bins, n_channels);
%     for c2 = 1:N_bins
%         lower = (c2-1)*bin_size;
%         upper = bin_size*c2;
% 
%         lower_idx = find(f > lower,1);
%         upper_idx = find(f > upper,1) -1;
%         f_data(c2,:) = sum(S(lower_idx:upper_idx,:))/N_bins;  
% 
%         
%     end
%     
%     ad_psd_features(row_idx,:) = reshape(f_data,1,n_channels*N_bins );
    ad_labels(row_idx) = (group -2)*-1;
row_idx             = row_idx+1

    
end

% save([data_directory 'ad_psd_features.mat'], 'ad_psd_features')
save([data_directory 'ad_labels.mat'], 'ad_labels')

end

