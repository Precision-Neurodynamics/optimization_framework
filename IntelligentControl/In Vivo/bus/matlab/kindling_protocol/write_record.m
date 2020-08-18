function write_record( stim_record, f_stimulation, duration, width, amplitude, channel)

if ~exist(stim_record, 'file')
    header      = {'f_stimulation', 'duration', 'width', 'amplitude', 'channel'};
    txt        = sprintf('%s,',header{:});
    txt(end)   ='';
    dlmwrite(stim_record,txt,'');
end

dlmwrite(stim_record,[f_stimulation, duration, width, amplitude, channel],'delimiter',',','-append');

end


