
function featout = TeNT_Grid_getFeatures_IIS(temp,W,Seizout,Chout,nameparam,MW,task,S_th,bs,os,as)
Fs = 2000;
params.Fs = Fs;
params.tapers = [3 5];
params.fpass = [3 300];
band = [3:1:99 100:2:198 200:4:296];
if ~exist('MW')
    MW = W;
end

%file load
% cd(Folder)
% filelist = dir;
j = 1;
% for i=1:1:length(filelist)
%     temp{i} = load(filelist{i});
% end
Ch_PSD = 1:1:16;
Ch_COH = 1:2:15;


% feature extraction start
j1 = 1;
j2 = 1;
realind = 1:1:length(temp);
realind(Seizout) = [];
MWIIS = 0.1;
WIIS = 0.5;
%%%%%%%% Sth cal %%%%%%%%%%
% S_th = BO_IIS_Threshold(temp,WIIS,MWIIS,2000);

%%%%%%%% Baseline, stimulation, after stim labeling %%%%%
% bs = 20;
% os = 20;
% as = 20;
IISW = 0:MWIIS:floor(size(temp{1},2)/Fs)-MWIIS;

for i = realind
    PSD = [];
    COH = [];
    PHI = [];
    Label = [];
    if strcmp(task,'grid')
        j1 = 1; % index initialization
        
        %%%%%%% IIS detect %%%%%%%
        IISW_flag(1:length(IISW),1) = 1;
        Cheff = 1:16;
        Cheff(Chout) = [];
        IIS_detected = BO_IIS_detect_power(temp{i}(Cheff,:),S_th(Cheff),WIIS,MWIIS,2000,0);
        for c1=1:1:length(Cheff)
            IIS{c1} = round(IIS_detected.time_Sp_final{c1},1);
            for c2=1:1:size(IIS{c1},1)
                startI = round(round(IIS{c1}(c2,1),2)/MWIIS)+1;
                endI = round(round(IIS{c1}(c2,2),2)/MWIIS);
                IISW_flag(startI:endI,1) = 0;
            end
        end
        %%% IISW_flag = IIS alltogether
        BS_flag = find(IISW_flag(1:bs/MWIIS) == 0);
        OS_flag = find(IISW_flag(bs/MWIIS+1:(os+bs)/MWIIS) == 0);
        AS_flag = find(IISW_flag((os+bs)/MWIIS+1:(os+bs+as)/MWIIS) == 0);
        
        tempBS = temp{i}(:,1:bs*Fs);
        tempOS = temp{i}(:,Fs*bs+1:Fs*(bs+os));
        tempAS = temp{i}(:,Fs*(bs+os)+1:Fs*(bs+os+as));
        
        %%% IIS removal
        for i1=1:1:length(BS_flag)
            tempBS(:,round(IISW(BS_flag(i1))*Fs)+1:round(IISW(BS_flag(i1)+1)*Fs)) = NaN;
        end
        for i1=1:1:length(OS_flag)
            tempOS(:,round(IISW(OS_flag(i1))*Fs)+1:round(IISW(OS_flag(i1)+1)*Fs)) = NaN;
        end
        for i1=1:1:length(AS_flag)
            tempAS(:,round(IISW(AS_flag(i1))*Fs)+1:round(IISW(AS_flag(i1)+1)*Fs)) = NaN;
        end
        todel = find(isnan(tempBS(1,:)));
        tempBS(:,todel) = [];
        todel = find(isnan(tempOS(1,:)));
        tempOS(:,todel) = [];
        todel = find(isnan(tempAS(1,:)));
        tempAS(:,todel) = [];
        
        %%% if bs/os/as are more than 5sec then cal features
        
        % bs first
        for L=1:1:3
            if L == 1
                datahere = tempBS;
            elseif L == 2
                datahere = tempOS;
            elseif L == 3
                datahere = tempAS;
            end
            clear Wind
            NW = floor((size(datahere,2)-Fs*W)/(Fs*MW))+1;
            if NW>0
                Wind(:,1) = 1:MW*Fs:MW*Fs*(NW-1)+1;
                Wind(:,2) = Wind(:,1)+W*Fs-1;
                
                for i2=1:1:NW
                    for c1=Ch_PSD
                        [PSD_raw f_PSD] = mtspectrumc(datahere(c1,Wind(i2,1):Wind(i2,2))',params);
                        %PSD
                        PSD_bin = nan(1,length(band));
                        for k=1:1:length(band)
                            band_use = [min(find(f_PSD>band(k))):max(find(f_PSD<band(k)+1))];
                            PSD_bin(k) = sum(PSD_raw(band_use))/length(band_use);
                            f_PSD_bin(k) = band(k); %just for checking
                        end
                        PSD(j1,c1,:) = PSD_bin;
                    end
                    %Coherence & Phase
                    for c1=Ch_COH
                        %             [PSD_raw f_PSD] = mtspectrumc(temp{i}.data(c1,(i2-1)*Fs*W+1:i2*Fs*W)',params);
                        [COH_raw, PHI_raw,~,~,~,f_COH] = coherencyc(datahere(c1,Wind(i2,1):Wind(i2,2))',datahere(c1+1,Wind(i2,1):Wind(i2,2))',params);
                        COH_bin = nan(1,length(band));
                        PHI_bin = nan(1,length(band));
                        for k=1:1:length(band)
                            band_use = [min(find(f_PSD>band(k))):max(find(f_PSD<band(k)+1))];
                            COH_bin(k) = sum(COH_raw(band_use))/length(band_use);
                            PHI_bin(k) = sum(PHI_raw(band_use))/length(band_use);
                        end
                        COH(j1,(c1-1)/2+1,:) = COH_bin;
                        PHI(j1,(c1-1)/2+1,:) = PHI_bin;
                    end
                    Label(j1) = L; %base:1/stim:2/post:3
                    j1 = j1+1;
                end
                
                PSD(:,Chout,:) = NaN;
                COH(:,ceil(Chout/2),:) = NaN;
            end
        end
        
        featout{i}.Label = Label;
    elseif strcmp(task,'seiz')
        j1 = 1; % index initialization
        
        %%%%%%% IIS detect %%%%%%%
        IISW_flag(1:length(IISW),1) = 1;
        Cheff = 1:16;
        Cheff(Chout) = [];
        IIS_detected = BO_IIS_detect_power(temp{i}(Cheff,:),S_th(Cheff),WIIS,MWIIS,2000,0);
        for c1=1:1:length(Cheff)
            IIS{c1} = round(IIS_detected.time_Sp_final{c1},1);
            for c2=1:1:size(IIS{c1},1)
                startI = round(round(IIS{c1}(c2,1),2)/MWIIS)+1;
                endI = round(round(IIS{c1}(c2,2),2)/MWIIS);
                IISW_flag(startI:endI,1) = 0;
            end
        end
        datahere = temp{i};
        %%% IIS removal
        IIS_flag = find(IISW_flag == 0);
        for i1=1:1:length(IIS_flag)
            datahere(:,round(IISW(IIS_flag(i1))*Fs)+1:round((IISW(IIS_flag(i1))+MWIIS)*Fs)) = NaN;
        end
        todel = find(isnan(datahere(1,:)));
        datahere(:,todel) = [];
        
        %%% Now feature cal
        clear Wind
        NW = floor((size(datahere,2)-Fs*W)/(Fs*MW))+1;
        
        if NW>0
            Wind(:,1) = 1:MW*Fs:MW*Fs*(NW-1)+1;
            Wind(:,2) = Wind(:,1)+W*Fs-1;
            
            for i2=1:1:NW
                for c1=Ch_PSD
                    [PSD_raw f_PSD] = mtspectrumc(datahere(c1,Wind(i2,1):Wind(i2,2))',params);
                    %PSD
                    PSD_bin = nan(1,length(band));
                    for k=1:1:length(band)
                        band_use = [min(find(f_PSD>band(k))):max(find(f_PSD<band(k)+1))];
                        PSD_bin(k) = sum(PSD_raw(band_use))/length(band_use);
                        f_PSD_bin(k) = band(k); %just for checking
                    end
                    PSD(j1,c1,:) = PSD_bin;
                end
                %Coherence & Phase
                for c1=Ch_COH
                    %             [PSD_raw f_PSD] = mtspectrumc(temp{i}.data(c1,(i2-1)*Fs*W+1:i2*Fs*W)',params);
                    [COH_raw, PHI_raw,~,~,~,f_COH] = coherencyc(datahere(c1,Wind(i2,1):Wind(i2,2))',datahere(c1+1,Wind(i2,1):Wind(i2,2))',params);
                    COH_bin = nan(1,length(band));
                    PHI_bin = nan(1,length(band));
                    for k=1:1:length(band)
                        band_use = [min(find(f_PSD>band(k))):max(find(f_PSD<band(k)+1))];
                        COH_bin(k) = sum(COH_raw(band_use))/length(band_use);
                        PHI_bin(k) = sum(PHI_raw(band_use))/length(band_use);
                    end
                    COH(j1,(c1-1)/2+1,:) = COH_bin;
                    PHI(j1,(c1-1)/2+1,:) = PHI_bin;
                end
                j1 = j1+1;
            end
            
            PSD(:,Chout,:) = NaN;
            COH(:,ceil(Chout/2),:) = NaN;
        end
    end
    %Save, one cell per one param
    featout{i}.PSD = PSD;
    featout{i}.COH = COH;
    featout{i}.PHI = PHI;
    featout{i}.param =nameparam;
    featout{i}.Chout = Chout;
    featout{i}.W = W;
    featout{i}.MW = MW;
end
