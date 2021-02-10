
function [S,P] = Forage

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
S.protocol = 'Forage';
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
P.holdDur = 0.30;
S.holdDur = 'Duration at grating for reward (s):';
P.fixRadius = 2.5;  
S.fixRadius = 'Probe reward radius(degs):';
P.trialdur = 10; 
S.trialdur = 'Trial Duration (s):';
P.iti = 0.5;
S.iti = 'Duration of intertrial interval (s):';
P.mingap = 0.4;  
S.mingap = 'Min gap to next target (s):';
P.maxgap = 1.6;
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
P.probecon = 0.60; 
S.probecon = 'Transparency of Probe (1-none, 0-gone):';
P.proberange = 80; %
S.proberange = 'Luminance range of grating (1-127):';
P.stimEcc = 4.0;
S.stimEcc = 'Ecc of stimulus (degrees):';
P.stimBound = 7.0;
S.stimBound = 'Boundary if moving (degs):';
P.stimSpeed = 0;
S.stimSpeed = 'Speed of probe (degs/sec):';
P.orinum = 3;  
S.orinum = 'Orientations to sample of stimulus';
P.prefori = 45;  
S.prefori = 'Preferred orientation (degs):';
P.cpd = 4;  
S.cpd = 'Probe Spatial Freq (cyc/deg)';
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
P.noisetype = 2;
S.noisetype = 'Background (0-none,1-hartley, 2-spatial, ...):';

if (P.noisetype == 1)
    %****** Hartley type spf and orientation stim
    % not perfect, in radial space than ori/freq domain
    P.noiseorinum = 12;  
    S.noiseorinum = 'Noise orientations:';
    P.spfnum = 6;
    S.spfnum = 'Number of spatial freqs to test';
    P.spfmin = 0.5;  % will be [0.5 1 2 4 8 16]
    S.spfmin = 'Minimum spat freq (cyc/deg):';
    P.spfmax = 16;   % use log spacing
    S.spfmax = 'Minimum spat freq (cyc/deg):';
    %********* parameters for noise stimulus following gaze
    P.probNoise = 0.25;  % fraction of frames with orientation instead of blank
    S.probNoise = 'Fraction frames no blank: ';
    P.noiseradius = Inf; %4.0;  % diameter of target is dva
    S.noiseradius = 'Size of Face(dva):';
    P.noiserange = 127;
    S.noiserange = 'Luminance range of grating (1-127):';
end

if (P.noisetype == 2)
    %****** in this version fixation noise is spatial noise
    P.snoisewidth = 25.0;  % radius of noise field around origin
    S.snoisewidth = 'Spatial noise width (degs, +/- origin):';
    P.snoiseheight = 15.0;  % radius of noise field around origin
    S.snoiseheight = 'Spatial noise height (degs, +/- origin):';
    if (1)  % for V1
      P.snoisenum = 16;   % number of white/black ovals to draw
      S.snoisenum = 'Number of noise ovals:';
      P.snoisediam = 0.5;  % diameter in dva of noise oval
      S.snoisediam = 'Diameter of noise ovals (dva): ';
    else  % for MT
      P.snoisenum = 3;   % number of white/black ovals to draw
      S.snoisenum = 'Number of noise ovals:';
      P.snoisediam = 1.0;  % diameter in dva of noise oval
      S.snoisediam = 'Diameter of noise ovals (dva): '; 
    end
    P.range = 127;
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

if (P.noisetype == 4)
    %****** in this version full field motion 
    P.noisewidth = 25.0;  % radius of noise field around origin
    S.noisewidth = 'Spatial noise width (degs, +/- origin):';
    P.noiseheight = 15.0;  % radius of noise field around origin
    S.noiseheight = 'Spatial noise height (degs, +/- origin):';
    P.stimCycle = 30;   % video frames of motion
    S.stimCycle = 'On duration of motion (frames):';
    P.totCycle = 50;   % video frames of motion
    S.totCycle = 'Total duration till next motion (frames):';
    %*******
    P.dotNum = 640;   % number of dots to draw
    S.dotNum = 'Number of dots: ';
    P.dotSize = 0.2;  % diameter in dva of dot
    S.dotSize = 'Diameter of dots (dva): '; 
    P.dotLifeTime = inf; % duration of each dot, in frames
    S.dotLifeTime = 'Duration in frames :';
    P.numSpeed = 2;   % number of speeds to sample, changed 9/13 from 4 to 2
    S.numSpeed = 'Number of speeds: ';
    P.dotSpeed = 15.0; % diameter in dva of noise oval
    S.dotSpeed = 'Dot speed (dva/s): ';   
    P.dotSpeedMin = 8; % diameter in dva of noise oval
    S.dotSpeedMin = 'Min Dot speed (dva/s): ';   
    P.dotSpeedMax = 16; %32.0; % diameter in dva of noise oval, change 9/13 32 to 16
    S.dotSpeedMax = 'Max Dot speed (dva/s): ';   
    P.noisenum = 16; % number of motion directions
    S.noisenum = 'Dot motion directions: ';   
    P.range = 68; % minus from the background
    S.range = 'Luminance range of grating (1-127):';
end

if (P.noisetype == 5)
    %****** in this version moving large dots for motion RF
    P.snoisewidth = 25.0;  % radius of noise field around origin
    S.snoisewidth = 'Spatial noise width (degs, +/- origin):';
    P.snoiseheight = 15.0;  % radius of noise field around origin
    S.snoiseheight = 'Spatial noise height (degs, +/- origin):';
    P.snoisenum = 16; %8; %2; %8;   % number of white/black ovals to draw
    S.snoisenum = 'Number of noise ovals:';
    P.snoisediam = 1.0; %2.0; %1.0;  % diameter in dva of noise oval
    S.snoisediam = 'Diameter of noise ovals (dva): ';
    P.snoiselife = 6;  % lifetime in video frames
    S.snoiselife = 'Lifetime in frames';
    P.snoisespeed = 15;  % motion speed
    S.snoisespeed = 'Speed of dot';
    P.snoisedirs = 16;  % number of speed directions
    S.snoisedirs = 'Number of directions:';
    P.range = 127;
    S.range = 'Luminance range of grating (1-127):';
end
