
function [COH PHI] = get_COH_1Hz(data,Ch_CA1,Ch_CA3)

Fs = 2000;
params.Fs = Fs;
params.tapers = [3 5];
params.fpass = [3 300];
band = [3:1:99 100:2:198 200:4:296];

Ch_COH = [];

for i=1:1:length(Ch_CA1)
    if ~isempty(find(Ch_CA3 == Ch_CA1(i)+1))
        Ch_COH(end+1) = Ch_CA1(i);
    end
end
j = 1;
for c1=Ch_COH
    %             [PSD_raw f_PSD] = mtspectrumc(temp{i}.data(c1,(i2-1)*Fs*W+1:i2*Fs*W)',params);
    [COH_raw, PHI_raw,~,~,~,f_COH] = coherencyc(data(:,c1),data(:,c1+1),params);
    COH_bin = nan(1,length(band));
    PHI_bin = nan(1,length(band));
    for k=1:1:length(band)
        band_use = [min(find(f_COH>band(k))):max(find(f_COH<band(k)+1))];
        COH_bin(k) = sum(COH_raw(band_use))/length(band_use);
        PHI_bin(k) = sum(PHI_raw(band_use))/length(band_use);
    end
    COH(j,:) = COH_bin;
    PHI(j,:) = PHI_bin;
    j = j+1;
end
COH = mean(COH,1);
PHI = mean(PHI,1);