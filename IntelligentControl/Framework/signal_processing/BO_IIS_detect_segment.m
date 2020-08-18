function IIS = BO_IIS_detect_segment(time_Sp_final,W)

if isempty(time_Sp_final)
    IIS = [];
else
N_seg = size(W,1);
for j=1:1:size(time_Sp_final,1)
    up = [];
    down = [];

    for i=1:1:N_seg
        if time_Sp_final(j,1) >= W(i,1) && time_Sp_final(j,1) <= W(i,2) && isempty(up)
            up = i;
        end
        if time_Sp_final(j,2) >= W(i,1) && time_Sp_final(j,2) <= W(i,2)
            down = i;
        end
    end
    if ~isempty(up)
        if ~isempty(down)
            IIS{j} = up:1:down;
        else
            IIS{j} = up:1:N_seg;
        end
    else
        IIS{j} = [];
    end
end
end