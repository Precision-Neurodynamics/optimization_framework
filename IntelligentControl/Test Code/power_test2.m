load('/Users/mconnolly/Dropbox/stimulation data/ARN 035 RapidKindling/ARN035_RapidKindling_Block-242.mat')

f_sample    = data.streams.Wave.fs;
ch2         = data.streams.Wave.data(2,:);
t_data      = (1:length(ch2))/f_sample;
lower_band      = 500;          % Hertz
upper_band      = 550;          % Hertz

counts = [];
for offset = 100:100:f_sample
index           = 1;
    for c1 = offset:f_sample/2:length(ch2)-f_sample/2
        recent_data     = ch2(floor(c1):floor(c1+f_sample/2));
        n_samples       = length(recent_data);

        psd             = abs(fftshift(fft(recent_data)))/n_samples;
        dF              = f_sample/n_samples;
        f               = -f_sample/2:dF:f_sample/2-dF;

        f_lower         = find(f > lower_band,1);
        f_upper         = find(f > upper_band,1) - 1;

        signal_power(index)    = sum(psd(f_lower:f_upper));
        index = index+1;



    end

    count = 0;
    
    for c1 = 1:length(signal_power)-1
        if signal_power(c1) < 4e-4 ...
                && signal_power(c1) > 1e-5 ...
                && signal_power(c1+1) > 4e-4
            count = count+1;
        end

    end
    counts = [counts count];
end

% plot(signal_power, '-o')
% hold on
% plot([0 index], [1e-5 1e-5])