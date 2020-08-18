function [ signal, fs ] = extract_stimulation
%EXTRACT_STIMULATION Summary of this function goes here
%   Detailed explanation goes here

load_directory      = '/Users/mconnolly/Dropbox/stimulation data/ARN 035 RapidKindling';
save_directory      = '/Users/mconnolly/Dropbox/Intelligent Control Repository/data/ARN035 Kindling Extracted/';
file_key            = 'ARN 035 Kindling Notes.xlsx';
tank                = 'ARN035_RapidKindling';
stim_channels       = [1,3,5,7,10,12,14,16];
mea_channels        = setdiff(1:16, stim_channels);

file_list = dir(load_directory);
for c1 = 1:size(file_list, 1)
    try 
        fname = file_list(c1).name;

        if size(fname,2) > 3 && strcmp(fname(end-3:end), '.mat') 
            
            save_file = [save_directory strrep(fname, '.mat', '_stimulation_extract.mat')];
          
            
            load([load_directory '/' fname]);

            signal_data = data.streams.Sign.data(stim_channels,:);
            mea_data    = data.streams.Wave.data(mea_channels,:);

            for c2 = 1:size(stim_channels,2)
                channel_open(c2)    = find(signal_data(c2,:) > 300, 1);
                channel_close(c2)   = channel_open(c2) + find(signal_data(c2,channel_open(c2):end) < 300, 1);
            end

            [stimulation_start, stim_ch]  = min(channel_close);
            stimulation_end     = - 2 + stimulation_start + find(signal_data(stim_ch,stimulation_start:end) > 300, 1);

            subplot(3,1,1)
            plot(signal_data(stim_ch,1:stimulation_start), 'k-')
            hold on
            subplot(3,1,2)
            plot(signal_data(stim_ch,stimulation_start:stimulation_end))
            subplot(3,1,3)
            plot(signal_data(stim_ch,stimulation_end+1:end), 'k-')

            pre_stimulation    = mea_data(:,1:stimulation_start);
            post_stimulation   = mea_data(:,stimulation_end+1:end);
            if exist(save_file)
                continue;
            end
            save(save_file, ...
                'pre_stimulation', 'post_stimulation');
        end
    catch
        fname 
    end
    
end
end
