function stim_signal = opto_generate_arbitrary(f_sample,f_stim_P , duration, amplitude, PWP, n_channels  )
%   Detailed explanation goes here

if PWP>1-10^-10
    error('Wrong pulse width too big!')
end


t   = 0:1/f_sample:duration ;
f1 = 7;
f2 = 35;
A1 = 2;
A2 = 2;
y1 = A1* sin((2*pi)*f1*t);
y2 = A2* sin((2*pi)*f2*t);
stim_signal = y1+y2;

% dP = PWP/2:1/f_stim_P:duration+PWP/2;
% yP = amplitude*pulstran(t,dP,'rectpuls',PWP);
% 
% stim_signal = yP;
% stim_signal = repmat(stim_signal,n_channels,1);

end
