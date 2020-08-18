function realtime_spectrogram(f_sample, data_buffer, read_channel)

subplot(2,1,1)
t = double((1:data_buffer.lst-data_buffer.fst+1))/f_sample;
plot(t, data_buffer.raw(data_buffer.fst:data_buffer.lst,read_channel));
xlim([0, t(end)]);
subplot(2,1,2)
spectrogram(data_buffer.raw(data_buffer.fst:data_buffer.lst,2),128,120,128,f_sample,'yaxis');
ylim([0 1])
colorbar off

end
