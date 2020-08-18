function cost = mtspectrum_stationary_cost( P, cost_func, vivo_CA3_psd, vivo_CA1_psd, vivo_CA3, vivo_CA1, make_plot)

FS      = 2000;
FS_max  = 200;
FS_min  = 4;
n_layers = P(7);
focus_layer = ceil(P(7)/2);

synaptic_gain 				= P(1:3);
synaptic_time_constants 	= [100 30 350];
internal_connectivities 	= [135 108 33.75 33.75 40.5 13.5 108];
mass_connectivities 		= [P(4) P(5) P(6) P(8) P(9) n_layers];
stimulation_parameters		= [0 0 0 110 focus_layer-1];
simulation_parameters 		= [6 2000];

cost_1 = nan(1,10);
for c1 = 1:10
lfp = simulation_engine_mex(synaptic_gain, synaptic_time_constants    ...
           , internal_connectivities, mass_connectivities       ...
           , stimulation_parameters, simulation_parameters      ...
           );


silico_CA3 = lfp(:, focus_layer);
silico_CA1 = lfp(:, n_layers + focus_layer);

[silico_CA3_psd, ~, silico_CA1_psd, ~] ...
    = feval(cost_func, silico_CA3, FS, silico_CA1, FS, FS_min, FS_max, 1);

cost_CA3    = sum((silico_CA3_psd - vivo_CA3_psd).^2);
cost_CA1    = sum((silico_CA1_psd - vivo_CA1_psd).^2);

cost_1(c1)    = cost_CA3 + cost_CA1;

end
cost = mean(cost_1);
if make_plot
    
    subplot(3,1,1);
    plot(vivo_CA3);
    xlim([0 10000]);
    
    subplot(3,1,2);
    plot(silico_CA3);
    xlim([0 10000]);

    subplot(3,1,3);
    plot(vivo_CA3_psd);
    hold on
    plot(silico_CA3_psd)
    xlim([1 FS_max])
    hold off
    drawnow
%     subplot(2,3,4);
%     plot(vivo_CA1);
%     xlim([0 10000]);
%         
%     subplot(2,3,5);
%     plot(silico_CA1);
%     xlim([0 10000]);
% 
%     subplot(2,3,6);
%     plot(vivo_CA1_psd);
%     hold on
%     plot(silico_CA1_psd)
%     xlim([1 FS_max])
%     hold off
%     UB = [5     30      20      200.0   200     200   32];
%     subplot(3,3,7:9)
%     p = repmat(UB,70,1);
%     plot(population' ./ p)
end
end

