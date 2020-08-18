function stim_signal = opto_generate_train(f_sample, f_stim_T,f_stim_P , duration, amplitude, PWT, PWP, n_channels  )
%   Detailed explanation goes here

if duration<10
    t   = 0:1/f_sample:duration ;
    dP = 0:1/f_stim_P:duration;
    if PWP == 1
        yP = ones(1,length(t));
    else
        yP = pulstran(t,dP,'rectpuls',PWP);
    end
    if PWT == 1
        yT = amplitude*ones(1,length(yP));
    else
        dT = PWT/2:1/f_stim_T:duration+ PWT/2;
        yT = amplitude*pulstran(t,dT,'rectpuls',PWT);
    end
    stim_signal = yT.*yP;
    stim_signal = repmat(stim_signal,n_channels,1);
else % if duration>10
    temp_duration = 5;
    N_rep = floor(duration/temp_duration);
    Sec_remain = round(duration - N_rep*temp_duration);
    
    t   = 0:1/f_sample:temp_duration ;
    dP = 0:1/f_stim_P:temp_duration;
    if PWP == 1
        yP = ones(1,length(t));
    else
        yP = pulstran(t,dP,'rectpuls',PWP);
    end
    if PWT == 1
        yT = amplitude*ones(1,length(yP));
    else
        dT = PWT/2:1/f_stim_T:temp_duration+ PWT/2;
        yT = amplitude*pulstran(t,dT,'rectpuls',PWT);
    end
    stim_signal_temp = yT.*yP;
    stim_signal_temp = repmat(stim_signal_temp,n_channels,N_rep);
    
    temp_duration = Sec_remain;
    t   = 0:1/f_sample:temp_duration ;
    dP = 0:1/f_stim_P:temp_duration;
    if PWP == 1
        yP = ones(1,length(t));
    else
        yP = pulstran(t,dP,'rectpuls',PWP);
    end
    if PWT == 1
        yT = amplitude*ones(1,length(yP));
    else
        dT = PWT/2:1/f_stim_T:temp_duration+ PWT/2;
        yT = amplitude*pulstran(t,dT,'rectpuls',PWT);
    end
    
    stim_signal = [stim_signal_temp repmat(yT.*yP,n_channels,1)];
    
    
end
end
