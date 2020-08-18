function realtime_state( TD, data_buffer, ~ )
load('results\models\ARN038_pre_stim_svm.mat');
f_sample        = TD.FS{1};
READ_CHAN       = [2 4 6 8 9  11 13 15];

if data_buffer.lst - data_buffer.fst > 10*6103
    t               = double((1:data_buffer.lst-data_buffer.fst+1))/f_sample;
    data            = data_buffer.raw(data_buffer.fst:data_buffer.lst,[2 4 6 8 9  11 13 15]);

    ad_psd_features = get_MT_frequency_spectrum_function(data, TD.FS{1});

    predict(SVMModel,ad_psd_features)
end
end

