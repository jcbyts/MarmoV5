
function [S,P] = Flag

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
S.protocol = 'Flag';
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
S.protocolTitle = 'Simple Target Saccade';

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
P.stimDur = 0.10;  % duration of peripheral stim (offset before sac)
S.stimDur = 'Duration of peripheral stim (s):';
%************
P.gazecontin = 0;
S.gazecontin = 'Make noise gaze contingent:';
P.holdDur = 0.10;
S.holdDur = 'Duration at grating for reward (s):';
P.stimOnDel = 0.3;   % was 0.3!!! too long
S.stimOnDel = 'Jitter onset of stim 0-? s:';
P.dotdelay = 0.30; % extra duration stim presentation after saccade
S.dotdelay = 'Extra dot time(s):';
P.fixslots = 0.08;  % give juice for fixation from fraction   
S.fixslots = 'Fraction of fix trials:';
P.fixMin = 0.10;  
S.fixMin = 'Minimum fixation (s):';
P.fixRan = 0.10;
S.fixRan = 'Random additional fixation (s):';
P.probecon = -1.00; 
S.probecon = 'Transparency of Probe (1-none, 0-gone):';
P.range = 64; % lower contrast probe, 127;
S.range = 'Luminance range of grating (1-127):';

P.orinum = 12;  
S.orinum = 'Orientations to sample of stimulus';
if (1)  % full circle stim
    P.prefori = 90;  % center direction for trial tuning
    S.prefori = 'Pref ori (0 to 180)';
    P.rangeori = 90;  % plus or minus range around ori
    S.rangeori = 'Plus or minus range (0 to 90)';    
else   % limited range around target
    P.prefori = 15;  % center direction for trial tuning
    S.prefori = 'Pref ori (0 to 180)';
    P.rangeori = 30;  % plus or minus range around ori
    S.rangeori = 'Plus or minus range (0 to 90)';
end
%******** choose to burn more orientations
P.orinum2 = 0;   % set to zero if not
S.orinum2 = 'Orientations over focused range:';
P.prefori2 = 105;
S.prefori2 = 'Pref ori (focused range):';
P.rangeori2 = 30;  % note, will sample in between points
S.rangeori2 = 'Range for finer sampling:';
P.fadeframes = 6;
S.fadeframes = 'Fade in of stim probe:';
%***************

P.ori = 0;  % stim orientation
S.ori = 'Stim orientation (degs):';
P.postori = 0;  % stim orientation
S.postori = 'Post-sac Stim ori(degs):';
P.stimEcc = 7.0;
S.stimEcc = 'Ecc of stimulus (degrees):';

% Stimulus settings
P.fixdelay = 0.5; % hold if a fixation trial
S.fixdelay = 'Fixation Trial Hold (s):';
P.fixation = 0;
S.fixation = 'Reward fixation (no target):';
P.apertures = 8;
S.apertures = 'Number of aperture locs:';
P.xDeg = 7.0;
S.xDeg = 'X center of stimulus (degrees):';
P.yDeg = 0;
S.yDeg = 'Y center of stimulus (degrees):';
P.radius = 3.0;  % diameter of target is dva
S.radius = 'Size of Target(dva):';
P.cpd = 4;  % must be scaled by pixperDeg
S.cpd = 'Cycles per degree:';
P.cpd2 = 16;  % must be scaled by pixperDeg
S.cpd2 = '2nd Cycles per deg:';
P.faceradius = 1.5;  % diameter of target is dva
S.faceradius = 'Size of Face(dva):';
%********* parameters for noise stimulus following gaze
P.noisenum = 1; % 12;  
S.noisenum = 'Noise orientations:';
%******
P.probNoise = 0.2;  % fraction of frames with orientation instead of blank
S.probNoise = 'Fraction frames no blank: ';
P.noiseradius = 2.0;  %Inf; %4.0;  % diameter of target is dva
S.noiseradius = 'Size of Face(dva):';
P.noisecpd = 0;  % if zero, becomes a blob
S.noisecpd = 'Fix Gabor Cycles per degree (0 is blob):';
P.noiserange = 32; % noise lower contrast probe, 127;
S.noiserange = 'Luminance range central noise(1-127):';
%*********
P.bkgd = 127;
S.bkgd = 'Choose a grating background color (0-255):';
P.phase = -1;
S.phase = 'Grating phase (-1 or 1):';
P.squareWave = 0;
S.squareWave = '0 - sine wave, 1 - square wave';

% Gaze indicator
P.eyeRadius = 1.5; % 1.5;
S.eyeRadius = 'Gaze indicator radius (degrees):';
P.eyeIntensity = 5;
S.eyeIntensity = 'Indicator intensity:';
P.showEye = 0;
S.showEye = 'Show the gaze indicator? (0 or 1):';

%****** fixation properties
P.fixPointRadius = 0.3;  
S.fixPointRadius = 'Fix Point Radius (degs):';

% Windows
P.initWinRadius = 1;
S.initWinRadius = 'Enter to initiate fixation (deg):';
P.fixWinRadius = 2.0;  %by JM 10/18/17
S.fixWinRadius = 'Fixation window radius (deg):';
P.stimWinMinRad = 4; % by JM
S.stimWinMinRad = 'Minumum saccade from fixation (deg):';
P.stimWinMaxRad = 10; %10; by JM
S.stimWinMaxRad = 'Maximum saccade from fixation (deg):';
P.stimWinTheta = pi/8;  % bit more narrow, force accuracy
S.stimWinTheta = 'Angular leeway for saccade (radians):';

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
P.flightDur = 0.07;
S.flightDur = 'Time for saccade to finish (s):';
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

