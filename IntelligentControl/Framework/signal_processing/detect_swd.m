function [ swd_onset_times ] = detect_swd( signal, fs, threshold )

cwt(signal,1:32,'morl',1/2000, 'scal');

% plot(smooth(abs(sum(w_CA3(3:11,:)))))
end

