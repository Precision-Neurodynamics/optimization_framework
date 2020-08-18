
clc; clear all; 
SID = 2;
FS  = 2000;
[ vivo_CA3_pre, vivo_CA3_post, vivo_CA1_pre, vivo_CA1_post ] = data_extraction_testbed(SID);
params.Fs       = FS;
params.tapers   = [5 9];

[vivo_CA3_pre_psd] = mtspectrumc( vivo_CA3_pre, params );
[vivo_CA3_post_psd] = mtspectrumc( vivo_CA3_post, params );
[vivo_CA1_pre_psd] = mtspectrumc( vivo_CA1_pre, params );
[vivo_CA1_post_psd] = mtspectrumc( vivo_CA1_post, params );



options                 = gaoptimset;
options.PlotFcns        = @gaplotbestf;
options.PlotInterval    = 1;
options.Generations     = 10;
options.UseParallel     = 0;
options.Vectorized      = 'off';
options.Display         = 'iter';

%%%%%%%%
% Simulation
%%%%%%%%

% p  [A     B       G       Sc      Fb      Lat   Lay
LB = [0.0   0.0     0.0     0       0       0     4];
UB = [5     30      20      200.0   200     200   32];
[new_P,fval,exitflag,output,population,scores] = ...
    ga({@mtspectrum_cost,  vivo_CA3_pre_psd, vivo_CA1_pre_psd, vivo_CA3_post_psd, vivo_CA1_post_psd},...
    7 ,[], [],[],[], LB, UB, [] , [7], options);  


% SID 1 new_P = [1.9496 1.4184 7.1823 103.9433 122.4308 27.5303 27.0000]

% SID 2 new_P = [1.2129 0.2910 5.9567 184.2288 75.0319 20.8811 22.0000]