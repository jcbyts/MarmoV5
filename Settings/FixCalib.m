function [S,P] = FixCalib

%%%%% NECESSARY VARIABLES FOR GUI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD THE RIG SETTINGS, THESE HOLD CRUCIAL VARIABLES SPECIFIC TO THE RIG,
% IF A CHANGE IS MADE TO THE RIG, CHANGE THE RIG SETTINGS FUNCTION IN
% SUPPORT FUNCTIONS
S = MarmoViewRigSettings;

% NOTE THE MARMOVIEW VERSION USED FOR THIS SETTINGS FILE, IF AN ERROR, IT
% MIGHT BE A VERSION PROBLEM
S.MarmoViewVersion = '5';

% PARAMETER DESCRIBING TRIAL NUMBER TO STOP TASK
S.finish = 20;

% PROTOCOL PREFIXS
S.protocol = 'FixCalib';
S.protocol_class = ['protocols.PR_',S.protocol];

% Define Banner text to identify the experimental protocol
S.protocolTitle = 'Fixation Eye Calibration (random locations)';

%******** Similar to FaceCal, but configurations are choosen random
%******** from a grid of possible locations, and second, on viewing
%******** a face it becomes a fixation point for a duration, followed
%******** by reward and disappearing if fixation is held (fix foraging)

%********** allow calibratin of eye position during running
P.InTrialCalib = 1;
S.InTrialCalib = 'Eye Calib in Trials';

%%%%% END OF NECESSARY VARIABLES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This settings is unnecessary because 'MarmoViewLastCalib.mat' is the GUI
% default to use, but because this is an exemplar protocol I decided to
% includee it if for some reason you don't want to use the last calibration
% values (e.g. subjects you are running have substantially different 
% horizontal or vertical gain). Place this calibration file in the
% 'SupportData' directory of MarmoView
S.calibFilename = 'MarmoViewLastCalib.mat';

% If using the gaze indicator, this sets a step value, intensity should be
% between 1 and 5, this is taking advantage of male color blindness to make
% it less obvious to the marmoset than us, but it will still be obvious if
% overwriting textures

%%%%% PARAMETERS -- VARIABLES FOR TASK, CAN CHANGE WHILE RUNNING %%%%%%%%%
% INCLUDES STIMULUS PARAMETERS, DURATIONS, FLAGS FOR TASK OPTIONS
% MUST BE SINGLE VALUE, NUMERIC -- NO STRINGS OR ARRAYS!
% THEY ALSO MUST INCLUDE DESCRIPTION OF THE VALUE IN THE SETTINGS ARRAY

% Stimulus settings
P.faceRadius = 0.75;
S.faceRadius = 'Aperture radius (degrees):';
P.eyeRadius = 2.0;
S.eyeRadius = 'Gaze indicator radius (degrees):';
P.eyeIntensity = 10;
S.eyeIntensity = 'Indicator intensity:';
P.showEye = 0;
S.showEye = 'Show the gaze indicator? (0 or 1):';
P.bkgd = 127;
S.bkgd = 'Choose the background color (0-255):';

% Trial timing
P.faceDur = 4;
S.faceDur = 'Duration to display faces (s):';
P.fixGrid = 5;  % number of X,Y locs (odd number, centered at origin)
S.fixGrid = 'Number of locations to sample on an axis';
P.fixStep = 3;
S.fixStep = 'Size in dva between sampled locations';
P.fixPts = 4;
S.fixPts = 'Number of sample fix points per trial';
P.fixHold = 0.5;  
S.fixHold = 'Duration to hold for reward (s)';
P.fixRadius = 2;
S.fixRadius = 'Radius to accept a fixating face';
P.fixPointRadius = 0.2;
S.fixPointRadius = 'Fixation point radius';
P.iti = 2;
S.iti = 'Duration of intertrial interval (s):';
