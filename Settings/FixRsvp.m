function [S,P] = FixRsvp

%%%%% NECESSARY VARIABLES FOR GUI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD THE RIG SETTINGS, THESE HOLD CRUCIAL VARIABLES SPECIFIC TO THE RIG,
% IF A CHANGE IS MADE TO THE RIG, CHANGE THE RIG SETTINGS FUNCTION IN
% SUPPORT FUNCTIONS
S = MarmoViewRigSettings;

% NOTE THE MARMOVIEW VERSION USED FOR THIS SETTINGS FILE, IF AN ERROR, IT
% MIGHT BE A VERSION PROBLEM
S.MarmoViewVersion = '2';

% PARAMETER DESCRIBING TRIAL NUMBER TO STOP TASK
S.finish = 100;

% PROTOCOL PREFIX
S.protocol = 'FixRsvpStim';
% PROTOCOL PREFIXS
S.protocol_class = ['protocols.PR_',S.protocol];

% STORE EYE POSITION DATA
% S.EyeDump = false;

% Define Banner text to identify the experimental protocol
% recommend maximum of ~28 characters
S.protocolTitle = 'Fixation Point Training';

%********** allow calibratin of eye position during running
P.InTrialCalib = 1;
S.InTrialCalib = 'Eye Calib in Trials';
S.TimeSensitive = 2;  % state 2 is Gabor flashing, don't drop frames

%%%%% END OF NECESSARY VARIABLES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% PARAMETERS -- VARIABLES FOR TASK, CAN CHANGE WHILE RUNNING %%%%%%%%%
% INCLUDES STIMULUS PARAMETERS, DURATIONS, FLAGS FOR TASK OPTIONS
% MUST BE SINGLE VALUE, NUMERIC -- NO STRINGS OR ARRAYS!
% THEY ALSO MUST INCLUDE DESCRIPTION OF THE VALUE IN THE SETTINGS ARRAY

% Reward setting
P.rewardNumber = 1;
S.rewardNumber = 'Number of juice pulses to deliver:';

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
%  Currently not implemented, idea is 1 could be gabors, 2 could be pink
%  noise, 3 could be natural scenes, etc. Each distractor type would need
%  it's own parameters.
P.distractorType = 0;
S.distractorType = 'Parameter to add distractors:';

% Gaze indicator
P.eyeRadius = 1.2;
S.eyeRadius = 'Gaze indicator radius (degrees):';
P.eyeIntensity = 20;
S.eyeIntensity = 'Indicator intensity:';
P.showEye = 0;
S.showEye = 'Show the gaze indicator? (0 or 1):';

% Windows
P.fixWinRadius = 1.5;
S.fixWinRadius = 'Fixation window radius (deg):';

% Trial timing
P.startDur = 4;
S.startDur = 'Time to enter fixation (s):';
P.flashFrameLength = 32;   % make it slow, 250 ms
S.flashFrameLength = 'Length of fixation flash (frames):';
P.fixGrace = 0.05;
S.fixGrace = 'Grace period to be inside fix window (s):';
P.fixMin = 0.2;
S.fixMin = 'Minimum fixation (s):';
P.fixRan = 0.05;
S.fixRan = 'Random additional fixation (s):';
P.iti = 2;
S.iti = 'Duration of intertrial interval (s):';
P.timeOut = 1;
S.timeOut = 'Time out for error (s):';

P.GaborContrast = 100;   %from 0 to 100
S.GaborContrast = 'Contrast of Flashed Gabors:';
P.OriNum = 8;   %from 0 to 100
S.OriNum = 'Number of Gabor Orientations:';
P.gabRadius = 1.0;  % diameter is dva
S.gabRadius = 'Size of Gabor (dva):';
P.cpd = 2.0;
S.cpd = 'Gabor Spatial Freq (cyc/deg): ';
P.gabMaxRadius = 15.0;  % radius of noise field around fixation
S.gabMaxRadius = 'Max Radius of Noise Field (dva): ';
P.gabMinRadius = 2.0;  % min radius of noise field
S.gabMinRadius = 'Min Radius of Noise Field (dva): ';
P.faceRadius = 1.5;  % diameter is dva
S.faceRadius = 'Size of Face(dva):';

% Alternate ways for the run loop to control parameters
P.faceTrialFraction = 0;
S.faceTrialFraction = 'Fraction of trials with face:';
P.runType = 1;
S.runType = '0-User, 1-Staircase:';

% THESE SETTINGS ARE USED TO MANAGE PARAMETERS BASED ON THE RUN TYPE
% Staircasing settings, linear array with entries described below
% 1-minimum fixMin, 2-minimum fixRan, 3-maximum fixMin, 4-maximum fixRan 
S.staircase.durLims = [.2 .05 2 .65]; % Ideally differences are simply proportional for even increments/decrements
% Currently using 1/3 up/down ratio so marmo would be at 75% steady state
% 1-increase in fixMin, 2-increase in fixRan, if previous trial was correct
% S.staircase.up = [.25 .05];   % Original by Sam
S.staircase.up = [.20 .025];   % Shanna you can play with this
% 1-decrease in fixMin, 2-decrease in fixRan, if previous trial was incorrect
% S.staircase.down = S.staircase.up * (1/3);
S.staircase.down = S.staircase.up * .75;   % move down stairs as fast as up, smaller multiplication makes its harder
% If highest number the fixation duration exceeds indicates how many juice
% pulses, note it is weighted, so more juice for less time on long ones
% Marmo gets no juice if it doesn't complete the full fixation duration
%S.staircase.rewardSchedule = [0 .25 .35 .5 .7 .9 1.2 1.5 1.8 2.1 2.4 2.8];
S.staircase.rewardSchedule = [0 .5 1.0 1.5 2.0 2.5 3.0];  % less drops than before (too much), 
                                                          % each level up is one more drop
                                                          
