%% To do
%0. Make it channel specific
%1.mean and sigma from long data to define IIS threshold
%2. New objective functions
%3. New model and parameters

% function BO_IIS_remove()

data = out{7}.data;

W = 3;
OW = 2.4;
N_seg = 10;
%Define window
%(1)Pre_control (2)On_control (3) Pre_stim (4)On_stim

for i=1:1:N_seg
    Pre_control_W(i,1) = 0+(W-OW)*(i-1); %start
    Pre_control_W(i,2) = W+(W-OW)*(i-1); %end
    On_control_W(i,1) = W+(W-OW)*(i-1); %start
    On_control_W(i,2) = W*2+(W-OW)*(i-1); %end
    
    stim_start = W*2+(W-OW)*(N_seg-1);
    Pre_stim_W(i,1) = stim_start-W+(W-OW)*(i-1); %start
    Pre_stim_W(i,2) = stim_start+(W-OW)*(i-1); %end
    On_stim_W(i,1) = stim_start+(W-OW)*(i-1); %start
    On_stim_W(i,2) = stim_start+W+(W-OW)*(i-1); %end
end


% Theta calculation
Fs = 2000;
params.Fs = Fs;
params.tapers = [3 5];
params.fpass = [4 10];
Ch = 1:16;
for a=1:1:length(out)
    for i=1:1:N_seg
        Pre_control_theta(a,i) = sum(mean(mtspectrumc(out{a}.data(Ch,1+floor(Pre_control_W(i,1)*Fs):floor(Pre_control_W(i,2)*Fs))',params),2),1);
        Pre_stim_theta(a,i) = sum(mean(mtspectrumc(out{a}.data(Ch,1+floor(Pre_stim_W(i,1)*Fs):floor(Pre_stim_W(i,2)*Fs))',params),2),1);
        On_control_theta(a,i) = sum(mean(mtspectrumc(out{a}.data(Ch,1+floor(On_control_W(i,1)*Fs):floor(On_control_W(i,2)*Fs))',params),2),1);
        On_stim_theta(a,i) = sum(mean(mtspectrumc(out{a}.data(Ch,1+floor(On_stim_W(i,1)*Fs):floor(On_stim_W(i,2)*Fs))',params),2),1);
        Delta_stim_theta(a,i) = On_stim_theta(a,i)-Pre_stim_theta(a,i);
        Delta_control_theta(a,i) = On_control_theta(a,i)-Pre_control_theta(a,i);
    end
end

%% Calculating Threshold (IIS) for each channel
WW = 0.5;
MW = 0.1;
S_th = BO_IIS_Threshold(out,WW,MW,Fs);

%% IIS detection
%1) huge low-freq band power
clear IIS_detected
for i=1:1:length(out)
    IIS_detected{i} = BO_IIS_detect_power(out{i}.data,S_th,0.5,0.1,2000);
end
%2) 

%% Find overlap between each segment and IIS detected
% Pre_control_W
% On_control_W
% Pre_stim_W
% On_stim_W
% Pre_control_IIS
Pre_control_IIS = [];
On_control_IIS = [];
Pre_stim_IIS = [];
On_stim_IIS = [];
for i=1:1:length(out)
    for C=1:1:16
        Pre_control_IIS{i,C} = BO_IIS_detect_segment(IIS_detected{i}.time_Sp_final{C},Pre_control_W);
        On_control_IIS{i,C} = BO_IIS_detect_segment(IIS_detected{i}.time_Sp_final{C},On_control_W);
        Pre_stim_IIS{i,C} = BO_IIS_detect_segment(IIS_detected{i}.time_Sp_final{C},Pre_stim_W);
        On_stim_IIS{i,C} = BO_IIS_detect_segment(IIS_detected{i}.time_Sp_final{C},On_stim_W);
    end
end

for i=1:1:length(out)
    for C=1:1:16
        Stim_IIS{i,C} = [];
        Control_IIS{i,C} = [];
        for j=1:1:length(Pre_control_IIS{i,C})
            Stim_IIS{i,C} = [Stim_IIS{i,C} Pre_stim_IIS{i,C}{j} On_stim_IIS{i,C}{j}];
            Control_IIS{i,C} = [Control_IIS{i,C} Pre_control_IIS{i,C}{j} On_control_IIS{i,C}{j}];
        end
        Stim_IIS{i,C} = unique(Stim_IIS{i,C});
        Control_IIS{i,C} = unique(Control_IIS{i,C});
    end
end

%% Model IIS free
Pre_control_theta_raw = [];
On_control_theta_raw = [];
Pre_stim_theta_raw = [];
On_stim_theta_raw = [];
Pre_control_theta_pure = [];

On_control_theta_pure = [];
Pre_stim_theta_pure = [];
On_stim_theta_pure = [];

for a=1:1:length(out)
    for i=1:1:N_seg 
        for C=1:1:16
            Pre_control_theta_raw(i,C,:) = mtspectrumc(out{a}.data(C,1+floor(Pre_control_W(i,1)*Fs):floor(Pre_control_W(i,2)*Fs))',params);
            On_control_theta_raw(i,C,:) = mtspectrumc(out{a}.data(C,1+floor(On_control_W(i,1)*Fs):floor(On_control_W(i,2)*Fs))',params);
            if ~isempty(find(Control_IIS{a,C}==i))
                Pre_control_theta_raw(i,C,:) = NaN;
                On_control_theta_raw(i,C,:) = NaN;
            end
            
            Pre_stim_theta_raw(i,C,:) = mtspectrumc(out{a}.data(C,1+floor(Pre_stim_W(i,1)*Fs):floor(Pre_stim_W(i,2)*Fs))',params);
            On_stim_theta_raw(i,C,:) = mtspectrumc(out{a}.data(C,1+floor(On_stim_W(i,1)*Fs):floor(On_stim_W(i,2)*Fs))',params);
            if ~isempty(find(Stim_IIS{a,C}==i))
                Pre_stim_theta_raw(i,C,:) = NaN;
                On_stim_theta_raw(i,C,:) = NaN;
            end                
            Pre_control_theta_pure(a,i) = squeeze(sum(nanmean(Pre_control_theta_raw(i,:,:),2),3));
            Pre_stim_theta_pure(a,i) = squeeze(sum(nanmean(Pre_stim_theta_raw(i,:,:),2),3));
            On_control_theta_pure(a,i) = squeeze(sum(nanmean(On_control_theta_raw(i,:,:),2),3));
            On_stim_theta_pure(a,i) = squeeze(sum(nanmean(On_stim_theta_raw(i,:,:),2),3));
            Delta_stim_theta_pure(a,i) = On_stim_theta_pure(a,i)-Pre_stim_theta_pure(a,i);
            Delta_control_theta_pure(a,i) = On_control_theta_pure(a,i)-Pre_control_theta_pure(a,i);
        end
    end
end

%% New Observations
% fitting and find X (Pre) range -> area
for a=1:1:length(out)
    p_control(a,:) = polyfit(Pre_control_theta(a,:),Delta_control_theta(a,:),1);
    p_stim(a,:) = polyfit(Pre_stim_theta(a,:),Delta_stim_theta(a,:),1);
    range_X(a,:) = [min([squeeze(Pre_control_theta(a,:)) squeeze(Pre_stim_theta(a,:))]) max([squeeze(Pre_control_theta(a,:)) squeeze(Pre_stim_theta(a,:))])];
    min(length(find(isnan(Pre_control_theta_pure(a,:))==0)),length(find(isnan(Pre_stim_theta_pure(a,:))==0)))
    if min(length(find(isnan(Pre_control_theta_pure(a,:))==0)),length(find(isnan(Pre_stim_theta_pure(a,:))==0)))>4
        xhere = Pre_control_theta_pure(a,:);
        yhere = Delta_control_theta_pure(a,:);
        xhere(isnan(xhere)) = [];
        yhere(isnan(yhere)) = [];
        p_control_pure(a,1:2) = polyfit(xhere,yhere,1);
        xhere = Pre_stim_theta_pure(a,:);
        yhere = Delta_stim_theta_pure(a,:);
        xhere(isnan(xhere)) = [];
        yhere(isnan(yhere)) = [];
        p_stim_pure(a,:) = polyfit(xhere,yhere,1);
    else
        p_control_pure(a,1:2) = NaN;
        p_stim_pure(a,1:2) = NaN;
    end
    range_X_pure(a,:) = [min([squeeze(Pre_control_theta_pure(a,:)) squeeze(Pre_stim_theta_pure(a,:))]) max([squeeze(Pre_control_theta_pure(a,:)) squeeze(Pre_stim_theta_pure(a,:))])];
end
% find 2nd objective function = area

for a=1:1:length(out)
    m1_control(a) = BO_IIS_getarea(p_control(a,:),range_X(a,:));
    m1_stim(a) = BO_IIS_getarea(p_stim(a,:),range_X(a,:));
    m1_control_pure(a) = BO_IIS_getarea(p_control_pure(a,:),range_X_pure(a,:));
    m1_stim_pure(a) = BO_IIS_getarea(p_stim_pure(a,:),range_X_pure(a,:));
    m2(a) = m1_stim(a)-m1_control(a);
    m2_pure(a) = m1_stim_pure(a) - m1_control_pure(a);
end

figure
plot(m2,'b')
hold on
plot(m2_pure,'r')

%% Model fitting and plot
clear gp_model
var = {'pulse_frequency_train','pulse_frequency_pulse'};
stim_table(:,2) = experiment_table.pulse_frequency_train;
stim_table(:,1) = experiment_table.pulse_frequency_pulse;
OF = m2_pure;
nonNANI = find(~isnan(OF));
lower = [35 5];
upper = [100 11];
gp_model = opto_gp_object();
gp_model.initialize_data(stim_table(nonNANI,:),OF(nonNANI)',lower, upper);
y = gp_model.predict(gp_model.t);
% y = reshape(y,100,100);
[dum Index] = max(y);
[dum Index_zero] = min(abs(y));

figure
    gp_model.plot_mean;
    colormap('jet')
    [a b] = ind2sub([100 100], Index);
    param = gp_model.t(Index,:)
    param_zero = gp_model.t(Index_zero,:)
%% 
figure
plot(Pre_control_theta,Delta_control_theta,'b.')
hold on
plot(Pre_stim_theta,Delta_stim_theta,'r.')

Pre_control_theta_pure = Pre_control_theta;
Pre_control_theta_pure(Control_IIS) = [];
Delta_control_theta_pure = Delta_control_theta;
Delta_control_theta_pure(Control_IIS) = [];

Pre_stim_theta_pure = Pre_stim_theta;
Pre_stim_theta_pure(Stim_IIS) = [];
Delta_stim_theta_pure = Delta_stim_theta;
Delta_stim_theta_pure(Stim_IIS) = [];

figure
plot(Pre_control_theta_pure,Delta_control_theta_pure,'b.')
hold on
plot(Pre_stim_theta_pure,Delta_stim_theta_pure,'r.')
