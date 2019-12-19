function pixPerDeg = PixPerDeg(screenDistance,screenWidth,pixelWidth)

% This function finds the pixels per degree of a monitor of screenWidth
% from a distance of screenDistance (units can be arbitray, but must be the
% same) for a monitor with pixelWidth number of pixels in screenWidth.
% 
% If only screenDistance is given then screenWidth (in cm) and pixelWidth 
% will be the values of the BenQ XL2411 monitor run at 1080p

if ~exist('screenWidth','var'); screenWidth = 53;   end
if ~exist('pixelWidth','var');  pixelWidth = 1920;  end

ScreenDeg = 2*atan2(screenWidth/2,screenDistance) * (180/pi);
pixPerDeg = pixelWidth/ScreenDeg;