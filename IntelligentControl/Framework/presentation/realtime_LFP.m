function realtime_LFP( TD, data_buffer, ~ )

read_channel = 1;
f_sample = TD.FS{1};

t = double((1:data_buffer.lst-data_buffer.fst+1))/f_sample;
t = flip(t)*-1;

plot(t, data_buffer.raw(data_buffer.fst:data_buffer.lst,read_channel));
xlim([t(1), 0]);

end

