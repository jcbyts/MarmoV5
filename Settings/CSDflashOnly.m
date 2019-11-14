
function [S,P] = CSDflashOnly

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
S.finish = 80;

% PROTOCOL PREFIX
S.protocol = 'CSDflashOnly';
% PROTOCOL PREFIXS
S.protocol_class = ['protocols.PR_',S.protocol];


%NOTE: in MarmoView2 subject is entered in GUI

%******** Don't allow in trial calibration for this one (comment out)
% P.InTrialCalib = 1;
% S.InTrialCalib = 'Eye Calib in Trials';
S.TimeSensitive = 1;

% STORE EYE POSITION DATA
% S.EyeDump = false;

% Define Banner text to identify the experimental protocol
% recommend maximum of ~28 characters
S.protocolTitle = 'Full field flash';

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

P.noisedur = 40;  % number of frames to hold on stim
S.noisedur = 'Frames on of stim: ';

P.noiseoff = 80;  % number of frames to hold on stim
S.noiseoff = 'Frames off of stim: ';

P.noiserange = 127;
S.noiserange = 'Luminance range of flash (1-127):';


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


P.iti = 1;
S.iti = 'Duration of intertrial interval (s):';
P.blank_iti = 1;
S.blank_iti = 'Duration of blank intertrial(s):';
P.abort_iti = 3;
S.abort_iti = 'Duration of abort intertrial(s):';
P.timeOut = 1;
S.timeOut = 'Time out for error (s):';

