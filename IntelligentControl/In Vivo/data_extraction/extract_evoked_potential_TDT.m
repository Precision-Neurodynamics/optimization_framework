function extract_evoked_potential_TDT(stimulation_log)
% close all
figure
window_length_idx       = 250;
recording_channels      = [8 6 4 2 9 11 13 15];
stimulating_channels    = 11;

stimulation_table       = readtable(stimulation_log);
block_name              = stimulation_table.block_name{1};
tank_name               = stimulation_table.tank_name{1};


d               = TDT2mat(tank_name, block_name, 'VERBOSE', 0);
data            = d.streams.Wave.data(recording_channels,:);
stim_sig        = d.streams.Sign.data(stimulating_channels,:);
stim            = d.streams.Stim.data(stimulating_channels,:);

stim_flip       = -1*flip(stim_sig);
fs              = d.streams.Wave.fs;
pulse_start     = zeros(size(stim_sig));
pulse_end       = pulse_start;

% Get all pulse times
search_idx = 1;
while search_idx < size(stim_sig,2)
    next_pulse_start                = find(stim_sig(search_idx:end) > 0, 1) + search_idx - 1;    
    pulse_start(next_pulse_start)   = 1;    
    search_idx                      = next_pulse_start + 15;
end

search_idx = 1;
while search_idx < size(stim_sig,2)
    next_pulse_end              = find(stim_flip(search_idx:end) > 0, 1) + search_idx - 1;    
    pulse_end(next_pulse_end)   = 1;    
    search_idx                  = next_pulse_end + 15;
end
pulse_end       = flip(pulse_end);
pulse_end_idx   = find(pulse_end > 0);
pulse_start_idx = find(pulse_start > 0);

% Collect all the post-stimulation data
for c1 = 1:size(pulse_end_idx,2)
    window_start    = pulse_end_idx(c1)-250;
    window_end      = window_start + window_length_idx;
    ep_mat(c1,:,:)  = data(:,window_start:window_end);
    st_mat(c1,:)    = stim(window_start:window_end);
end

t = (1:size(ep_mat,3))/fs * 1e3;
tt = [t flip(t)];
% Plot each channel
for c1 = 1:size(ep_mat,2)
    channel_ep  = squeeze(ep_mat(:,c1,:));
    ep_mean     = mean(channel_ep);
    ep_std      = std(channel_ep);
    ep_se       = ep_std / sqrt(size(ep_mat,2));
    
    yy          = [ep_mean(c1) - ep_se flip(ep_mean + ep_se)];
    
    subplot(2,4,c1)
    hold on
    patch(tt, yy, .5*ones(1,3), 'FaceAlpha', .5, 'EdgeColor', 'k')
    plot(t, ep_mean, 'LineWidth', 2, 'Color', 'r')
    
    title(sprintf('Channel: %d', recording_channels(c1)))
    xlabel('milliseconds')
    ylabel('Potential (V)')
    set(gca,'FontSize', 12)
    xlim([min(t) max(t)]);
end
end