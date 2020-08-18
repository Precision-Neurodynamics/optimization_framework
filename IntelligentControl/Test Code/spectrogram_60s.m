function spectrogram_60s(data,Fs,Ch,fig_flag)
if ~exist('Fs')
    Fs = 24414.0625;
end

if ~exist('Ch')
    Ch = 1;
end

obj.params.Fs                           = Fs;
obj.params.tapers                       = [3 5];
obj.params.fpass                        = [4 80];


if isnumeric(Ch)
    d_to_spec(1,:) = mean(data(Ch,:),1);
    
elseif strcmp(Ch,'even')
    d_to_spec(1,:) = mean(data(2:2:16,:),1);
    
elseif strcmp(Ch,'odd')
    d_to_spec(1,:) = mean(data(1:2:15,:),1);
end
        
[S, t, f] = mtspecgramc(d_to_spec, [1 .25], obj.params);
if ~exist('fig_flag')
    figure
else
    figure(fig_flag)
end
plot_matrix(S,t,f);
colormap('jet')
        