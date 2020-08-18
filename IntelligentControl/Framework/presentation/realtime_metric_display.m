function  realtime_metric_display( metric_objects, new_data)
%REALTIME_DISPLAY Summary of this function goes here
%   Detailed explanation goes here

n_displays  = length(metric_objects);
for c1 = 1:n_displays
    subplot(n_displays,1, c1)
    metric_object   = metric_objects{c1};
    
    metric_object.update_buffer(new_data, 0)

    metric_buffer   = metric_object.METRIC_BUFFER;
    metric_fst      = metric_buffer.fst;
    metric_lst      = metric_buffer.lst;
    
    data            = metric_buffer.raw(metric_fst:metric_lst);
    fs              = metric_object.metric_sampling_frequency;
    
    duration        = double(metric_buffer.bufSz/fs);

    t               = fliplr(0:1/fs:duration)*-1;
    L               = min(length(t), length(data));
    
    plot(t(1:L), real(data(1:L)));
    ylabel(metric_objects{c1}.name);
    if isprop(metric_objects{c1}, 'ylim') && ~isempty(metric_objects{c1}.ylim)
        ylim(metric_objects{c1}.ylim)
    end
    xlim([-1*duration 0])
end
drawnow
end

