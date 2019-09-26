
function S = MarmoViewRigSettings
% TODO: This should, at a minumum, have a switch, case statement for
% different rigs

% For use with MarmoView version 3   
%
% Revised by JM 8/2018 to consolidate several new features and Dummy Screen
%
% This function contains all settings for a particular rig, this way, when
% a change is made to the rig, all settings files do not need to be
% updated. This function MUST be located in a directory set in the MATLAB
% path so that it can both be called by MarmoView (in MarmoView directory)
% and by settings functions (in the MarmoView/Settings directory). I
% suggest SupportFunctions.
%
% For example, if you change the monitor set up, you only change those
% monitor related variables here.

RigName = 'propixx';

switch RigName
    case 'Rig3'
        S.newera = true;         % use Newera juice pump
        S.eyetracker = 'arrington';
        S.arrington = true;      % use Arrington eye tracker
        S.DummyEye = false;       % use mouse instead of eye tracker
        S.solenoid = false;      % use solenoid juice delivery
        S.DummyScreen = false;   % don't use a Dummy Display
        S.EyeDump = true;        % store all eye position data
        S.DataPixx = true;
        
        S.monitor = 'BenQ-XL2411Z';         % Monitor used for display window
        S.screenNumber = 2;                 % Designates the display for task stimuli
        S.frameRate = 100; % 120;           % Frame rate of screen in Hz
        S.screenRect = [0 0 1920 1080];     % Screen dimensions in pixels
        S.screenWidth = 53;                 % Width of screen (cm)
        S.centerPix =  [960 540];           % Pixels of center of the screen
        S.guiLocation = [800 100 890 660];
        S.bgColour = 127; %127; %186;  % use 127 if gamma corrected
        
        S.screenDistance = 57;              % Distance of eye to screen (cm)
        S.pixPerDeg = PixPerDeg(S.screenDistance,S.screenWidth,S.screenRect(3));
   
    case 'ddpi'
        S.newera = false;         % use Newera juice pump
        S.eyetracker = 'ddpi';
        S.arrington = false;      % use Arrington eye tracker
        S.DummyEye = false;       % use mouse instead of eye tracker
        S.solenoid = false;      % use solenoid juice delivery
        S.DummyScreen = false;   % don't use a Dummy Display
        S.EyeDump = true;        % store all eye position data
        S.DataPixx = true;
        
        % setup screen
        S.monitor = 'BenQ-XL2411Z';         % Monitor used for display window
        S.screenNumber = 1;                 % Designates the display for task stimuli
        S.frameRate = 100; % 120;           % Frame rate of screen in Hz
        S.screenRect = [0 0 1920 1080];     % Screen dimensions in pixels
        S.screenWidth = 53;                 % Width of screen (cm)
        S.centerPix =  [960 540];           % Pixels of center of the screen
        S.guiLocation = [800 100 890 660];
        S.bgColour = 127; %127; %186;  % use 127 if gamma corrected
        
        S.screenDistance = 57;              % Distance of eye to screen (cm)
        S.pixPerDeg = PixPerDeg(S.screenDistance,S.screenWidth,S.screenRect(3));
        
    case 'propixx'
        S.newera = true;         % use Newera juice pump
        S.eyetracker = 'ddpi';
        S.arrington = true;      % use Arrington eye tracker
        S.DummyEye = false;       % use mouse instead of eye tracker
        S.solenoid = false;      % use solenoid juice delivery
        S.DummyScreen = false;   % don't use a Dummy Display
        S.EyeDump = true;        % store all eye position data
        S.DataPixx = true;
        
        % setup screen
        S.monitor = 'PROPIXX';         % Monitor used for display window
        S.screenNumber = 1;                 % Designates the display for task stimuli
        S.frameRate = 120; % 120;           % Frame rate of screen in Hz
        S.screenRect = [0 0 1920 1080];     % Screen dimensions in pixels
        S.screenWidth = 70;                 % Width of screen (cm)
        S.centerPix =  [960 540];           % Pixels of center of the screen
        S.guiLocation = [800 100 890 660];
        S.bgColour = 127; %127; %186;  % use 127 if gamma corrected
        
        S.screenDistance = 87;              % Distance of eye to screen (cm)
        S.pixPerDeg = PixPerDeg(S.screenDistance,S.screenWidth,S.screenRect(3));
        
    otherwise % laptop development
        S.newera = false;
        S.solenoid = false;
        S.arrington = false;
        S.DummyEye = true;
        S.DummyScreen = true;
        S.EyeDump = false;
        S.DataPixx = false;
end
        
S.TimeSensitive = [];  % default, allow GUI updating in run func states
%***************************

if S.newera % this should be moved into rig specific parameters
    if IsWin
        S.pumpCom = 'COM9';                 % COM port the New Era syringe pump
    elseif IsLinux
%         S.pumpCom = '/dev/ttyS0';
        S.pumpCom = '/dev/ttyUSB0';
    end
    
    S.pumpDiameter = 20;                % internal diameter of the juice syringe (mm)
    S.pumpRate = 20;                     % rate to deliver juice (ml/minute)
    S.pumpDefVol = 10;                % default dispensing volume (ml)
end

if S.DummyScreen

   S.monitor = 'Laptop';         % Monitor used for display window
   S.screenNumber = 0;                 % Designates the display for task stimuli
   S.frameRate = 60;                  % Frame rate of screen in Hz
   S.screenRect = [0 0 960 540];     % Screen dimensions in pixels
   S.screenWidth = 15;                 % Width of screen (cm)
   S.centerPix =  [480 270];           % Pixels of center of the screen
   S.guiLocation = [1000 100 890 660];
   S.bgColour = 127; % 186 if not gamma corrected

   S.screenDistance = 14; %57;         % Distance of eye to screen (cm)
   S.pixPerDeg = PixPerDeg(S.screenDistance,S.screenWidth,S.screenRect(3));
   

end

S.gamma = 2.2;                      % Single value gamma correction, this
                                    % works for BenQ, others might need a
                                    % table based correction
