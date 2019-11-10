
function [S,P] = GazeCalibRefine

%%%% NECESSARY VARIABLES FOR GUI
%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% LOAD THE RIG SETTINGS, THESE HOLD CRUCIAL VARIABLES SPECIFIC TO THE RIG,
% IF A CHANGE IS MADE TO THE RIG, CHANGE THE RIG SETTINGS FUNCTION IN
% SUPPORT FUNCTIONS
S = MarmoViewRigSettings;

% NOTE THE MARMOVIEW VERSION USED FOR THIS SETTINGS FILE, IF AN ERROR, IT
% MIGHT BE A VERSION PROBLEM
S.MarmoViewVersion = '5';

% PARAMETER DESCRIBING TRIAL NUMBER TO STOP TASK
S.finish = 800;

% PROTOCOL PREFIX
S.protocol = 'GazeCalibRefine';
% PROTOCOL PREFIXS
S.protocol_class = ['protocols.PR_',S.protocol];


%NOTE: in MarmoView2 subject is entered in GUI

%******** Don't allow in trial calibration for this one (comment out)
% P.InTrialCalib = 1;
% S.InTrialCalib = 'Eye Calib in Trials';
S.TimeSensitive = 1:7;

% STORE EYE POSITION DATA
% S.EyeDump = false;

% Define Banner text to identify the experimental protocol
% recommend maximum of ~28 characters
S.protocolTitle = 'Refine eye position';

%%%%% END OF NECESSARY VARIABLES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% PARAMETERS -- VARIABLES FOR TASK, CAN CHANGE WHILE RUNNING %%%%%%%%%
% INCLUDES STIMULUS PARAMETERS, DURATIONS, FLAGS FOR TASK OPTIONS
% MUST BE SINGLE VALUE, NUMERIC -- NO STRINGS OR ARRAYS!
% THEY ALSO MUST INCLUDE DESCRIPTION OF THE VALUE IN THE SETTINGS ARRAY

% Reward setting
P.rewardNumber = 3;   % Max juice, only one drop ... it is so easy!
S.rewardNumber = 'Number of juice pulses to deliver:';
P.CycleBackImage = 5;
S.CycleBackImage = 'If def, backimage every # trials:';

%**********************
P.probShow = 5/S.frameRate; % default to 5 times a second after refractory period is met
S.probShow = 'Prob of stim onset on each frame while fixating';

P.refractoryDur = 0.5;
S.refractoryDur = 'Duration post flash before can be shown again (s):';

P.stimDur = 0.25;  % duration of peripheral stim (offset before sac)
S.stimDur = 'Duration of flashed stim (s):';

P.postSacGraceDur = 0.05;
S.postSacGraceDur = 'Stimulus duration post-saccade (s):';

P.eyeVelThresh = 10;
S.eyeVelThresh = 'Velocity for online saccade detection (deg/sec):';

P.useFace = true;
S.useFace = 'Use face as target (logical):';


P.trialDuration = 20;
S.trialDuration = 'Length of trial (s, must be < 20):';
%*******
P.targRadius = .5;  % diameter of target is dva
S.targRadius = 'Size of target (dva):';

P.bkgd = 127;
S.bkgd = 'Choose a grating background color (0-255):';

% Gaze indicator
P.eyeRadius = 1.5; % 1.5;
S.eyeRadius = 'Gaze indicator radius (degrees):';
P.eyeIntensity = 5;
S.eyeIntensity = 'Indicator intensity:';
P.showEye = 0;
S.showEye = 'Show the gaze indicator? (0 or 1):';


% Windows
P.initWinRadius = 1;
S.initWinRadius = 'Enter to initiate fixation (deg):';
P.fixWinRadius = 2.0;  %by JM 10/18/17
S.fixWinRadius = 'Fixation window radius (deg):';

% Trial timing
P.startDur = 1;
S.startDur = 'Time to enter fixation (s):';
P.flashFrameLength = 32;   % make it slow, 250 ms
S.flashFrameLength = 'Length of fixation flash (frames):';
P.flashFrameLengthBreak = 8;   % make it slow, 250 ms
S.flashFrameLengthBreak = 'Length of fixation flash after breaks (frames):';
P.fixGrace = 0.05;   %50 ms, making sure not a saccade through fixation
S.fixGrace = 'Grace period to be inside fix window (s):';

P.noresponseDur = 2.5;
S.noresponseDur = 'Duration to count error if no response(s):';
P.flightDur = 0.05;
S.flightDur = 'Time for saccade to finish (s):';
P.flightWait = 0.5;
S.flightWait = 'Time to find a target (s):';
P.iti = 1;
S.iti = 'Duration of intertrial interval (s):';
P.blank_iti = 1;
S.blank_iti = 'Duration of blank intertrial(s):';
P.abort_iti = 3;
S.abort_iti = 'Duration of abort intertrial(s):';
P.timeOut = 1;
S.timeOut = 'Time out for error (s):';

