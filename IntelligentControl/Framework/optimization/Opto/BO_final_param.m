% clear gp_model
% folder = 'C:\Users\TDT\Documents\IntelligentControl\results\EPI033\bayesian_optimization\Train_50I-test-EPI033_20190404T171127';
% stim_table = csvread(strcat(folder,'\','parameter.csv'));
% OF_1 = csvread(strcat(folder,'\','objective_function.csv'));
% OF = OF_1(:,3);
% 
% %fitmax
% if exist(strcat(folder,'\','second_objective_function.csv'))
% OF_2 = csvread(strcat(folder,'\','second_objective_function.csv'));
% OF_2 = OF_2(:,3);
% OF = OF_2;
% end
% 
% lower = [35 5];
% upper = [100 11];
% % lower = [5 2];
% % upper = [80 10];
% 
% % lower = [4.1 5 2];
% % upper = [5 42 10];
% 
% % Pre_state = csvread(strcat(folder,'\','state_function.csv'));
% % Pre_state = Pre_state(:,:);
% n_vars = size(stim_table,2);
% % % stim_table(15,:) = [];
% % % OF(15,:) = [];
% % % OF = second_metric';
% % todel = 4;
% % stim_table(todel,:) = [];
% % OF(todel) = [];
% N_trial = size(OF,1);
% 
% % N_trial = N_trial-1;
% % N_trial = 23;
% gp_model = opto_gp_object();
% gp_model.initialize_data(stim_table(1:N_trial,:),OF(1:N_trial),lower, upper);
% gp_temp = gp_model;
% % gp_model.acquisition_function = 'EI';
user = 2;
if user == 1
    user_define_length = 36;
else
    user_define_length = length(gp_temp.y_data);
end
gp_temp.x_data = gp_temp.x_data(1:user_define_length,:);
gp_temp.y_data = gp_temp.y_data(1:user_define_length,:);
% todel = [4 13 15 38];
todel = [] ;
gp_temp.y_data(todel,:) = [];
gp_temp.x_data(todel,:) = [];

y = gp_temp.predict(gp_temp.t);
% y = reshape(y,100,100);
[dum Index] = max(y);
[dum Index_min] = min(y);
[dum Index_zero] = min(abs(y));
if gp_temp.n_vars == 2
    figure
    gp_temp.plot_mean;
    [a b] = ind2sub([100 100], Index);
    param = gp_temp.t(Index,:)
    param_min = gp_temp.t(Index_min,:)
    param_zero = gp_temp.t(Index_zero,:)
elseif gp_temp.n_vars == 3
    [a b c] = ind2sub([100 100 100], Index);
%     param = gp_model.discrete_aquisition_function(2,0.01)
    param = gp_temp.t(Index,:)
    
end

