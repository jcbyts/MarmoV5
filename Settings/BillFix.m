function [S,P] = BillFix

% Updated by Jude, 10/6/2018, to modify staircasing and include gunshot 
%                 sound as an object from stimulus folder
%
  
%%%%% NECESSARY VARIABLES FOR GUI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD THE RIG SETTINGS, THESE HOLD CRUCIAL VARIABLES SPECIFIC TO THE RIG,
% IF A CHANGE IS MADE TO THE RIG, CHANGE THE RIG SETTINGS FUNCTION IN
% SUPPORT FUNCTIONS
S = MarmoViewRigSettings;

% NOTE THE MARMOVIEW VERSION USED FOR THIS SETTINGS FILE, IF AN ERROR, IT
% MIGHT BE A VERSION PROBLEM
S.MarmoViewVersion = '2';

% PARAMETER DESCRIBING TRIAL NUMBER TO STOP TASK
S.finish = 40;

% PROTOCOL PREFIX
S.protocol = 'BillFix';
% PROTOCOL PREFIXS
S.protocol_class = ['protocols.PR_',S.protocol];

% STORE EYE POSITION DATA
% S.EyeDump = false;

% Define Banner text to identify the experimental protocol
% recommend maximum of ~28 characters
S.protocolTitle = 'Bill Fixation Point Training';
S.TimeSensitive = 2;  % state 2 is Gabor flashing, don't drop frames

%%%%% END OF NECESSARY VARIABLES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% PARAMETERS -- VARIABLES FOR TASK, CAN CHANGE WHILE RUNNING %%%%%%%%%
% INCLUDES STIMULUS PARAMETERS, DURATIONS, FLAGS FOR TASK OPTIONS
% MUST BE SINGLE VALUE, NUMERIC -- NO STRINGS OR ARRAYS!
% THEY ALSO MUST INCLUDE DESCRIPTION OF THE VALUE IN THE SETTINGS ARRAY

% Windows
P.fixWinRadius = 1.5;
S.fixWinRadius = 'Fixation window radius (deg):';


% Trial timing
P.fixMin = 0.2;
S.fixMin = 'Minimum fixation (s):';
P.fixRan = 0.1;
S.fixRan = 'Random additional fixation (s):';
P.stairUp = 0.20;
S.stairUp = 'Staircase up duration(s):';
P.stairDown = 0.15;
S.stairDown = 'Staircase down dur (s):';
P.stairMax = 3.0;
S.stairMax = 'Max fixation dur (s):';
P.stairMin = 0.2;
S.stairMin = 'Min fixation dur (s):';

P.startDur = 4;
S.startDur = 'Time to enter fixation (s):';
P.fixGrace = 0.05;
S.fixGrace = 'Grace period to be inside fix window (s):';
P.iti = 2;
S.iti = 'Duration of intertrial interval (s):';
P.timeOut = 1;
S.timeOut = 'Time out for error (s):';

% Reward setting
P.rewardNumber = 1;
S.rewardNumber = 'Number of juice pulses to deliver:';

%********** allow calibratin of eye position during running
P.InTrialCalib = 1;
S.InTrialCalib = 'Eye Calib in Trials';

% Stimulus settings
P.fixPointRadius = .35; % in deg, but recommended > than 4 pixels
S.fixPointRadius = 'Radius of point (deg):';
P.fixPointColorOut = 0;
S.fixPointColorOut = 'Color of point outline (0-255):';
P.fixPointColorIn = 255;
S.fixPointColorIn = 'Color of point center (0-255):';
P.xDeg = 0;
S.xDeg = 'X center of point (deg):';
P.yDeg = 0;
S.yDeg = 'Y center of point (deg):';
P.bkgd = 127;
S.bkgd = 'Choose the background color (0-255):';

% Gaze indicator
P.eyeRadius = 1.2;
S.eyeRadius = 'Gaze indicator radius (degrees):';
P.eyeIntensity = 20;
S.eyeIntensity = 'Indicator intensity:';
P.showEye = 0;
S.showEye = 'Show the gaze indicator? (0 or 1):';

% Alternate ways for the run loop to control parameters
P.runType = 1;
S.runType = '0-User, 1-Staircase:';
