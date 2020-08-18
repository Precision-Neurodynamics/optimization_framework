

function BO_final_3param(gp_model)

y = gp_model.predict(gp_model.t);
% y = reshape(y,100,100);
[dum Index] = max(y);
[dum Index_min] = min(y);
[dum Index_zero] = min(abs(y));

[a b c] = ind2sub([100 100 100], Index);
%     param = gp_model.discrete_aquisition_function(2,0.01)
    param = gp_model.t(Index,:)
    param_min = gp_model.t(Index_min,:)
    param_zero = gp_model.t(Index_zero,:)
    
end