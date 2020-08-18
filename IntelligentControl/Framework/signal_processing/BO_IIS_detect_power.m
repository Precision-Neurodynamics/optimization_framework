
% making it channel based

function out = BO_IIS_detect_power(data,S_th,W,MW,Fs,plot_flag)

if ~exist('W')
    W = 0.5;
end
if ~exist('MW')
    MW = 0.1;
end
if ~exist('Fs')
    Fs = 2000;
end
paramssp.Fs                           = Fs;
paramssp.tapers                       = [3 5];
paramssp.fpass                        = [3 30];
[S_raw, t, f] = mtspecgramc(data', [W MW], paramssp);
% S = mean(S_raw,3); % these values will be coming as an input
S_sum = squeeze(sum(S_raw,2)); %t by channel % these values will be coming as an input
% S_th = median(S_sum,1)+std(S_sum,1); % these values will be coming as an input


for C=1:1:size(S_sum,2)
    ind_up = [];
    ind_down = [];
    ind_Sp_final = [];
    time_Sp_final = [];
    indraw_Sp_final = [];
    
    ind_Sp = logical(squeeze(S_sum(:,C))>S_th(C)); %find the index above threshold
    if ind_Sp(1) == 1
        ind_up(1) = 1;
        temp = find(diff(ind_Sp) == 1);
        ind_up = [ind_up;temp];
    else
        ind_up = find(diff(ind_Sp) ==1);
    end
    
    ind_down = find(diff(ind_Sp) == -1);
    if ind_Sp(end) == 1
        ind_down(end+1,1) = length(ind_Sp)-1;
    end
    ind_down = ind_down + 1;
    ind_length = ind_down - ind_up;
    ind_detect = find(ind_length>3); %1.5second
    ind_Sp_final = [];
    for i=1:1:length(ind_detect)
        ind_Sp_final = [ind_Sp_final ind_up(ind_detect(i)):ind_down(ind_detect(i))];
        time_Sp_final(i,1:2) = [t(ind_up(ind_detect(i)))-W/2, t(ind_down(ind_detect(i)))+W/2];
        indraw_Sp_final(i,1:2) = [(t(ind_up(ind_detect(i)))-W/2)*2000, (t(ind_down(ind_detect(i)))+W/2)*2000];
    end
    
    out.ind_Sp_final{C} = ind_Sp_final;
    out.time_Sp_final{C} = time_Sp_final;
    out.indraw_Sp_final{C} = indraw_Sp_final;
end


%% plotting
if plot_flag == 1
figure(99)
fig_size = [4,8];
dT = t(2)-t(1);
for i=1:1:size(data,1)
    subplot(fig_size(1),fig_size(2),2*(i-1)+1)
    plot([1:1:size(data,2)]/2000,data(i,:))
    hold on
    subplot(fig_size(1),fig_size(2),2*(i-1)+2)
    plot(t,S_sum(:,i),'b')
    hold on
    for j=1:1:size(out.time_Sp_final{i},1)
        [~,ind1] = min(abs(t-out.time_Sp_final{i}(j,1)));
        [~,ind2] = min(abs(t-out.time_Sp_final{i}(j,2)));
        subplot(fig_size(1),fig_size(2),2*(i-1)+2)
        plot(t(ind1:ind2),S_sum(ind1:ind2,i),'r')
        subplot(fig_size(1),fig_size(2),2*(i-1)+1)
        plot([out.indraw_Sp_final{i}(j,1):out.indraw_Sp_final{i}(j,2)]/2000,data(i,round([out.indraw_Sp_final{i}(j,1):out.indraw_Sp_final{i}(j,2)])),'r')
    end
    subplot(fig_size(1),fig_size(2),2*(i-1)+1)
    hold off
    subplot(fig_size(1),fig_size(2),2*(i-1)+2)
    hold off

end
end

% for i=1:1:length(ind_detect)
%     subplot(3,2,6)
%     plot(t(ind_up(ind_detect(i)):ind_down(ind_detect(i))),S_sum(ind_up(ind_detect(i)):ind_down(ind_detect(i))),'r')
%     subplot(3,2,3:4)
%     hold on
%     plot([indraw_Sp_final(i,1):indraw_Sp_final(i,2)]/2000,data(2,[indraw_Sp_final(i,1):indraw_Sp_final(i,2)]),'r')
%     subplot(3,2,1:2)
%     hold on
%     plot([indraw_Sp_final(i,1):indraw_Sp_final(i,2)]/2000,data(Chmax,[indraw_Sp_final(i,1):indraw_Sp_final(i,2)]),'r')
% end