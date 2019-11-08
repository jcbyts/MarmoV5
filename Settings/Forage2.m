
function [S,P] = Forage2()

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
S.protocol = 'Forage2';
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
S.protocolTitle = 'Foraging with back mapping';

%%%%% END OF NECESSARY VARIABLES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% PARAMETERS -- VARIABLES FOR TASK, CAN CHANGE WHILE RUNNING %%%%%%%%%
% INCLUDES STIMULUS PARAMETERS, DURATIONS, FLAGS FOR TASK OPTIONS
% MUST BE SINGLE VALUE, NUMERIC -- NO STRINGS OR ARRAYS!
% THEY ALSO MUST INCLUDE DESCRIPTION OF THE VALUE IN THE SETTINGS ARRAY

% Reward setting
P.rewardNumber = 1;   % Max juice, only one drop ... it is so easy!
S.rewardNumber = 'Number of juice pulses to deliver:';
P.CycleBackImage = 5;
S.CycleBackImage = 'If def, backimage every # trials:';

%******* trial timing and reward
P.holdDur = 0.10;
S.holdDur = 'Duration at grating for reward (s):';
P.fixRadius = 2.5;  
S.fixRadius = 'Probe reward radius(degs):';
P.trialdur = 10; 
S.trialdur = 'Trial Duration (s):';
P.iti = 0.5;
S.iti = 'Duration of intertrial interval (s):';
P.mingap = 0.2;  
S.mingap = 'Min gap to next target (s):';
P.maxgap = 0.5;
S.maxgap = 'Max gap to next target (s):';
P.probFace = 0.5;
S.probFace = 'Prob of face reward:';
P.faceradius = 1.0;  % diameter of target is dva
S.faceradius = 'Size of Face(dva):';
P.faceTime = 0.1;  % duration of flashed face, in ms
S.faceTime = 'Duration of Face Flash (s):';

%************** Probe properties
P.proberadius = 2.5;  % radius of target is dva
S.proberadius = 'Size of Target(dva):';
P.probecon = 0.50; 
S.probecon = 'Transparency of Probe (1-none, 0-gone):';
P.proberange = 48; %a bit brighter
S.proberange = 'Luminance range of grating (1-127):';
P.stimEcc = 4.0;
S.stimEcc = 'Ecc of stimulus (degrees):';
P.stimBound = 7.0;
S.stimBound = 'Boundary if moving (degs):';
P.stimSpeed = 0;
S.stimSpeed = 'Speed of probe (degs/sec):';
P.orinum = 3;  
S.orinum = 'Orientations to sample of stimulus';
P.prefori = 40;
S.prefori = 'Preferred orientation (degs):';
P.cpd = 3;  
S.cpd = 'Probe Spatial Freq (cyc/deg)';
%*****
P.nonprefori = 130;  
S.nonprefori = 'Preferred orientation (degs):';
P.noncpd = 3;  
S.noncpd = 'Probe Spatial Freq (cyc/deg)';
%*****
P.bkgd = 127;
S.bkgd = 'Choose a grating background color (0-255):';
P.phase = 0;
S.phase = 'Grating phase (-1 to 1):';
P.squareWave = 0;
S.squareWave = '0 - sine wave, 1 - square wave';

% Gaze indicator
P.eyeRadius = 1.5; % 1.5;
S.eyeRadius = 'Gaze indicator radius (degrees):';
P.eyeIntensity = 5;
S.eyeIntensity = 'Indicator intensity:';
P.showEye = 0;
S.showEye = 'Show the gaze indicator? (0 or 1):';

%***** FORAGE CAN ACCEPT DIFFERENT BACKGROUND TYPES *****
P.noisetype = 1;
S.noisetype = 'Background (0-none,1-hartley, 2-spatial, ...):';

if (P.noisetype == 1)
    %****** Hartley type spf and orientation stim
    % not perfect, in radial space than ori/freq domain
    P.orioffset = 11.25;
    S.orioffset = 'Offset start Ori (degs):';
    P.noiseorinum = 8;  
    S.noiseorinum = 'Noise orientations:';
    P.spfnum = 4;
    S.spfnum = 'Number of spatial freqs to test';
    P.spfmin = 2;  % will be [0.5 1 2 4 8 16]
    S.spfmin = 'Minimum spat freq (cyc/deg):';
    P.spfmax = 16;   % use log spacing
    S.spfmax = 'Minimum spat freq (cyc/deg):';
    %********* parameters for noise stimulus following gaze
    P.probNoise = 0.10;  % fraction of frames with orientation instead of blank
    S.probNoise = 'Fraction frames no blank: ';
    P.noiseradius = Inf; %4.0;  % diameter of target is dva
    S.noiseradius = 'Size of Face(dva):';
    P.noiserange = 127;
    S.noiserange = 'Luminance range of grating (1-127):';
    P.dontclear = 2;
end

if (P.noisetype == 2)
    %****** in this version fixation noise is spatial noise
    P.snoisewidth = 25.0;  % radius of noise field around origin
    S.snoisewidth = 'Spatial noise width (degs, +/- origin):';
    P.snoiseheight = 15.0;  % radius of noise field around origin
    S.snoiseheight = 'Spatial noise height (degs, +/- origin):';
    P.snoisenum = 8;   % number of white/black ovals to draw
    S.snoisenum = 'Number of noise ovals:';
    P.snoisediam = 1.0; %2.0; % diameter in dva of noise oval
    S.snoisediam = 'Diameter of noise ovals (dva): ';   
    P.range = 64; %127;
    S.range = 'Luminance range of grating (1-127):';
end

if (P.noisetype == 3)
    %****** in this version it is CSD, whole field white background
    %********* parameters for noise stimulus following gaze
    P.noisedur = 40;  % number of frames to hold on stim
    S.noisedur = 'Frames on of stim: ';
    P.noiseoff = 80;  % number of frames to hold on stim
    S.noiseoff = 'Frames off of stim: ';
    P.noiserange = 127;
    S.noiserange = 'Luminance range of grating (1-127):';
    %*************
end

