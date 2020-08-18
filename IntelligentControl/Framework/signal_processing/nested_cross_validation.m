function [ average_accuracy class_data] = nested_cross_validation( svm_data, group_data, kernel_function )

class_data = nan(size(svm_data,1),1);

% Leave-one-out loop
for c1 = 1:size(svm_data,1)
    
    f_data_loo       = svm_data([1:c1-1 c1+1:length(group_data)],:);
    group_loo        = group_data([1:c1-1 c1+1:length(group_data)]);

    [c sigma]        = parameter_tuning(f_data_loo, group_loo, kernel_function);
    
    if strcmp(kernel_function, 'rbf')
        SVMStruct       = svmtrain(f_data_loo, group_loo, 'BoxConstraint', c, ...
                       'kernel_function','rbf', 'rbf_sigma', sigma);
    else
        SVMStruct        = svmtrain(f_data_loo, group_loo,'autoscale', 'true', 'BoxConstraint', c,'kernel_function', kernel_function);
    end
    class_data(c1)   = svmclassify(SVMStruct, svm_data(c1,:));
    
end
[group_data'  class_data];

class_data(group_data == 1);
average_accuracy = sum(group_data == class_data')/size(class_data',2);

end

%   for each element in data[40]
%       outer_test[1]
%       outer_train[39]
% 
%       For each parameter c in constraints
%           for each element in outer_train
%               inner_train[38]
%               inner_test[1]
%               svmtrain(inner_train[38], c)
%               svmclassify(inner_test[1])
%               calulate accuracy
%           end for
%           calculate average accuracy
%           evaluate performance of c
%       end for
% 
%       determine best parameter c*
% 
%       svmtrain(outer_train[39], c*)
%       svmclassify(outer_test[1])
%       calculate accuracy
%   end for
%   calculate average accuracy

