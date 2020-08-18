function  [stim_interp theta_interp] = plot_control(dir)
close all
setpoint            = [.07 .07];
setpoint_time       = [0 0];
kd = 0;
ki = 0;
kp = 45;
stimulation_duration = 0.4;
dir_control         = 'results/ARN045/pid_control/pid_control_theta_NOR2-ARN045_20160630T182854/';
dir_control_2   	= 'results/ARN045/pid_control/pid_control_theta_3.1_3s_window-ARN045_20160623T171522/';

o_table         = readtable([dir_control 'objective_function.csv'],'readvariablenames', 0);
stim_table      = readtable([dir_control 'stimulation_table.csv']);

theta_val       = o_table.Var2;
theta_time      = o_table.Var1 - o_table.Var1(1);
stim_time       = stim_table.stimulation_uid -o_table.Var1(1);

fs = 1/.001;
t               = 0:1/fs:stim_time(end)+1;
theta_interp    = interp1(theta_time,theta_val,t);
stim_interp     = zeros(size(t));

for c1 = 2:length(stim_time)
    [~,a] = min(abs(t-stim_time(c1)));
    stim_interp(a:a+stimulation_duration*fs) = stim_table.stimulation_amplitude_a(c1)*2;
end

subplot(2,1,1)
plot(t,theta_interp)
xlim([t(1) t(end)])
ylabel('Theta');

hold on 
n_setpoints = size(setpoint,2);
for c1 = 1:n_setpoints-1
    
    if ~isnan(setpoint(c1))
        plot([setpoint_time(c1)  setpoint_time(c1+1)], [setpoint(c1) setpoint(c1)], 'k--'); 
    else
        plot([setpoint_time(c1)  t(end)], [setpoint(c1) setpoint(c1)], 'k--'); 
    end
    
end

plot([setpoint_time(1)  t(end)], [setpoint(1) setpoint(1)], 'k--'); 
ylabel('Theta');
legend({'Optimized', 'Setpoint'});
xlabel('Seconds');
title(sprintf('%.2fs Stimulation (Kp = %.2f, Ki = %.2f, Kd = %.2f)', stimulation_duration, kp, ki,kd));

subplot(2,1,2)
plot(t, stim_interp);
xlabel('Seconds');
ylabel('Pulse Amplitude (V)');
xlim([t(1) t(end)])
theta_interp(isnan(theta_interp)) = 0;
stim_interp(isnan(stim_interp)) = 0;
% subplot(3,1,3)
% bar([mean(control_error) mean(no_control_error)]);
% hold on
% mean_control_error      = mean(control_error);
% mean_no_control_error   = mean(no_control_error);
% ci_control_error       = std(control_error)/sqrt(size(control_error,1))*1.96;
% ci_no_control_error    = std(no_control_error)/sqrt(size(no_control_error,1))*1.96;
% 
% plot([1 1],[mean_control_error-ci_control_error mean_control_error+ci_control_error ], 'linewidth', 2, 'color', 'k')
% plot([2 2],[mean_no_control_error-ci_no_control_error mean_no_control_error+ci_no_control_error ], 'linewidth', 2, 'color', 'k')
% ax = gca;
% ax.XTickLabel = {'Optimized', 'Control'};
% hold on
% ylabel('Error');
% xlabel(sprintf('P-value = %.4f', ranksum(control_error, no_control_error, 'tail', 'right')))
% xlim([0 3])

end

