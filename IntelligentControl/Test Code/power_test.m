load('/Users/mconnolly/Dropbox/stimulation data/ARN 035 RapidKindling/ARN035_RapidKindling_Block-242.mat')

f_sample    = data.streams.Wave.fs;
ch2         = data.streams.Wave.data(2,:);
t_data      = (1:length(ch2))/f_sample;


% [s, f]  = spectrogram(ch2, floor(f_sample/2), 0, [], f_sample);
% 
% lower   = find(f > 500, 1);
% upper   = find(f > 550, 1) - 1;
% 
% power   = abs(sum(s(lower:upper,:)))/floor(f_sample/2);

lower_band      = 500;          % Hertz
upper_band      = 550;          % Hertz
index = 1;
for c1 = 4400:f_sample/2:length(ch2)-f_sample/2
    recent_data     = ch2(floor(c1):floor(c1+f_sample/2));
    n_samples       = length(recent_data);

    psd             = abs(fftshift(fft(recent_data)))/n_samples;
    dF              = f_sample/n_samples;
    f               = -f_sample/2:dF:f_sample/2-dF;

    f_lower         = find(f > lower_band,1);
    f_upper         = find(f > upper_band,1) - 1;

    power(index)    = sum(psd(f_lower:f_upper));
    index = index+1;



end
t_power = (1:length(power))/2+4400/f_sample;
threshold = ones(1,length(t_power))*1e-5;

subplot(2,2,[1 2])
[AX, hLine1, hLine2] = plotyy(t_data, ch2,t_power, power );

hLine1.Color = 0*ones(3,1);
AX(1).YColor = [ 0 0 0];

hLine2.Color = [1 .2 .2];
AX(2).YColor = [1 .2 .2];

xlabel('Seconds');
ylabel(AX(1), 'LFP (V)');
ylabel(AX(2), 'Power [500-550Hz] (V^2)');
axes(AX(2));
hold on
plot(t_power, ones(1,length(t_power))*1e-5, 'color', .5*ones(1,3), 'linestyle', '--');

xlim(AX(1),[100 t_power(end)]);
xlim(AX(2),[100 t_power(end)]);

subplot(2,2,3)
plot(t_data,ch2, 'k-')
xlim([118 119])

subplot(2,2,4)
plot(t_data,ch2, 'k-')
xlim([160.2 160.35])
