function realtime_line_length(TD, data_buffer, ~  )
%REALTIME_LINE_LENGTH Summary of this function goes here
%   Detailed explanation goes here

read_channel = 1;

f_sample = TD.FS{1};

step_size = double(data_buffer.lst - data_buffer.new);

t = (step_size:step_size:(double(data_buffer.lst) - double(data_buffer.fst)))/f_sample;
t = flip(t)*-1;

ll_idx  = data_buffer.fst:step_size:data_buffer.lst;
ll      = nan(size(ll_idx,2)-1,1);
for c1 = 1:length(ll_idx)-1
    ll_segment  = data_buffer.raw(ll_idx(c1):ll_idx(c1)+step_size-1, read_channel);
    ll(c1)      = mean(abs(ll_segment(2:end) - ll_segment(1:end-1))); 
end

plot(t,ll)
xlim([t(1), 0])