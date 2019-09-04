
function [S,P] = FlagMo

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
S.protocol = 'FlagMo';
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
S.protocolTitle = 'Cued target saccade';

%%%%% END OF NECESSARY VARIABLES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% PARAMETERS -- VARIABLES FOR TASK, CAN CHANGE WHILE RUNNING %%%%%%%%%
% INCLUDES STIMULUS PARAMETERS, DURATIONS, FLAGS FOR TASK OPTIONS
% MUST BE SINGLE VALUE, NUMERIC -- NO STRINGS OR ARRAYS!
% THEY ALSO MUST INCLUDE DESCRIPTION OF THE VALUE IN THE SETTINGS ARRAY

% Reward setting
P.rewardNumber = 3;   % Max juice, only one drop ... it is so easy!
S.rewardNumber = 'Number of juice pulses to deliver:';
P.CycleBackImage = 20;
S.CycleBackImage = 'If def, backimage every # trials:';

%**********************
P.gazecontin = 0;
S.gazecontin = 'Make noise gaze contingent:';
P.holdDur = 0.10;
S.holdDur = 'Duration at grating for reward (s):';
P.stimOnDel = 0.3;   % was 0.3!!! too long
S.stimOnDel = 'Jitter onset of stim 0-? s:';
P.stimDur = 0.20;  % duration of peripheral stim (offset before sac)
S.stimDur = 'Duration of peripheral stim (s):';
P.dotdelay = 0.30; % extra duration stim presentation after saccade
S.dotdelay = 'Extra dot time(s):';
P.fixslots = 0.08;  % give juice for fixation from fraction   
S.fixslots = 'Fraction of fix trials:';
P.fixMin = 0.15;  
S.fixMin = 'Minimum fixation (s):';
P.fixRan = 0.25;
S.fixRan = 'Random additional fixation (s):';
P.fixdelay = 0.5; % hold if a fixation trial
S.fixdelay = 'Fixation Trial Hold (s):';
P.fixation = 0;
S.fixation = 'Reward fixation (no target):';

%******* parameters for spatial cue to target
P.width1 = 0.11; 
S.width1 = 'Cue line width in degs';
P.sigma1 = 1.0;
S.sigma1 = 'Cue line width near fixation';
P.FixN = 1;
S.FixN = 'Steps to fixation fade:';
P.cue_contrast = 1.0;
S.cue_contrast = 'Cue Contrast(0-1.0):';
%***************

%*************
P.ori = 0;  % stim orientation
S.ori = 'Stim motion (degs):';
P.postori = 0;  % stim orientation
S.postori = 'Post-sac Stim ori(degs):';
P.stimEcc = 7.0;
S.stimEcc = 'Ecc of stimulus (degrees):';

%************
P.orinum = 16;  
S.orinum = 'Motion dirs to sample of stimulus';
P.RF_X = -1;
S.RF_X = 'Position of RF, x-pos (degs):';
P.RF_Y = 4;
S.RF_Y = 'Position of RF, y-pos (degs):';
ecc = norm([P.RF_X,P.RF_Y]);
P.targnum = 3;  %total choice locations
S.targnum = 'Number of choice locations:';
%*****
P.xDeg = P.RF_X;
S.xDeg = 'X center of stimulus (degrees):';
P.yDeg = P.RF_Y;
S.yDeg = 'Y center of stimulus (degrees):';
P.eccFrac = 0.4;
S.eccFrac = 'RF radius as fraction of ecc (degs):';
P.radius = P.eccFrac * ecc;  % diameter of target is dva
S.radius = 'Size of Target(dva):';
P.choiceRadius = P.eccFrac * ecc;
S.choiceRadius = 'Choice on target (degs):';
%********

% Stimulus settings, use dot motion or static grating
P.motionStimulus = 1;
S.motionStimulus = 'Use moving dot field:';

if (P.motionStimulus == 0)  % use grating      
    P.cpd = 8;  % must be scaled by pixperDeg
    S.cpd = 'Cycles per degree:';
    P.cpd2 = NaN;  % must be scaled by pixperDeg
    S.cpd2 = '2nd Cycles per deg:';
    P.phase = -1;
    S.phase = 'Grating phase (-1 or 1):';
    P.squareWave = 0;
    S.squareWave = '0 - sine wave, 1 - square wave';
    P.probecon = -1.00; 
    S.probecon = 'Transparency of Probe (1-none, 0-gone):';
    P.range = 64;
    S.range = 'Luminance range of grating (1-127):';
else 
    P.dotColor = 0;  % over-ridden by dot fade-in 
    S.dotColor = 'Dot color (0-255):';
    P.dotSpeed = 15;  % between 10 and 15
    S.dotSpeed = 'Dot Speed (Degree per sec):';
    P.lifetime = Inf;  % between 10 and 15
    S.lifetime = 'Dot Lifetime (frames):';
    P.dotSize = 0.2; 
    S.dotSize = 'Dot Size (Degree):';
    P.dotNum = floor( 50 * ((ecc/5)^ 2) );
    S.dotNum = 'Number of dots:';
    P.range = 127;
    S.range = 'Luminance range of grating (1-127):';
end

%*******
P.faceradius = 1.5;  % diameter of target is dva
S.faceradius = 'Size of Face(dva):';
P.bkgd = 127;
S.bkgd = 'Choose a grating background color (0-255):';

% Gaze indicator
P.eyeRadius = 1.5; % 1.5;
S.eyeRadius = 'Gaze indicator radius (degrees):';
P.eyeIntensity = 5;
S.eyeIntensity = 'Indicator intensity:';
P.showEye = 0;
S.showEye = 'Show the gaze indicator? (0 or 1):';
P.showCue = 0;
S.showCue = 'Show line cue? (1 or 0): ';

%****** fixation properties
P.fixPointRadius = 0.3;  
S.fixPointRadius = 'Fix Point Radius (degs):';

% Windows
P.initWinRadius = 1;
S.initWinRadius = 'Enter to initiate fixation (deg):';
P.fixWinRadius = 2.0;  %by JM 10/18/17
S.fixWinRadius = 'Fixation window radius (deg):';

% Trial timing
P.startDur = 2;
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

%***** FOR RUNNING TRIAL-LIST, repeat them all till all are correct
P.RepeatUntilCorrect = 1;   % block structure, re-run trials till correct
S.RepeatUntilCorrect = 'Repeat trials till all correct :';

%*******
P.runType = 1;
S.runType = '0-User,1-Trials List:';

%*************
P.rewardFix = 0;
S.rewardFix = 'One drop for holding fix (0 or 1): ';

%*********** Limit number of fixation trials ******** 
P.minCueCount = 2;  % min correct in cue task before allow a fixation trial
S.minCueCount = 'Min Cued Response before a fix trial: ';

