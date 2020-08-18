
function PSD = get_PSD_1Hz(data,Ch)

% j1 = 1;
% j2 = 1;
%     NW = floor((size(data,2)-Fs*W)/(Fs*MW))+1;
%     Wind(:,1) = 1:MW*Fs:MW*Fs*(NW-1)+1;
%     Wind(:,2) = Wind(:,1)+W*Fs-1;
%     for i2=1:1:NW
Fs = 2000;
params.Fs = Fs;
params.tapers = [3 5];
params.fpass = [3 300];
band = [3:1:99 100:2:198 200:4:296];
j = 1;
for c1=Ch
    [PSD_raw f_PSD] = mtspectrumc(data(:,c1),params);
    PSD_bin = nan(1,length(band));
    for k=1:1:length(band)
        band_use = [min(find(f_PSD>band(k))):max(find(f_PSD<band(k)+1))];
        PSD_bin(k) = sum(PSD_raw(band_use))/length(band_use);
        f_PSD_bin(k) = band(k); %just for checking
    end
    PSD(j,:) = PSD_bin;
    j = j+1;
end
PSD = mean(PSD,1);
%     end
% PSD(:,Chout,:) = NaN;
% COH(:,ceil(Chout/2),:) = NaN;
