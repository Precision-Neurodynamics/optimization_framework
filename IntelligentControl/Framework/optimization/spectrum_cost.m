function varargout = spectrum_cost(varargin)
%
% [psd_1 f_1 psd_2 f_2 ...] = ...
% spectrum_cost(signal_1, fs_1, signal_2, fs_2, fs_min, fs_max, normalize)
%

normalize       = varargin{nargin};

params.tapers   = [5 9];
fs_min          = varargin{nargin - 2};
fs_max          = varargin{nargin - 3};
varargout       = cell(1, nargin-3);

for c1 = 1:2:nargin-3
    signal          = varargin{c1};
    signal          = signal - mean(signal);
    params.Fs       = varargin{c1 + 1};
    [psd, f]        = mtspectrumc(signal, params );
    
    [~, fs_max_idx] = min(abs(f - fs_max));
    [~, fs_min_idx] = min(abs(f - fs_min));
    
    f   = f(fs_min_idx:fs_max_idx);
    psd = psd(fs_min_idx:fs_max_idx);
    
    if normalize
        psd  = psd/max(psd);
    end
    
    varargout{c1}   = psd;
    varargout{c1+1} = f;
end
end