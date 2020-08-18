function [ output_args ] = sp( input_args )

t = 0:0.001:2;
x = chirp(t,150,1,300);

f=0:0.1:150; % example

 [y,f,t,P]=spectrogram(x,10,6,f,1E3);
 figure; surf(t,f,10*log10(abs(P)),'EdgeColor','none');
 view(0,90);
 xlabel('times s');
 ylabel(' frequency Hz');
 
 x1=500;
 x2=1000;
 F=P(x1:x2,:);
 figure; surf(t, F, 20*log10(F) ,'EdgeColor','none');
 view(0,90);

end

