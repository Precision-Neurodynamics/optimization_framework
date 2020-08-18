function  realtime_display( display_objects, TD, data_buffer )
%REALTIME_DISPLAY Summary of this function goes here
%   Detailed explanation goes here

n_displays  = length(display_objects);
for c1 = 1:n_displays
    subplot(n_displays,1, c1)
    
    display_objects{c1}(TD, data_buffer)
end
end

