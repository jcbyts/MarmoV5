function I = buildLineTexture(hNoise, varargin)
% build line texture for measuring impact of tremor
% I = buildLineTexture(hNoise)
% Inputs:
%   hNoise <struct>
%       dims
%       start
%       lightWidth
%       darkWidth
%
% Output:
%   I <double> images of dimensions hNoise.dims
% 
I = zeros(hNoise.dims);

% build index
n = hNoise.dims((hNoise.orientation/90) +1);
on = false(n,1);
ison = hNoise.start;
lastswitch = 0;

for i = 1:n

    if ison
        on(i) = true;
        if (i-lastswitch) >= hNoise.lightWidth
            ison = false;
            lastswitch = i;
        end
    else
        
        if (i-lastswitch) >= hNoise.darkWidth
            ison = true;
            lastswitch = i;
        end
            
    end

    
end

switch hNoise.orientation
    
    case 0
        
        I(on,:) = 1;
        
    case 90
        I(:,on) = 1;
end