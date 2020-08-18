function  plot_ce_results
%PLOT_CE_RESULTS Summary of this function goes here
%   Detailed explanation goes here
results_dir = 'results/cross_entropy_optimization-ARN038_20160414T192547/';

objective_function = csvread([results_dir 'objective_function.csv']);

over = mod(size(objective_function,1),100);
n_iterations = size(objective_function,1) - over;


groups = reshape(repmat(1:15,100,1), 1,1500);
for c1 = 1:n_iterations/100
     
end
end

