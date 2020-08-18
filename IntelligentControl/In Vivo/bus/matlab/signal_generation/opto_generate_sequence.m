function stim_signal = opto_generate_sequence(f_sample,duration, amplitude,frequency, PWP, n_channels  )
%   Detailed explanation goes here

if PWP>1-10^-10
    error('Wrong pulse width too big!')
end

if length(frequency)>1 && length(amplitude)>1 && length(amplitude) ~=length(frequency)
    error('Wrong length of the sequence')
end

Nseg = length(frequency);
t   = 0:1/f_sample:duration;
tstart = 1:round(duration/Nseg*f_sample)+1:round(duration/Nseg*f_sample)*Nseg+1;
stim_signal = [];

for i=1:1:Nseg
    there = round(duration/Nseg)*(i-1):1/f_sample:round(duration/Nseg)*i;
    dP = there(1)+PWP/2:1/frequency(i):there(1)+round(duration/Nseg)-PWP/2;
    stim_signal = [stim_signal amplitude(i) * pulstran(there,dP,'rectpuls',PWP)];        
end
endpoint = floor(f_sample*duration);

stim_signal(endpoint-10:max(length(stim_signal),endpoint)) = 0;
if length(stim_signal)>endpoint
    stim_signal(endpoint:end) = [];
end
    
% 
% f1 = 7;
% f2 = 35;
% A1 = 2;
% A2 = 2;
% y1 = A1* sin((2*pi)*f1*t);
% y2 = A2* sin((2*pi)*f2*t);
% stim_signal = y1+y2;

% dP = PWP/2:1/f_stim_P:duration+PWP/2;
% yP = amplitude*pulstran(t,dP,'rectpuls',PWP);
% 
% stim_signal = yP;
% stim_signal = repmat(stim_signal,n_channels,1);

end
