function plot_16_ch(lfp, fs)

%TODO Make work for general number of channels and indexed channels 
clc; close all;

scrsz = get(groot,'ScreenSize');
figure('Position',[1 scrsz(4)*(2/3) scrsz(3) scrsz(4)*1/3])

t = linspace(0,size(lfp, 1)/fs, size(lfp, 1));

lfp_norm    = lfp - repmat(mean(lfp,1), size(lfp,1), 1);
min_lfp     = min(min(lfp_norm));
max_lfp     = max(max(lfp_norm));
ha          = tight_subplot(2,4,[.01 .005],[.1 .01],[.03 .01]);

for c1 = 1:8
    axes(ha(c1));
    plot(t, lfp_norm(:,c1), 'color', 'k');
    ylim([min_lfp*1.2, max_lfp*1.2]);
    xlim([0 20]);
    
    set(ha(c1),'YTickLabel','');
    if(c1 ~= 1 && c1 ~= 5)
        set(ha(c1),'YTickLabel','');
    else
        if(c1 == 1)
            ylabel('CA3 LFP (mV)');
        else
            ylabel('CA1 LFP (mV)');
        end
    end
    
    if(c1 == 5)
            xlabel('Time (seconds)');
    else
        set(ha(c1),'XTickLabel','');
    end
end

end
