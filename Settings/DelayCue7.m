
function [S,P] = DelayCue7

%%%% NECESSARY VARIABLES FOR GUI
%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% LOAD THE RIG SETTINGS, THESE HOLD CRUCIAL VARIABLES SPECIFIC TO THE RIG,
% IF A CHANGE IS MADE TO THE RIG, CHANGE THE RIG SETTINGS FUNCTION IN
% SUPPORT FUNCTIONS
S = MarmoViewRigSettings;

% NOTE THE MARMOVIEW VERSION USED FOR THIS SETTINGS FILE, IF AN ERROR, IT
% MIGHT BE A VERSION PROBLEM
S.MarmoViewVersion = '3';

% PARAMETER DESCRIBING TRIAL NUMBER TO STOP TASK
S.finish = 400;

% PROTOCOL PREFIX
S.protocol = 'DelayCue7';
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
S.protocolTitle = 'Symbolic Cue Task';

%%%%% END OF NECESSARY VARIABLES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% PARAMETERS -- VARIABLES FOR TASK, CAN CHANGE WHILE RUNNING %%%%%%%%%
% INCLUDES STIMULUS PARAMETERS, DURATIONS, FLAGS FOR TASK OPTIONS
% MUST BE SINGLE VALUE, NUMERIC -- NO STRINGS OR ARRAYS!
% THEY ALSO MUST INCLUDE DESCRIPTION OF THE VALUE IN THE SETTINGS ARRAY

% Reward setting
P.RepeatUntilCorrect = 1;   % block structure, re-run trials till correct
S.RepeatUntilCorrect = 'Repeat trials till all correct :';
P.rewardNumber = 5;   % Max juice
S.rewardNumber = 'Number of juice pulses to deliver:';
P.delayNumber = 1;  % default
P.TargetDist = 1;  % 1 for single, 2 for opposite hemi, 3 - four items, 4 - all 8 ... more to come
% trial balancing per unit set
P.SamplingDirections = 1; % 1 all 8, 2 - cardinal, 3 - diagonal, 4 - show 8 apertures
%********* equate location sampling every 8 trials
P.randtrialcnt = 2;
if (P.SamplingDirections == 1) | (P.SamplingDirections == 4)  % all 8 directions    
    P.randtrial = [randperm(8) randperm(8)];
else 
    if (P.SamplingDirections == 2) %cardinal directions
        P.randtrial = [randperm(4)*2 randperm(4)*2];
    else
        P.randtrial = [ ((randperm(4)*2)-1) ((randperm(4)*2)-1)];
    end 
end

%************** vary stim contrat to equate preference
P.dropStimulus = 0.5;   %fraction of trials to disappear stim on saccade flight
S.dropStimulus = 'Fraction of trials to drop stimulus:';
%P.dotFadeStep = 0.020; %0.03;  % increase or decrease fade in speed to vary salience
%S.dotFadeStep = 'Fade Step for Salience (0.01,small):';
%P.cueLenStep = 0.0; %0.05;  % increase or decrease fade in speed to vary salience
%S.cueLenStep = 'Lengthen Cue Line (0.1, for Salience):';
%P.cueLenDefault = 1.8;  % increase or decrease fade in speed to vary salience
%S.cueLenDefault = 'Default Length of Cue Line (1.5):';
%***********************

P.stimEcc = 5.0;
S.stimEcc = 'Ecc of stimulus (degrees):';

% Stimulus settings
P.delay = 1.0;
S.delay = 'Delay(s):';
P.dotdelay = .30; % extra duration stim presentation after saccade
S.dotdelay = 'Extra dot time(s):';
P.apertures = 8;
S.apertures = 'Number of apertures:';
P.xDeg = 5.0; %6.0; %7.5;
S.xDeg = 'X center of stimulus (degrees):';
P.yDeg = 0;
S.yDeg = 'Y center of stimulus (degrees):';
P.faceRadius = 2.0;  % diameter is dva
S.faceRadius = 'Size of Face(dva):';

