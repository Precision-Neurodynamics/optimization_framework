function stim_signal = opto_generate_standard(f_sample,f_stim_P , duration, amplitude, PWP, n_channels  )
%   Detailed explanation goes here

if PWP>1-10^-10
    error('Wrong pulse width too big!')
end
t   = 0:1/f_sample:duration ;
dP = PWP/2:1/f_stim_P:duration+PWP/2;
yP = amplitude*pulstran(t,dP,'rectpuls',PWP);

stim_signal = yP;
stim_signal = repmat(stim_signal,n_channels,1);

end
