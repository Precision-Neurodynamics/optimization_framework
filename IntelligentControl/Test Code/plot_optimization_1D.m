function  plot_optimization_1D
close all;
optimization_home   = 'results\ARN045\cross_entropy_frequency_theta_power_delta_minmization\cross_entropy_optimization_frequency_theta_power_delta_minmization-ARN045_20160609T102517\';
control_home        = 'results\ARN045\cross_entropy_frequency_theta_power_delta_minmization\cross_entropy_optimization_frequency_theta_power_delta_control-ARN045_20160609T135345\';

stimulation_table               = readtable([optimization_home 'stimulation_table.csv']);
optimization_parameters         = csvread([optimization_home 'parameter.csv']);
optimized_objective_function    = csvread([optimization_home 'objective_function.csv']);
control_objective_function      = csvread([control_home 'objective_function.csv']);

samples_per_cycle   = 100;
n_elite             = 10;
n_samples           = min(size(optimized_objective_function,1), size(control_objective_function,1));

% Plot elite/non-elite samples 
subplot(3,1,1); hold on;

for c1 = 1 : n_samples/ samples_per_cycle -1
        
    [~, objective_idx]   = sort(optimized_objective_function((c1-1)*samples_per_cycle + 1: c1*samples_per_cycle,2), 'descend');
    sample_freq = stimulation_table.pulse_frequency((c1-1)*samples_per_cycle + 1: c1*samples_per_cycle);
    
    non_elite_samples   = sample_freq(objective_idx(n_elite+1:end));
    elite_samples       = sample_freq(objective_idx(1:n_elite));
    
    scatter(ones(size(non_elite_samples))*c1, non_elite_samples, 'MarkerEdgeColor', [1 1 1]*.7, 'LineWidth', 1 )
    scatter(ones(size(elite_samples))*c1, elite_samples, 'MarkerEdgeColor', [1 0 0], 'SizeData', 200, 'Marker', 'X', 'linewidth', 2)
     
end

ylabel('Stimulation Frequency');

% Plot value of opjective function
for c1 = 1 : n_samples/ samples_per_cycle -1
    optimized_objective_mean(c1) = mean(optimized_objective_function((c1-1)*samples_per_cycle + 1: c1*samples_per_cycle,2));
    optimized_objective_std(c1) = std(optimized_objective_function((c1-1)*samples_per_cycle + 1: c1*samples_per_cycle,2))/sqrt(samples_per_cycle)*1.96;
    
    control_objective_mean(c1) = mean(control_objective_function((c1-1)*samples_per_cycle + 1: c1*samples_per_cycle,2));
    control_objective_std(c1) = std(control_objective_function((c1-1)*samples_per_cycle + 1: c1*samples_per_cycle,2))/sqrt(samples_per_cycle)*1.96;
end
xlim([.5 c1+0.5]);
subplot(3,1,2);
hold on
errorbar((1:c1)+.1, control_objective_mean, control_objective_std,'linewidth', 2, 'color', [.5 .5 .5]);
errorbar(1:c1, optimized_objective_mean, optimized_objective_std,'k-','linewidth', 2);
xlim([.5 c1+0.5]);
ylabel('Theta Power');

subplot(3,1,3);
hold on
plot(1:c1, optimization_parameters(1:c1, 2)- optimization_parameters(1:c1, 3), 'k-', 'linewidth', 2 )
plot(1:c1, optimization_parameters(1:c1, 2), 'r-', 'linewidth', 2 )
plot(1:c1, optimization_parameters(1:c1, 2)+ optimization_parameters(1:c1, 3), 'k-', 'linewidth', 2 )
ylabel('Search Distribution - Mean +/- STD (Hz)');
xlabel('Iteration (100 stimulations each)')
xlim([.5 c1+0.5]);
end