%**** JM - if too difficult at first
P.apertureRadius =  3; 
S.apertureRadius = 'Aperture radius (degrees):';
P.dotFade = -1.5;  %increment to increase lum per frame
S.dotFade = 'Dot fade in (0-5):';
%**********************
% P.apertureWidth = 0; % no longer shown
% S.apertureWidth = 'Width of aperture line (pixels):';
% P.apertureColor = 0;
% S.apertureColor = 'Aperture color (0-255):';
% P.apertureFade = -1.0; %increment to increase lum per frame
% S.apertureFade = 'Aperture fade in (0-5):';
%*******
P.dotColor = 0;  % over-ridden by dot fade-in 
S.dotColor = 'Dot color (0-255):';
P.dotSpeed = 7.5; 
S.dotSpeed = 'Dot Speed (Degree per sec):';
P.dotSize = 0.15; 
S.dotSize = 'Dot Size (Degree):';
P.dotNum = 200;
S.dotNum = 'Number of dots:';
P.correctColor = 0; %127-5;
S.correctColor = 'Correction cue color (0-255):';
P.bkgd = 127;
S.bkgd = 'Choose a grating background color (0-255):';
P.range = 127;
S.range = 'Luminance range of grating (1-127):';

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
P.probShowFace = 0;
S.probShowFace = 'Flash large face at fix to start (p=0.0):';

% Windows
P.initWinRadius = 1;
S.initWinRadius = 'Enter to initiate fixation (deg):';
P.fixWinRadius = 2.0;  %by JM 10/18/17
S.fixWinRadius = 'Fixation window radius (deg):';
P.stimWinMinRad = 2.0; % by JM
S.stimWinMinRad = 'Minumum saccade from fixation (deg):';
P.stimWinMaxRad = 10; %10; by JM
S.stimWinMaxRad = 'Maximum saccade from fixation (deg):';
P.stimWinTheta = pi/6; 
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
P.fixMin = 0.20;  
S.fixMin = 'Minimum fixation (s):';
P.fixRan = 0.10;
S.fixRan = 'Random additional fixation (s):';
P.stimForwardDur = 0.0;   % was 0.3!!! too long
S.stimForwardDur = 'Duration of fixation hold from line cue:';
% P.stimGazeDur = 0.1;
% S.stimGazeDur = 'Duration of gaze cue face:';

P.noresponseDur = 1.5;
S.noresponseDur = 'Duration to count error if no response(s):';
P.flightDur = 0.07;
S.flightDur = 'Time for saccade to finish (s):';
P.holdDur = 0.025;
S.holdDur = 'Duration at grating for reward (s):';
P.iti = 0.5;
S.iti = 'Duration of intertrial interval (s):';
P.blank_iti = 0.5;
S.blank_iti = 'Duration of blank intertrial(s):';
P.abort_iti = 3.0;
S.abort_iti = 'Duration of abort intertrial(s):';
P.timeOut = 0.5;
S.timeOut = 'Time out for error (s):';

% Cue pointer parameters
P.width1 = 0.11; 
S.width1 = 'Cue line width in degs';
P.sigma1 = 2.5;
S.sigma1 = 'Cue line width near fixation';
P.FixN = 11;
S.FixN = 'Steps to fixation fade:';
P.cue_contrast = 1.0;
S.cue_contrast = 'Cue Contrast(0-1.0):';
P.cue_peak = 1.0;
S.cue_peak = 'Cue Delay(s):';
P.cue_width = 0.5;
S.cue_width = 'Cue Width(s):';
P.cueColor = 255;
S.cueColor = 'Line Cue Polarity (white)';
P.cueDelayMin = 0.6;
S.cueDelayMin = 'Min Delay (secs) on Cue:';
P.cueDelayMax = 0.8;
S.cueDelayMax = 'Max Delay (secs) on Cue:';
%*******
P.runType = 1;
S.runType = '0-User,1-Trials List:';
%*************
P.rewardFix = 0;
S.rewardFix = 'One drop for holding fix (0 or 1): ';

%*********** Limit number of fixation trials ******** 
P.minCueCount = 2;  % min correct in cue task before allow a fixation trial
S.minCueCount = 'Min Cued Response before a fix trial: ';

%**************** Singleton list ... locations to reward for single targ
%**************** saccades ... to weight rewards to those locations
P.SingletonTrial = 0;  
S.SingletonTrial = 'Show single target';
%*******
S.SingletonDirs = [0, 180];  % By sac direction, right is 0, goes counter-clock
                           % Draw from these to give single targ trials
                           
