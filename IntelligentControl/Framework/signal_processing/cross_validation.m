function average_accuracy = cross_validation( svm_data, group_data, c, sigma, kernel_function )
%CROSS_VALIDATION Summary of this function goes here
%   Detailed explanation goes here

class_data = nan(1,size(svm_data,1));

% Leave-one-out loop
for c1 = 1:size(svm_data,1)
    
    f_data_loo       = svm_data([1:c1-1 c1+1:length(group_data)],:);
    group_loo        = group_data([1:c1-1 c1+1:length(group_data)]);

    if strcmp(kernel_function, 'rbf')
        SVMStruct       = svmtrain(f_data_loo, group_loo, 'BoxConstraint', c, ...
                       'kernel_function','rbf', 'rbf_sigma', sigma);
    else
        SVMStruct   	= svmtrain(f_data_loo, group_loo, 'autoscale', 'true', 'BoxConstraint', c, 'kernel_function', kernel_function);
    end
    
    class_data(c1)      = svmclassify(SVMStruct, svm_data(c1,:));
    
end

average_accuracy = sum(group_data == class_data)/size(class_data,2);
end

