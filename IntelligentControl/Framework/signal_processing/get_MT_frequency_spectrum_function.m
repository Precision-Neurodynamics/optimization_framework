function ad_psd_features = get_MT_frequency_spectrum_function(data, TD_FS)


f_sample                    = TD_FS;
max_f                       = 50;
bin_size                    = 1;
N_bins                      = max_f/bin_size;

data            = data - repmat(mean(data,2),1,size(data,2));
n_channels      = size(data',1);
params.Fs       = f_sample;
params.tapers   = [3 5];
[S, f]          = mtspectrumc(data, params);

% Bin data
f_data = nan(N_bins, n_channels);
for c2 = 1:N_bins
    lower = (c2-1)*bin_size;
    upper = bin_size*c2;

    lower_idx = find(f > lower,1);
    upper_idx = find(f > upper,1) -1;
    f_data(c2,:) = sum(S(lower_idx:upper_idx,:))/N_bins;  


end

ad_psd_features = reshape(f_data,1,n_channels*N_bins );

end

