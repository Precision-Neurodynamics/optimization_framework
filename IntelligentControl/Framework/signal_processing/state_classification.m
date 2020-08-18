function average_accuracy = state_classification(svm_data, group_data, c)
% Classifier to determine whether the stimulation will result in
% seizure/afterdischarges

class_loo = nan(size(svm_data,1),1);

% Leave-one-out loop
for c1 = 1:size(svm_data,1)
    
    f_data_loo       = svm_data([1:c1-1 c1+1:length(group_data)],:);
    group_loo        = group_data([1:c1-1 c1+1:length(group_data)]);

    SVMStruct        = svmtrain(f_data_loo, group_loo, 'BoxConstraint', c);
    class_loo(c1)    = svmclassify(SVMStruct, svm_data(c1,:));
    
end

end

