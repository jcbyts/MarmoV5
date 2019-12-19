function [S,P] = Acuity

%%%% NECESSARY VARIABLES FOR GUI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD THE RIG SETTINGS, THESE HOLD CRUCIAL VARIABLES SPECIFIC TO THE RIG,
% IF A CHANGE IS MADE TO THE RIG, CHANGE THE RIG SETTINGS FUNCTION IN
% SUPPORT FUNCTIONS
S = MarmoViewRigSettings;

% NOTE THE MARMOVIEW VERSION USED FOR THIS SETTINGS FILE, IF AN ERROR, IT
% MIGHT BE A VERSION PROBLEM
S.MarmoViewVersion = '5';

% PARAMETER DESCRIBING TRIAL NUMBER TO STOP TASK
S.finish = 300;

% STORE EYE POSITION DATA
% S.EyeDump = false;


% PROTOCOL PREFIX
S.protocol = 'Acuity';
% PROTOCOL PREFIXS
S.protocol_class = ['protocols.PR_',S.protocol];

% Define Banner text to identify the experimental protocol
% recommend maximum of ~28 characters
S.protocolTitle = 'Gabor Detection Task';

%******** Don't allow in trial calibration for this one (comment out)
% P.InTrialCalib = 1;
% S.InTrialCalib = 'Eye Calib in Trials';
S.TimeSensitive = 1:5;

%%%%% END OF NECESSARY VARIABLES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% PARAMETERS -- VARIABLES FOR TASK, CAN CHANGE WHILE RUNNING %%%%%%%%%
% INCLUDES STIMULUS PARAMETERS, DURATIONS, FLAGS FOR TASK OPTIONS
% MUST BE SINGLE VALUE, NUMERIC -- NO STRINGS OR ARRAYS!
% THEY ALSO MUST INCLUDE DESCRIPTION OF THE VALUE IN THE SETTINGS ARRAY

% Reward setting
P.RepeatUntilCorrect = 1;   % block structure, re-run trials till correct
S.RepeatUntilCorrect = 'Repeat trials till all correct :';
P.rewardNumber = 3;
S.rewardNumber = 'Number of juice pulses to deliver:';

% Stimulus settings
P.ecc = 5;  % eccentricity of grating for detection
S.ecc = 'Grating eccentricity (dva):';
P.cpd = 4;
S.cpd = 'Cycles per degree:';
P.minFreq = 4; %4;
S.minFreq = 'Min spf to test';
P.maxFreq = 12; %16;
S.maxFreq = 'Max spf to test';
P.FreqNum = 9;
S.FreqNum = 'Numb of freqs:';
P.apertures = 4;
S.apertures = 'Number of choice apertures:';
P.xDeg = 0.0; 
S.xDeg = 'X center of stimulus (degrees):';
P.yDeg = 0.0;
S.yDeg = 'Y center of stimulus (degrees):';
P.radius = 2.0;   
S.radius = 'Grating radius (degrees):';
P.orientation = 0;
S.orientation = 'Orientation of grating (degrees):';
P.bkgd = 127;
S.bkgd = 'Choose a grating background color (0-255):';
P.range = 127;
S.range = 'Luminance range of grating (1-127):';
P.phase = -1;
S.phase = 'Grating phase (-1 or 1):';
P.squareWave = 0;
S.squareWave = '0 - sine wave, 1 - square wave';

% Gaze indicator
P.eyeRadius = 2.5; 
S.eyeRadius = 'Gaze indicator radius (degrees):';
P.eyeIntensity = 5;
S.eyeIntensity = 'Indicator intensity:';
P.showEye = 0;
S.showEye = 'Show the gaze indicator? (0 or 1):';

%****** fixation properties
P.fixPointRadius = 0.35; 
S.fixPointRadius = 'Fix Point Radius (degs):';
P.fixPointColorOut = 0;
S.fixPointColorOut = 'Color of point outline (0-255):';
P.fixPointColorIn = 255;
S.fixPointColorIn = 'Color of point center (0-255):';
P.xFixDeg = 0.0; 
S.xFixDeg = 'Fix X center (degs):';
P.yFixDeg = 0.0;
S.yFixDeg = 'Fix Y center (degs):';

% Fixation and Response Windows
P.initWinRadius = 1;
S.initWinRadius = 'Enter to initiate fixation (deg):';
P.fixWinRadius = 2.0; %1.5;
S.fixWinRadius = 'Fixation window radius (deg):';
%*** check for saccade into left or right space
P.choiceRad = 4.0; % ring stimulus
S.choiceRad = 'Choice placed out to left or right (deg):';
P.choiceX = 5.0;   
S.choiceX = 'Sample choice location, X (deg): ';
P.choiceY = 0;
S.choiceY = 'Sample choice location, Y (deg): ';
P.choiceWidth = 3;
S.choiceWidth = 'Width of line aperture :';
P.choiceCon = 20;
S.choiceCon = 'Contrast of line aperture :';
%*************
P.stimWinMinRad = 2.5; 
S.stimWinMinRad = 'Minumum saccade from fixation (deg):';
P.stimWinMaxRad = 12;
S.stimWinMaxRad = 'Maximum saccade from fixation (deg):';
P.stimWinTheta = pi/5;
S.stimWinTheta = 'Angular leeway for saccade (radians):';

% Trial timing
P.startDur = 4;
S.startDur = 'Wait time to enter fixation (s):';
P.flashFrameLength = 30; %flash fixatin to draw animal to center
S.flashFrameLength = 'Length of fixation flash (frames):';
P.fixGrace = 0.05;
S.fixGrace = 'Grace period to be inside fix window (s):';
P.fixMin = 0.2;
S.fixMin = 'Minimum fixation (s):';
P.fixRan = 0.2; 
S.fixRan = 'Random additional fixation (s):';
P.stimDur = 0.30;
S.stimDur = 'Duration of grating presentation (s):';
P.stimHold = 0.10;
S.stimHold = 'Duration to hold fix after grating onset (s):';
P.noresponseDur = 1.5;
S.noresponseDur = 'Duration to count error if no response(s):';
P.flightDur = 0.05;
S.flightDur = 'Time for saccade to finish (s):';
P.holdDur = 0.025;
S.holdDur = 'Duration at grating for reward (s):';
P.iti = 0.5;
S.iti = 'Duration of intertrial interval (s):';
P.blank_iti = 1;
S.blank_iti = 'Duration of blank intertrial(s):';
P.timeOut = 0;
S.timeOut = 'Time out for error (s):';

%*******
P.runType = 1;
S.runType = '0-User,1-Trials List:';

