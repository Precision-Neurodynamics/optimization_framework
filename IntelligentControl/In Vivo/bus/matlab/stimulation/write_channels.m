function write_channels(TD, varargin )

if mod(nargin, 2) ~= 0
    return;
end

for c1 = 1:2:nargin
    write_channel(TD, varargin{c1}, varargin{c1+1} )
end
  

end

