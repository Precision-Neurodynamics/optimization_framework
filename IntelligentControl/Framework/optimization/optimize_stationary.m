
clc; clear all; 

SID         = 8;
FS          = 2000;
FS_min      = 4;
FS_max      = 200;
cost_func   = 'spectrum_cost';

[ vivo_CA3, vivo_CA1 ] = data_extraction_testbed(SID);

[vivo_CA3_psd, ~, vivo_CA1_psd, ~] ...
    = spectrum_cost(vivo_CA3, FS, vivo_CA1, FS, FS_min, FS_max, 1);

options                 = gaoptimset;
options.PlotFcns        = @gaplotbestf;
options.PlotInterval    = 1;
options.Generations     = 10;
options.UseParallel     = 0;
options.Vectorized      = 'off';
options.Display         = 'iter';

if strcmp(getenv('OS'), 'Windows_NT')
   options.UseParallel     = 1;
end

%%%%%%%%
% Simulation
%%%%%%%%

% p  [1.A   2.B     3.G     4.Sc    5.Fb    6.Lat   7.Lay   8.Stim
LB = [0.0   0.0     0.0     0       0       0       4       0       0];
UB = [5     30      20      200.0   200     200     32      1       1];
[new_P,fval,exitflag,output,population,scores] = ...
    ga({@mtspectrum_stationary_cost, cost_func, vivo_CA3_psd, vivo_CA1_psd, vivo_CA3, vivo_CA1, 1},...
    9 ,[], [],[],[], LB, UB, [] , [7], options);  

% s_file = '/Users/mconnolly/Google Drive/Research/Grants/URC 2016/Optimization_Solutions/';
% save(sprintf('%s/SID_%d_Gen_%d.mat', s_file, SID, options.Generations),'new_P','population', 'scores')

figure;
mtspectrum_stationary_cost(new_P, cost_func, vivo_CA3_psd, vivo_CA1_psd, vivo_CA3, vivo_CA1, 1)
% subplot(3,3,7:9)
% p = repmat(UB,70,1);
% plot((population ./ p)')

% SID 1 new_P = [1.9496 1.4184 7.1823 103.9433 122.4308 27.5303 27.0000]

% SID 2 new_P = [1.2129 0.2910 5.9567 184.2288 75.0319 20.8811 22.0000]