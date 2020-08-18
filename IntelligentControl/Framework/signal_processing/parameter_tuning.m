function [optimal_c, optimal_sigma] = parameter_tuning(svm_data, group_data, kernel_function)
%PARAMETER_TUNING Summary of this function goes here
%   Detailed explanation goes here

constraints         = 0.1:.1:1;
sigma               = 1;%0.1:.1:2;
average_accuracy    = nan(size(constraints,2), size(sigma,2));

for c1 = 1:size(constraints,2)
    for c2 = 1:size(sigma,2)
        average_accuracy(c1,c2) = cross_validation(svm_data, group_data, constraints(c1), sigma(c2), kernel_function);
    end
end
[~, optimal_c_idx]      = max(max(average_accuracy,[],2),[], 1);
optimal_c               = constraints(optimal_c_idx);
[~, optimal_sigma_idx]  = max(max(average_accuracy,[],1),[], 2);
optimal_sigma           = sigma(optimal_sigma_idx);
end

