function varargout = MarmoV5(varargin)
% MARMOV5 M-file for MarmoV5.fig
%
%      THIS IS MARMOV5 VERSION 1B, THIS CORRESPONDS TO THE VERSION TEXT
%      IN THE MarmoV5.fig FILE
%
%      MARMOV5, by itself, creates a new MARMOV5 or raises the existing
%      singleton*.
%
%      H = MARMOV5 returns the handle to a new MARMOV5 or the handle to
%      the existing singleton*.
%
%      MARMOV5('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MARMOV5.M with the given input arguments.
%
%      MARMOV5('Property','Value',...) creates a new MARMOV5 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before MarmoV5_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to MarmoV5_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help MarmoV5

% Last Modified by GUIDE v2.5 23-Sep-2019 17:01:59

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MarmoV5_OpeningFcn, ...
                   'gui_OutputFcn',  @MarmoV5_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before MarmoV5 is made visible.
function MarmoV5_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to MarmoV5 (see VARARGIN)

% Choose default command line output for MarmoV5
handles.output = hObject;

%%%%% IMPORTANT GROUNDWORK FOR THE GUI IS PLACED HERE %%%%%%%%%%%%%%%%%%%%%

% GET SOME CRUCIAL DIRECTORIES -- THESE DIRECTORIES MUST EXIST!!
% Present working directory, location of all GUIs
handles.taskPath = [fullfile(pwd) filesep];
% Settings directory, settings files should be kept here
handles.settingsPath = fullfile(pwd, ['Settings' filesep]);
% Output directory, all data will be saved here!
handles.outputPath = fullfile(pwd, ['Output' filesep]);
% Support data directory, data to support MarmoV5 or its protocols can be
% kept here unintrusively (e.g. eye calibration values or marmoset images)
handles.supportPath = fullfile(pwd, ['SupportData' filesep]);
%****** start with no settings file
handles.settingsFile = 'none';
set(handles.SettingsFile,'String',handles.settingsFile);

% AS DEFAULT, THE GUI WILL USE THE CALIBRATION SETTINGS AT THE END OF THE
% LAST GUI RUN, THIS GUI SUPPORT DATA IS IN THE 'SUPPORT DATA' DIRECTORY,
% A different calibration file can be loaded, if specified as a field in
% the settings structure, but any changes made will only be saved to the
% default 'MarmoViewLastCalib.mat' -- I suspect this won't be used, but
% could be if two subjects had substantially different eye position gains
handles.calibFile = 'MarmoViewLastCalib.mat';
set(handles.CalibFilename,'String',handles.calibFile);

if exist(handles.calibFile, 'file')
    tmp = load([handles.supportPath handles.calibFile]);
    handles.C.dx = tmp.dx;
    handles.C.dy = tmp.dy;
    handles.C.c = tmp.c;
else
    handles.C.dx = .1;
    handles.C.dy = .1;
    handles.C.c = [0 0];
end

handles.eyeTraceRadius = 15;
% This C structure is never changed until a protocol is cleared or
% MarmoV5 is exited, until then, it may be reset to the C values using
% the ResetCalib callback.

% CREATE THE STRUCTURES USED BY ALL PROTOCOLS
handles.A = struct; % Values necessary for protocols to run current trial
handles.S = struct; % Settings for the protocol, NOT changed while running
handles.P = struct; % Parameters for the current protocol, changeable
handles.SI = handles.S;
handles.PI = struct;

%****** AT SOME POINT THIS TASK CONTROL MAY INCLUDE EPHYS TIMING WRAPPER
handles.FC = marmoview.FrameControl();   % create generic task control 

% LOAD RIG SETTINGS TO S, THIS IS RELOADED FOR EACH PROTOCOL, SO IT SHOULD
% BE LOCATED IN A DIRECTORY IN MATLAB'S PATH, I SUGGEST THE
% 'marmov5\SupportFunctions' DIRECTORY
handles.outputSubject = 'none';
S = MarmoViewRigSettings;
S.subject = handles.outputSubject;
handles.S = S;

%****** if a DummyEye, use mouse and change coordinates
%****** so the eye is estimated to be where the mouse is located
if handles.S.DummyEye
    handles.calibFile = 'Using Mouse as Eye';
    set(handles.CalibFilename,'String',handles.calibFile);
    cx = round((S.screenRect(3)-S.screenRect(1))/2) + S.screenRect(1);
    cy = round((S.screenRect(4)-S.screenRect(2))/2) + S.screenRect(2);
    dx = 1;   % stay in pixel coordinates
    dy = -1;  % in pixel coordinates, don't scale, but do invert y
    handles.C.dx = dx;
    handles.C.dy = dy;
    handles.C.c = [cx cy];
end

%********** if using the DataPixx, initialize it here
if (handles.S.DataPixx)
    datapixx.init();
end

% Load calibration variables into the A structure to be changed if needed
handles.A = handles.C;
% Add in the plot handles to A in case handles isn't available
% e.g. while running protocols)
handles.A.EyeTrace = handles.EyeTrace;
handles.A.DataPlot1 = handles.DataPlot1;
handles.A.DataPlot2 = handles.DataPlot2;
handles.A.DataPlot3 = handles.DataPlot3;
handles.A.DataPlot4 = handles.DataPlot4;
handles.A.outputFile = 'none';

% OPEN UP COMMUNICATION WITH THE PUMP FOR REWARD DELIVERY -- THIS IS DONE
% IMMEDIATELY USING THE RIG SETTINGS, SO THAT JUICE IS AVAILABLE TO THE
% MARMOSET WHILE NO PROTOCOLS ARE LOADED
if handles.S.newera % create an @newera object for delivering liquid reward
  handles.reward = marmoview.newera('port',S.pumpCom,'diameter',S.pumpDiameter,'volume',S.pumpDefVol,'rate',S.pumpRate);
%   handles.reward = marmoview.newera('port',S.pumpCom,'diameter',S.pumpDiameter,'volume',S.pumpDefVol,'rate',S.pumpRate, 'baud', 9600);
%   handles.reward.open();
%   handles.reward.diameter = S.pumpDiameter;
else % no syringe pump? use the @dbgreward object object instead
  if handles.S.solenoid
     handles.reward = marmoview.SolenoidControl(S.pumpCom); 
     S.pumpDefVol = handles.reward.volume;
     vol = sprintf('%d',S.pumpDefVol);
     set(handles.JuiceVolumeText,'String',[vol ' ms']); % displayed in microliters!!
  else
     handles.reward = marmoview.dbgreward(handles);
  end
end
% % TYPICALLY, I PREFER TO HANDLES LARGER/SMALLER REWARDS BY NUMBER OF PULSES
% INSTEAD OF CHANGING THE VOLUME, ALTHOUGH THE VOLUME CAN BE CHANGED, I
% SUGGEST ONLY USING A NUMBER OF JUICE PULSE PARAMETER FOR PROTOCOLS.
% !!!IF YOU DO CHANGE JUICE VOLUME, MAKE SURE THE PUMP IS GIVEN TIME TO
% DELIVER EACH PULSE BEFORE STARTING ON THE NEXT ONE, IT TAKES LONGER TO
% DELIVER A BIG JUICE PULSE THAN A SMALL ONE!!!
handles.A.juiceVolume = handles.reward.volume; %S.pumpDefVol;
% Also start a juice counter, for now at 0 -- It will be reset upon loading
% a new protocol and between trials. But it's changed with the give juice
% button, so best to assign it now
handles.A.juiceCounter = 0;

%******** ADDED VIA SHAUN ************************
%******* and then Arrington wrapper by Jude ******
if isfield(handles.S, 'eyetracker') && ischar(handles.S.eyetracker)
    switch handles.S.eyetracker
        case 'arrington'
            handles.eyetrack = marmoview.eyetrack_arrington(hObject,'EyeDump',S.EyeDump);
        case 'ddpi'
            handles.eyetrack = marmoview.eyetrack_ddpi(hObject,'EyeDump',S.EyeDump);
        case 'eyelink'
            % if EYELINK, you must wait until initializing the protocol to setup
            % the eye tracker .... for now, set it to a default object
            handles.eyetrack = marmoview.eyetrack();
            handles.S.eyelink = true;
        otherwise
            handles.eyetrack = marmoview.eyetrack();
    end
else % dump to the old version
    
    if handles.S.arrington % create an @arrington eyetrack object for eye position
        handles.eyetrack = marmoview.eyetrack_arrington(hObject,'EyeDump',S.EyeDump);
    elseif handles.S.eyelink
        % if EYELINK, you must wait until initializing the protocol to setup
        % the eye tracker .... for now, set it to a default object
        handles.eyetrack = marmoview.eyetrack();
    else % no eyetrack, use @eyetrack object instead that uses mouse pointer
        handles.eyetrack = marmoview.eyetrack();
    end
end

% treadmill.type = 'arduino';
% treadmill.port = 666;
% treadmill.channelA = 'D3';
% treadmill.channelB = 'D2';


if isfield(handles.S, 'treadmill') && isfield(handles.S.treadmill, 'type')
    switch handles.S.treadmill.type
        case 'arduino'
            handles.treadmill =  marmoview.treadmill_arduino('port', handles.S.treadmill.port, ...
                'baud', handles.S.treadmill.BaudRate);
            
        otherwise
            handles.treadmill = marmoview.treadmill_dummy();
    end
    
    % add the treadmill parameters
    fields = {'scaleFactor', 'rewardMode', 'rewardDist', 'rewardProb'};
    for f = 1:numel(fields)
        if isfield(handles.S.treadmill, fields{f})
            handles.treadmill.(fields{f}) = handles.S.treadmill.(fields{f});
            pName = ['tread' fields{f}];
            handles.P.(pName) = handles.S.treadmill.(fields{f});
            handles.S.(pName) = sprintf('Treadmill parameter %s', fields{f});
            handles.S.customTreadmillParams = true;
        end
    end
    
else
    handles.treadmill = marmoview.treadmill_dummy();
end

%********************************************************

%********* add the task controller for storing eye movements, flipping
%********* frames
% WRITE THE CALIBRATION DATA INTO THE EYE TRACKER PANEL AND GET THE SIZES 
% OF GAIN AND SHIFT CONTROLS FOR CALIBRATING EYE POSITION
% FOR UPDATE EYE TEXT TO RUN PROPPERLY, CALBIRATION MUST ALREADY BE IN
% STRUCTURE 'A'
UpdateEyeText(handles);
handles.shiftSize = str2double(get(handles.ShiftSize,'String'));
handles.gainSize = str2double(get(handles.GainSize,'String'));

% THESE VARIABLES CONTROL THE RUN LOOP
handles.runTask = false;
handles.stopTask = false;
%******** New parameters for running background image
handles.runOneTrial = false;
handles.runImage = false;
handles.lastRunWasImage = false;

% SET ACCESS TO GUI CONTROLS
set(handles.Initialize,'Enable','Off');
set(handles.ClearSettings,'Enable','Off');
set(handles.RunTrial,'Enable','Off');
set(handles.PauseTrial,'Enable','Off');
set(handles.FlipFrame,'Enable','Off');
set(handles.ParameterPanel,'Visible','Off');
set(handles.EyeTrackerPanel,'Visible','Off');
set(handles.Background_Image,'Enable','Off');
set(handles.Calib_Screen,'Enable','Off');
set(handles.TaskPerformancePanel,'Visible','Off');
set(handles.SettingsPanel,'Visible','Off');

% Force to select subject name first thing
set(handles.OutputPrefixEdit,'Enable','Off');
set(handles.OutputSubjectEdit,'String','none');
handles.outputSubject = 'none';
% set(handles.OutputSubjectEdit,'Enable','Off');   %user can edit this!
set(handles.OutputDateEdit,'Enable','Off');
set(handles.OutputSuffixEdit,'Enable','Off');
%****** set names to empty for starting
handles.outputPrefix = [];
handles.outputDateEdit = [];
handles.outputSuffixEdit = [];
%**************
tstring = 'Please select SUBJECT to begin';
set(handles.StatusText,'String',tstring);

% For the protocol title, note that no protocol has been loaded yet
set(handles.ProtocolTitle,'String','No protocol is loaded.');
% The task light is a neutral gray when no protocol is loaded
ChangeLight(handles.TaskLight,[.5 .5 .5]);
UpdateEyeText(handles);

% Update handles structure
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = MarmoV5_OutputFcn(hObject, eventdata, handles)  %#ok<*INUSL>
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


%%%%% SETTINGS PANEL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHOOSE A SETTINGS FILE
function ChooseSettings_Callback(hObject, eventdata, handles) %#ok<*DEFNU>
% Go into the settings path
cd(handles.settingsPath);
% Have user select the file
handles.settingsFile = uigetfile;
% Show the selected outputfile
if handles.settingsFile ~= 0
    set(handles.SettingsFile,'String',handles.settingsFile);
else
% Or no outputfile if cancelled selection
    set(handles.SettingsFile,'String','none');
    handles.settingsFile = 'none';
end
% If file exists, then we can get the protocol initialized
if exist(handles.settingsFile,'file')
    if (strcmp(handles.outputSubject,'none'))
       set(handles.Initialize,'Enable','off');
       tstring = 'Please select SUBJECT NAME >>>';
    else
       set(handles.Initialize,'Enable','on');
       tstring = 'Ready to initialize protocol...';
    end
else
    set(handles.Initialize,'Enable','off');
    tstring = 'Please select a settings file...';
end
% Regardless, update status
set(handles.StatusText,'String',tstring);
% Return to task directory
cd(handles.taskPath);

% Update handles structure
guidata(hObject, handles);


% INITIALIZE A PROTOCOL FROM THE SETTINGS SELECTED
function Initialize_Callback(hObject, eventdata, handles)
% PREPARE THE GUI FOR INITIALIZING THE PROTOCOL
% Update GUI status
set(handles.StatusText,'String','Initializing...');
% The task light is blue only during protocol initialization
ChangeLight(handles.TaskLight,[.2 .2 1]);

% TURN OFF BUTTONS TO PREVENT FIDDLING DURING INITIALIZATION
set(handles.ChooseSettings,'Enable','Off');
set(handles.Initialize,'Enable','Off');
set(handles.OutputSubjectEdit,'Enable','Off'); % subject already set
% Effect these changes on the GUI immediately
guidata(hObject, handles); drawnow;

% GET PROTOCOL SETTINGS
cd(handles.settingsPath);
cmd = sprintf('[handles.S,handles.P] = %s;',handles.settingsFile(1:end-2));
eval(cmd);
handles.S.subject = handles.outputSubject;
cd(handles.taskPath);

% add the treadmill parameters
if isfield(handles.S, 'treadmill')
    fields = {'scaleFactor', 'rewardMode', 'rewardDist', 'rewardProb'};
    for f = 1:numel(fields)
        if isfield(handles.S.treadmill, fields{f})
            handles.treadmill.(fields{f}) = handles.S.treadmill.(fields{f});
            pName = ['tread' fields{f}];
            handles.P.(pName) = handles.S.treadmill.(fields{f});
            handles.S.(pName) = sprintf('Treadmill parameter %s', fields{f});
        end
    end
end

% MOVE THE GUI OFF OF THE VISUAL STIMULUS SCREEN TO THE CONSOLE SCREEN
% THIS IS CHANGED IN PROTOCOL SETTINGS AND IS NOT A NECESSARY SETTING
if isfield(handles.S,'guiLocation')
    set(handles.figure1,'Position',handles.S.guiLocation);
end

% SHOW THE PROTOCOL TITLE
set(handles.ProtocolTitle,'String',handles.S.protocolTitle);

% OPEN THE PBT SCREEN
handles.A = marmoview.openScreen(handles.S,handles.A);

% INITIALIZE THE PROTOCOL
cmd = sprintf('handles.PR = %s(handles.A.window);',handles.S.protocol_class);
eval(cmd);   %Establishes the PR object
%***************
% GENERATE DEFAULT TRIALS LIST
handles.PR.generate_trialsList(handles.S,handles.P);
%*****************
handles.PR.initFunc(handles.S, handles.P);
%***************

% ALSO GENERATE A BACKGROUND IMAGE VIEWER PROTOCOL
%********* Setup Image Viewer Protocol ******************
cd(handles.settingsPath);
[handles.SI,handles.PI] = BackImage;
cd(handles.taskPath);
% INITIALIZE THE Back Image Protocl 
handles.PRI = protocols.PR_BackImage(handles.A.window);
handles.PRI.generate_trialsList(handles.SI,handles.PI);
handles.PRI.initFunc(handles.SI, handles.PI);
%***************

%*****************************************

% INITIALIZE THE TASK CONTROLLER FOR THE TRIAL
handles.FC.initialize(handles.A.window, handles.P, handles.C, handles.S);

% SET UP THE OUTPUT PANEL
% Get the output file name components
handles.outputPrefix = handles.S.protocol;
set(handles.OutputPrefixEdit,'String',handles.outputPrefix);
set(handles.OutputSubjectEdit,'String',handles.outputSubject);
handles.outputDate = datestr(now,'ddmmyy');
set(handles.OutputDateEdit,'String',handles.outputDate);
i = 0; handles.outputSuffix = '00';
% Generate the file name
handles.A.outputFile = strcat(handles.outputPrefix,'_',handles.outputSubject,...
    '_',handles.outputDate,'_',handles.outputSuffix,'.mat');
% If the file name already exists, iterate the suffix to a nonexistant file
while exist([handles.outputPath handles.A.outputFile],'file')
    i = i+1; handles.outputSuffix = num2str(i,'%.2d');
    handles.A.outputFile = strcat(handles.outputPrefix,'_',handles.outputSubject,...
        '_',handles.outputDate,'_',handles.outputSuffix,'.mat');
end



% FOR EYELINK, you cannot setup until you have screen pointer and each
% edf file is created per opening the screen
if handles.S.eyelink
    if handles.S.EyeDump
               eyeFile = sprintf('%s_%s_%s_%s', ...
                              handles.outputPrefix, ...
                              handles.outputSubject, ...
                              handles.outputDate, ...
                              handles.outputSuffix);
               eyePath = handles.outputPath;
    else
               eyeFile = [];
               eyePath = [];
    end
    handles.eyetrack = marmoview.eyetrack_eyelink(hObject,handles.A.window,eyeFile,eyePath,...
                         'EyeDump',handles.S.EyeDump,'screen', handles.S.screenNumber); 
end

%*********** ADDED VIA SHAUN
% SC: eye posn data
handles.eyetrack.startfile(handles);
%
%*************************

% Show the file name on the GUI
set(handles.OutputSuffixEdit,'String',handles.outputSuffix);
set(handles.OutputFile,'String',handles.A.outputFile);
% Note that a new output file is being used
handles.A.newOutput = 1;

% SET UP THE PARAMETERS PANEL
% Trial counting section of the parameters
handles.A.j = 1; handles.A.finish = handles.S.finish;
set(handles.TrialCountText,'String',['Trial ' num2str(handles.A.j-1)]);
set(handles.TrialMaxText,'String',num2str(handles.A.finish));
set(handles.TrialMaxEdit,'String','');

% Get strings for the parameters list
handles.pNames = fieldnames(handles.P);         % pNames are the actual parameter names
handles.pList = cell(size(handles.pNames,1),1); % pList is the list of parameter names with values
for i = 1:size(handles.pNames,1)
    pName = handles.pNames{i};
    tName = sprintf('%s = %2g',pName,handles.P.(pName));
    handles.pList{i,1} = tName;
end

% add parameters to GUI
set(handles.Parameters,'String',handles.pList);
% For the highlighted parameter, provide a description and editable value
set(handles.Parameters,'Value',1);
set(handles.ParameterText,'String',handles.S.(handles.pNames{1}));
set(handles.ParameterEdit,'String',num2str(handles.P.(handles.pNames{1})));

% UPDATE ACCESS TO CONTROLS
set(handles.RunTrial,'Enable','On');
set(handles.FlipFrame,'Enable','On');
set(handles.ClearSettings,'Enable','On');
set(handles.ParameterPanel,'Visible','On');
set(handles.EyeTrackerPanel,'Visible','On');
set(handles.OutputPanel,'Visible','On');
set(handles.OutputSubjectEdit,'Enable','Off');
set(handles.OutputPrefixEdit,'Enable','Off');
set(handles.OutputDateEdit,'Enable','Off');
set(handles.OutputSuffixEdit,'Enable','Off');
set(handles.TaskPerformancePanel,'Visible','On');
set(handles.Background_Image,'Enable','On');
set(handles.Calib_Screen,'Enable','On');
%******* allow for graph zoom in and out
set(handles.GraphZoomIn,'Enable','On');
set(handles.GraphZoomOut,'Enable','On');

%*******Blank the eyetrace plot
h = handles.EyeTrace;
eyeRad = handles.eyeTraceRadius;
set(h,'NextPlot','Replace');
plot(h,0,0,'+k','LineWidth',2);
set(h,'NextPlot','Add');
plot(h,[-eyeRad eyeRad],[0 0],'--','Color',[.5 .5 .5]);
plot(h,[0 0],[-eyeRad eyeRad],'--','Color',[.5 .5 .5]);
axis(h,[-eyeRad eyeRad -eyeRad eyeRad]);
%*************************

if handles.S.DummyEye
    EnableEyeCalibration(handles,'Off');  %dont update if Dummy, use mouse
    %******* but allow for graph zoom in and out
    set(handles.GraphZoomIn,'Enable','On');
    set(handles.GraphZoomOut,'Enable','On');
end

% UPDATE GUI STATUS
set(handles.StatusText,'String','Protocol is ready to run trials.');
% Now that a protocol is loaded (but not running), task light is red
ChangeLight(handles.TaskLight,[1 0 0]);

% FINALLY, RESET THE JUICE COUNTER WHENEVER A NEW PROTOCOL IS LOADED
handles.A.juiceCounter = 0;

% UPDATE HANDLES STRUCTURE
guidata(hObject,handles);


% UNLOAD CURRENT PROTOCOL, RESET GUI TO INITIAL STATE
function ClearSettings_Callback(hObject, eventdata, handles)

% DISABLE RUNNING THINGS WHILE CLEARING
set(handles.RunTrial,'Enable','Off');
set(handles.FlipFrame,'Enable','Off');
set(handles.ClearSettings,'Enable','Off');
set(handles.ChooseSettings,'Enable','On');
set(handles.Initialize,'Enable','On');
set(handles.OutputPanel,'Visible','Off');
set(handles.ParameterPanel,'Visible','Off');
set(handles.EyeTrackerPanel,'Visible','Off');
set(handles.OutputPanel,'Visible','Off');
set(handles.TaskPerformancePanel,'Visible','Off');
set(handles.Background_Image,'Enable','Off');
set(handles.Calib_Screen,'Enable','Off');

% Clear plots
plot(handles.DataPlot1,0,0,'+k');
plot(handles.DataPlot2,0,0,'+k');
plot(handles.DataPlot3,0,0,'+k');
plot(handles.DataPlot4,0,0,'+k');

% Eye trace needs to be treated differently to maintain important
% properties
plot(handles.EyeTrace,0,0,'+k');
set(handles.EyeTrace,'UserData',15); % 15 degrees of visual arc is default

%****** ADDED VIA SHAUN **********
%%% SC: eye posn data
% tell ViewPoint to close the eye posn data file
handles.eyetrack.closefile();
%*************************

% DE-INITIALIZE PROTOCOL (remove screens or objects created on init)
handles.PR.closeFunc();  % de-initialize any objects 
handles.PRI.closeFunc(); % close the back-ground image protocol
handles.lastRunWasImage = false;

% REFORMAT DATA FILES TO CONDENSED STRUCT
CondenseAppendedData(hObject, handles)

% Close all screens from ptb
sca;

% Save the eye calibration values at closing time to the MarmoViewLastCalib
c = handles.A.c;
dx = handles.A.dx;
dy = handles.A.dy;
if ~handles.S.DummyEye 
  save([handles.supportPath 'MarmoViewLastCalib.mat'],'c','dx','dy');
end
% Create a structure for A that maintains only basic values required
% outside the protocol
handles.C.c = c; handles.C.dx = dx; handles.C.dy = dy;
A = handles.C;
A.EyeTrace = handles.EyeTrace;
A.DataPlot1 = handles.DataPlot1;
A.DataPlot2 = handles.DataPlot2;
A.DataPlot3 = handles.DataPlot3;
A.DataPlot4 = handles.DataPlot4;
A.outputFile = 'none';

% Reset structures
handles.A = A;
handles.S = MarmoViewRigSettings;
handles.S.subject = handles.outputSubject;
handles.P = struct;
handles.SI = handles.S;
handles.PI = struct;
% If juicer delivery volume was changed during the previous protocol,
% return it to default. Also add the juice counter for the juice button.
% fprintf(handles.A.pump,['0 VOL ' num2str(handles.S.pumpDefVol)]);
% handles.reward.volume = handles.S.pumpDefVol; % milliliters
handles.A.juiceVolume = handles.reward.volume;
handles.A.juiceCounter = 0;
if handles.S.solenoid
  set(handles.JuiceVolumeText,'String',sprintf('%3i ms',handles.A.juiceVolume));  
else
  set(handles.JuiceVolumeText,'String',sprintf('%3i ul',handles.A.juiceVolume));
end

% RE-ENABLE CONTROLS
set(handles.ChooseSettings,'Enable','On');
% Initialize is only available if the settings file exists
handles.settingsFile = get(handles.SettingsFile,'String');
if ~exist([handles.settingsPath handles.settingsFile],'file')
    set(handles.Initialize,'Enable','off');
    tstring = 'Please select a settings file...';
else
    set(handles.Initialize,'Enable','on');
    tstring = 'Ready to initialize protocol...';
end
% Update GUI status
set(handles.StatusText,'String',tstring);
% For the protocol title, note that no protocol is now loaded
set(handles.ProtocolTitle,'String','No protocol is loaded.');
% The task light is a neutral gray when no protocol is loaded
ChangeLight(handles.TaskLight,[.5 .5 .5]);

%****** RE-ENABLE THE SUBJECT ENTRY, in case want to change subject and
%****** continue the program without closing MarmoV5 (should be rare)
set(handles.OutputPanel,'Visible','On');
set(handles.OutputPrefixEdit,'Enable','Off');
set(handles.OutputSubjectEdit,'Enable','On');   %user can edit this!
set(handles.OutputDateEdit,'Enable','Off');
set(handles.OutputSuffixEdit,'Enable','Off');

% Update handles structure
guidata(hObject, handles);



%%%%% TRIAL CONTROL PANEL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function RunTrial_Callback(hObject, eventdata, handles)
% SET THE TASK TO RUN
handles.runTask = true;

%********* store what is the current EyeTrace to plot, based on 
%********* what protocol is most recently called (image or other)
if ~handles.runImage
    handles.lastRunWasImage = false;
else
    handles.lastRunWasImage = true;
end
%****************************

% SET TASK LIGHT TO GREEN
ChangeLight(handles.TaskLight,[0 1 0]);
%*********

%****** NOTE, maybe you can turn off some graphics figure features
%******  like resize and move functions in the future

%****** Gray out controls so it is clear you can't press them
set(handles.RunTrial,'Enable','Off');
set(handles.FlipFrame,'Enable','Off');
set(handles.Background_Image,'Enable','Off');
set(handles.Calib_Screen,'Enable','Off');
set(handles.CloseGui,'Enable','Off');
set(handles.ClearSettings,'Enable','Off')
set(handles.ChooseSettings,'Enable','Off');
set(handles.Initialize,'Enable','Off');
set(handles.OutputPrefixEdit,'Enable','Off');
% set(handles.OutputSubjectEdit,'Enable','Off');
set(handles.OutputDateEdit,'Enable','Off');
set(handles.OutputSuffixEdit,'Enable','Off');
%********** even more turned off
set(handles.Parameters,'Enable','Off');
set(handles.TrialMaxEdit,'Enable','Off');
set(handles.JuiceVolumeEdit,'Enable','Off');
set(handles.ChooseSettings,'Enable','Off');
set(handles.Initialize,'Enable','Off');
set(handles.ParameterEdit','Enable','Off');
%********* Optional Turn Offs *****************
%****** These might remain on for calib eye
if ( isfield(handles.P,'InTrialCalib') && (handles.P.InTrialCalib == 1) && ...
        (~handles.S.DummyEye) )  %dont allow calibration if dummy screen (use mouse)
  if ~handles.S.DummyEye
     EnableEyeCalibration(handles,'On');
  else
     EnableEyeCalibration(handles,'Off');
     set(handles.GraphZoomIn,'Enable','On');
     set(handles.GraphZoomOut,'Enable','On');
  end
  UpdateEyeText(handles);
else
  EnableEyeCalibration(handles,'Off');
  UpdateEyeText(handles);
end
%********** leave the pause button functioning **
set(handles.PauseTrial,'Enable','On');
%***********************************************

%************ ADDED VIA SHAUN ****
%%% SC: eye posn data
% 1. tell ViewPoint to (re-)start recording of eye posn data
handles.eyetrack.unpause();
%%%
%********************************

% UPDATE GUI STATUS
set(handles.StatusText,'String','Protocol trials are running.');

% RESET THE JUICER COUNTER BEFORE ENTERING THE RUN LOOP
handles.A.juiceCounter = 0;
% UPDATE THE HANDLES 
guidata(hObject,handles); drawnow;

% MOVE TASK RELATED STRUCTURES OUT OF HANDLES FOR THE RUN LOOP -- this way
% if a callback interrupts the run task function, we can update any changes
% the interrupting callback makes to handles without affecting those task
% related structures. E.g. we can run the task using parameters as they 
% were at the start of the trial, while getting ready to cue any changes 
% the user made on the next trial.
A = handles.A;   % these structs are small enough we will pass them
if ~handles.runImage
  S = handles.S;   % as arguments .... don't make them huge ... larger
  P = handles.P;   % data should stay in D, or inside the PR or FC objects
else
  S = handles.SI;  % pull other arguments for image protocol
  P = handles.PI;
end
% IF NOT DATA FILE OPENED, CREATE AND INSERT S Struct first
%****** ONCE OPENED, YOU ONLY APPEND TO THAT FILE EACH TRIAL NEW DATA    
cd(handles.outputPath);             % goto output directory
if ~exist(A.outputFile)
  save(A.outputFile,'S');     % save settings struct to output file
end
cd(handles.taskPath);               % return to task directory

%****** pass in any updated calibration params (can calib when paused!)
handles.FC.update_eye_calib(A.c,A.dx,A.dy);
%****** also, check if user turned on showEye during a pause
handles.FC.update_args_from_Pstruct(P);  %showEye, eyeIntensity, eye Radius, ...
%*********************************

% RUN TRIALS
CorCount = 0;   % count consecutive correct trials (for BackImage interleaving)
SetRunBack = 0; % flag for swapping to interleaved image trials and back
%******* 
while handles.runTask && A.j <= A.finish   
    % 'pause', 'drawnow', 'figure', 'getframe', or 'waitfor' will allow
    % other callbacks to interrupt this run task callback -- be aware that
    % if handles aren't properly managed then changes either in the run
    % loop or in other parts of the GUI may be out-of-sync. Nothing changes
    % to GUI-wide handles until the local callback puts them there. If
    % other callbacks change handles, and they are not brought into this
    % callback, then those changes are lost when this run loop updates that
    % handles. This concept is explained further right below during the 
    % nextCmd handles management.
    
    %******* Check if automatic interleaving of BackImage trials
    %******* and set the trial accordingly
    if isfield(handles.P,'CycleBackImage')
       if handles.P.CycleBackImage > 0 
           if ~mod((CorCount+1),handles.P.CycleBackImage)
              handles.runImage = true;
              SetRunBack = 1;
              S = handles.SI;
              P = handles.PI;
           end
       end
    end
    %*****************************
    P.rng_before_trial = rng(); % save current state of the random number generator
    
    % set which protocol to use
    if handles.runImage
        PR = handles.PRI;
    else
        PR = handles.PR;
    end
    
%     if isa(PR, 'protocols.protocol')
%         PR = copy(PR); % unlink PR from handles.PR
%     end

    % EXECUTE THE NEXT TRIAL COMMAND
    P = PR.next_trial(S,P);
    
    % UPDATE IN CASE JUICE VOLUME WAS CHANGED USING A PARAMETER
    if handles.A.juiceVolume ~= A.juiceVolume
        handles.reward.volume = A.juiceVolume; % A.juiceVolume is in milliliters
        if (handles.S.solenoid)
           set(handles.JuiceVolumeText,'String',sprintf('%3i ms',A.juiceVolume*1e3));     
        else
           set(handles.JuiceVolumeText,'String',sprintf('%3i ul',A.juiceVolume*1e3));
        end
        handles.A.juiceVolume = A.juiceVolume;
    end
    % UPDATE HANDLES FROM ANY CHANGES DURING NEXT TRIAL -- IF THIS ISN'T
    % DONE, THEN THE OTHER CALLBACKS WILL BE USING A DIFFERENT HANDLES
    % STRUCTURE THAN THIS LOOP IS
    guidata(hObject,handles);
    % ALLOW OTHER CALLBACKS INTO THE QUEUE AND UPDATE HANDLES -- 
    % HERE, HAVING UPDATED ANY RUN LOOP CHANGES TO HANDLES, WE LET OTHER
    % CALLBACKS DO THEIR THING. WE THEN GRAB THOSE HANDLES SO THE RUN LOOP
    % IS ON THE SAME PAGE. FORTUNATELY, IF A PARAMETER CHANGES IN HANDLES,
    % THAT WON'T AFFECT THE CURRENT TRIAL WHICH IS USING 'P', NOT handles.P
    pause(.001); handles = guidata(hObject);
    
    % EXECUTE THE RUN TRIAL COMMAND
    % eval(handles.runCmd);
    
    %******** IMPLEMENT DEFAULT RUN TRIAL HERE DIRECTLY **********
    %***** Note, PR will refer to the PROTOCOL object ************
    [FP,TS] = PR.prep_run_trial();

    handles.FC.set_task(FP,TS);  % load values into class for plotting (FP)
                                 % and to label TimeSensitive states (TS)
    % Task Controller flips first frame and logs the trial start
    [ex,ey] = handles.eyetrack.getgaze();
    pupil = handles.eyetrack.getpupil();
    
    % treadmill reset
    handles.treadmill.reset();
    
    %******* This is where to perform TimeStamp Syncing (start of trial)
    STARTCLOCK = handles.FC.prep_run_trial([ex,ey],pupil);
    STARTCLOCKTIME = GetSecs;
    if (S.DataPixx)
       datapixx.strobe(63,0);  % send all bits on to mark trial start 
    end
    %***********************
    tstring = sprintf('dataFile_InsertString "TRIALSTART:TRIALNO:%5i %2d %2d %2d %2d %2d %2d"',...
                       handles.A.j,STARTCLOCK(1:6));   % code the sixlet
    STARTMESSAGE = str2double(sprintf('%02d', STARTCLOCK));
    handles.eyetrack.sendcommand(tstring,STARTMESSAGE);
    
    %***********************************************************
    if (S.DataPixx)
        for k = 1:6
           datapixx.strobe(STARTCLOCK(k),0);
        end
    end
    %**************************************************
    
    %%%%% Start trial loop %%%%%
    rewardtimes = [];
    runloop = 1;
    %****** added to control when juice drop is delivered based on graphics
    %****** demands, drop juice on frames with low demands basically
    screenTime = GetSecs;
    frameTime = (0.5/handles.S.frameRate);
    holdrop = 0;
    dropreject = 0;
    %**************
    while runloop
       
       state = PR.get_state();
       
       %%%%% GET ON-LINE VALUES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       [ex,ey] = handles.eyetrack.getgaze();
       pupil = handles.eyetrack.getpupil();
       [currentTime,x,y] = handles.FC.grabeye_run_trial(state,[ex,ey],pupil);
       %**********************************

       drop = PR.state_and_screen_update(currentTime,x,y);
       
       % treadmill
       drop = handles.treadmill.afterFrame(currentTime, drop);
       
       %******* One idea, only deliver drop if there is alot of time
       %******* before the next screen flush (since drop command takes time)
       if ( drop > 0)
           holdrop = 1;
           dropreject = 0;
       end
       if  (holdrop > 0)
           droptime = GetSecs;
           if ( (droptime-screenTime) < frameTime) || (dropreject > 12)
              holdrop = 0; 
              rewardtimes = [rewardtimes droptime];
              handles.reward.deliver();
           else
              dropreject = dropreject + 1; 
           end
       end
       %**********************************
%        if  (drop > 0)
%            rewardtimes = [rewardtimes GetSecs];
%            handles.reward.deliver();
%        end
       %**********************************
       % EYE DISPLAY (SHOWEYE), SCREEN FLIP, and 
       % ANY GUI UPDATING (if not time sensitive states)
       [updateGUI,screenTime] = handles.FC.screen_update_run_trial(state);
       %********* returns the time of screen flip **********
       if updateGUI  
           drawnow;  % regrettable that this has to be included to grab the pause button hit
           % Update any changes made to the calibration  
           handles = guidata(hObject);
           %*** pass update back into task controller
           A.c = handles.A.c;
           A.dx = handles.A.dx;
           A.dy = handles.A.dy;
           handles.FC.update_eye_calib(A.c,A.dx,A.dy);
       end
       
        runloop = PR.continue_run_trial(screenTime);
    end
        
    %******** Update eye trace window before ITI start
    ENDCLOCK = handles.FC.last_screen_flip();   % set screen to gray, trial over, start ITI
    ENDCLOCKTIME = GetSecs;
    %******* the data pix strobe will take about 0.5 ms **********
    if (S.DataPixx)
       datapixx.strobe(62,0);  % send all bits on but first (254) to mark trial end  
    end
    %****** AGAIN this is a place for timing event to synch up trial ends 
    % this takes about 2 ms to send VPX command string
    tstring = sprintf('dataFile_InsertString "TRIALENDED:TRIALNO:%5i %2d %2d %2d %2d %2d %2d"',...
                       handles.A.j,ENDCLOCK(1:6));   % code the sixlet
    ENDMESSAGE = str2double(sprintf('%02d', ENDCLOCK));
    handles.eyetrack.sendcommand(tstring,ENDMESSAGE);
    handles.eyetrack.endtrial();
    %****** send the rest of the sixlet via DataPixx
    % this sixlet of numbers takes about 2 ms, but not used for time strobe
    if (S.DataPixx)
       for k = 1:6
           datapixx.strobe(ENDCLOCK(k),0);
       end
    end
    %**********************************************************
    
    %******** Any final clean-up for PR in the trial
    Iti = PR.end_run_trial();
    
    %*************************************************************
    % PLOT THE EYETRACE and enforce an ITI interval
    itiStart = GetSecs;
    subplot(handles.EyeTrace); hold off;  % clear old plot

    PR.plot_trace(handles); hold on; % command to plot on eye traces 
    
    handles.FC.plot_eye_trace_and_flips(handles);  %plot the eye traces
    % eval(handles.plotCmd);
    while (GetSecs < (itiStart + Iti))
         drawnow;   % grab GUI events while running ITI interval    
         handles = guidata(hObject);
    end
    %*************************************
    
    % UPDATE HANDLES FROM ANY CHANGES DURING RUN TRIAL
    guidata(hObject,handles);
    % ALLOW OTHER CALLBACKS INTO THE QUEUE AND UPDATE HANDLES
    pause(.001); handles = guidata(hObject);
        
    % SKETCH OF MY DATA SOLUTION HERE (I hated that it was passing
    %                                  a big D struct into functions)
    %  D should be a struct that stores per trial data (not everything)
    %    D.P has trial parameters (struct)
    %    D.eyeData has the eye trace (matrix)
    %    D.PR has feedback from the protocol (struct)
    %       if the protocol is complicated (rev cor), this could be large
    %       for example, might list every stim shown per frame in trial
    %    D.C has the eye calibration (struct)
    % ******************************
    %  In this scenario, the PR.end_plots does not get D at all.
    %  What does that mean, if your PR wants to plot stats over trials
    %  then it must store its own internal D with that information in
    %  a list .... so the experimenter needs to police this function.  
    %  It will get the P struct and A each trial and can update then.
    
    %********* Some Data is uploaded automatically from Task Controller
    D = struct;
    D.P = P; % THE TRIAL PARAMETERS
    D.STARTCLOCKTIME = STARTCLOCKTIME;
    D.ENDCLOCKTIME = ENDCLOCKTIME;
    D.STARTCLOCK = STARTCLOCK;
    D.ENDCLOCK = ENDCLOCK;
    
    D.PR = PR.end_plots(P,A);   %if critical trial info save as D.PR
    
    if ~handles.runImage
       D.PR.name = handles.S.protocol;
       if (D.PR.error == 0)
           CorCount = CorCount + 1;
       end
    else
       D.PR.name = 'BackImage';
    end
    D.eyeData = handles.FC.upload_eyeData();
    [c,dx,dy] = handles.FC.upload_C();
    D.c = c;
    D.dx = dx;
    D.dy = dy;
    D.rewardtimes = rewardtimes;    % log the time of juice pulses
    D.juiceButtonCount = handles.A.juiceCounter; % SUPPLEMENTARY JUICE DURING THE TRIAL
    D.juiceVolume = A.juiceVolume; % THE VOLUME OF JUICE PULSES DURING THE TRIAL
    D.treadmill = copy(handles.treadmill); % is this the best way?
    D.treadmill.locationSpace(D.treadmill.frameCounter:end,:) = [];
    
    %***************
    % SAVE THE DATA
    % here is a place to think as well ... what is the best way to save D?
    % can we append to a Matlab file only those parts news to the trial??
    cd(handles.outputPath);             % goto output directory
    Dstring = sprintf('D%d',A.j);       % will store trial data in this variable
    eval(sprintf('%s = D;',Dstring));   % set variable 
    save(A.outputFile,'-append','S',Dstring);   % append file
    cd(handles.taskPath);               % return to task directory
    eval(sprintf('clear %s;',Dstring));
    clear D;                 % release the memory for D once saved
    %************** END OF THE TRIAL DATA SECTION *************************
    
    % UPDATE TRIAL COUNT AND FINISH NUMBER
    A.j = A.j+1;
    set(handles.TrialCountText,'String',num2str(A.j-1));
    if ~handles.runOneTrial
      A.finish = handles.A.finish;
      set(handles.TrialMaxText,'String',num2str(A.finish));
    end
    % UPDATE IN CASE JUICE VOLUME WAS CHANGED DURING END TRIAL
    if handles.A.juiceVolume ~= A.juiceVolume
        fprintf(A.pump,['0 VOL ' num2str(A.juiceVolume/1000)]);
        if handles.S.solenoid
           set(handles.JuiceVolumeText,'String',[num2str(A.juiceVolume) ' ms']);           
        else
           set(handles.JuiceVolumeText,'String',[num2str(A.juiceVolume) ' ul']);
        end
    end
    
    % UPDATE THE TASK RELATED STRUCTURES IN CASE OF LEAVING THE RUN LOOP
    handles.A = A;
    if ~handles.runImage
      handles.S = S;
      handles.P = P;
    else
      handles.SI = S;
      handles.PI = P;    
    end
    %****** if it was an interleave Image trial, set it back proper
    if (SetRunBack == 1)
        handles.runImage = false;
        SetRunBack = 0;
        S = handles.S;
        P = handles.P;
        CorCount = 0;
    end
    %************************************
   
    % UPDATE THE PARAMETER LIST TO SHOW THE NEXT TRIAL PARAMETERS
    % NOTE, if running background image it is not listing the params
    %  but rather than main protocols params, in P struct, not PI struct
    for i = 1:size(handles.pNames,1)
        pName = handles.pNames{i};
        tName = sprintf('%s = %2g',pName,handles.P.(pName));
        handles.pList{i,1} = tName;
    end
    set(handles.Parameters,'String',handles.pList);
    
    % UPDATE THE HANDLES STRUCTURE FROM ALL OF THESE CHANGES
    guidata(hObject,handles);
    % ALLOW OTHER CALLBACKS INTO THE THE QUEUE. IF PARAMETERS ARE CHANGED
    % BY CHANCE THIS LATE IN THE LOOP, THEY WILL NOT BE CHANGED UNTIL
    % REACHING THE END OF THE NEXT TRIAL, BECAUSE P HAS ALREADY BEEN
    % ESTABLISHED FOR THE NEXT TRIAL. IF YOU EXIT THE LOOP, THOUGH, THEN P
    % WILL BE UPDATED BY ANY CHANGES TO THE HANDLES
    pause(.001); handles = guidata(hObject);
    
    % STOP RUN TASK IF SET TO DO SO
    if handles.stopTask || handles.runOneTrial
        handles.runTask = false;
    end
end

%***** ADDED VIA SHAUN ********
%%% SC: eye posn data
% tell ViewPoint to pause recording of eye posn data
handles.eyetrack.pause();
%%%
%******************************

% NO TASK RUNNING FLAGS SHOULD BE ON ANYMORE
handles.runTask = false;
handles.stopTask = false;

% UPDATE THE PARAMETERS LIST IN CASE OF ANY CHANGES MADE AFTER RUNNING THE
% END TRIAL COMMAND
for i = 1:size(handles.pNames,1)
    pName = handles.pNames{i};
    tName = sprintf('%s = %2g',pName,handles.P.(pName));
    handles.pList{i,1} = tName;
end
set(handles.Parameters,'String',handles.pList);

%********* TURN GUI BACK ON
% set(jWindow,'Enable',1);  %turns off everything, figure is halted
%********* Optional Turn Offs *****************
%****** Gray out controls so it is clear you can't press them
set(handles.RunTrial,'Enable','On');
set(handles.FlipFrame,'Enable','On');
set(handles.Background_Image,'Enable','On');
set(handles.Calib_Screen,'Enable','On');
set(handles.CloseGui,'Enable','On');
set(handles.ClearSettings,'Enable','On')
set(handles.OutputPrefixEdit,'Enable','Off');
% set(handles.OutputSubjectEdit,'Enable','On');
set(handles.OutputDateEdit,'Enable','Off');
set(handles.OutputSuffixEdit,'Enable','Off');
%********** even more turned off
set(handles.Parameters,'Enable','On');
set(handles.TrialMaxEdit,'Enable','On');
set(handles.JuiceVolumeEdit,'Enable','On');
set(handles.ChooseSettings,'Enable','Off');
set(handles.Initialize,'Enable','Off');
set(handles.ParameterEdit,'Enable','On');
%********* Optional Turn Offs *****************
%****** These might remain on for calib eye
if ~handles.S.DummyEye
  EnableEyeCalibration(handles,'On');
end
%********** leave the pause button functioning **
set(handles.PauseTrial,'Enable','Off');
%***********************************************
UpdateEyeText(handles);

% UPDATE GUI STATUS
set(handles.StatusText,'String','Protocol is ready to run trials.');
% SET TASK LIGHT TO RED
ChangeLight(handles.TaskLight,[1 0 0]);

% UPDATE HANDLES STRUCTURE
guidata(hObject,handles);


% STOP THE TRIAL LOOP ONCE THE CURRENT TRIAL HAS COMPLETED
function PauseTrial_Callback(hObject, eventdata, handles)
% Pause button can also act as an unpause button
  if ~handles.stopTask
         handles.stopTask = true;
         % SET TASK LIGHT TO ORANGE
         ChangeLight(handles.TaskLight,[.9 .7 .2]);
  end
% UPDATE HANDLES STRUCTURE
guidata(hObject,handles);


% GIVE A JUICE REWARD
function GiveJuice_Callback(hObject, eventdata, handles)
handles.reward.deliver();
handles.A.juiceCounter = handles.A.juiceCounter + 1;
guidata(hObject,handles);


% CHANGE THE SIZE OF THE JUICE REWARD TO BE DELIVERED
function JuiceVolumeEdit_CreateFcn(hObject, eventdata, handles) %#ok<*INUSD>
function JuiceVolumeEdit_Callback(hObject, eventdata, handles)
vol = get(hObject,'String'); % volume is entered in microliters!!

volUL = str2double(vol); % microliters

% fprintf(handles.A.pump,['0 VOL ' volML]);
handles.reward.volume = volUL; % milliliters
if handles.S.solenoid
  set(handles.JuiceVolumeText,'String',[vol ' ms']); % displayed in microliters!!
else
  set(handles.JuiceVolumeText,'String',[vol ' ul']);   
end
set(hObject,'String',''); % why?
handles.A.juiceVolume = volUL; % <-- A.juiceVolume should *always* be in milliliters!
guidata(hObject,handles);


% RESETS THE DISPLAY SCREEN IF IT WAS INTERUPTED (BY E.G. ALT-TAB)
function FlipFrame_Callback(hObject, eventdata, handles)
% If a bkgd parameter exists, flip frame with background color value
if isfield(handles.P,'bkgd')
    Screen('FillRect',handles.A.window,uint8(handles.P.bkgd));
end
Screen('Flip',handles.A.window);


%%%%% PARAMETER CONTROL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Parameters_CreateFcn(hObject, eventdata, handles)
function Parameters_Callback(hObject, eventdata, handles)
% Get the index of the selected field
i = get(hObject,'Value');
% Set the parameter text to a description of the parameter
set(handles.ParameterText,'String',handles.S.(handles.pNames{i}));
% Set the parameter edit to the current value of that parameter
set(handles.ParameterEdit,'String',num2str(handles.P.(handles.pNames{i})));
% Update handles structure
guidata(hObject,handles);

function ParameterEdit_CreateFcn(hObject, eventdata, handles)
function ParameterEdit_Callback(hObject, eventdata, handles)
% Get the new parameter value
pValue = str2double(get(hObject,'String'));
% Get the parameter name
pName = handles.pNames{get(handles.Parameters,'Value')};
% If the parameter value is a number
if ~isnan(pValue)
    % Change the parameter value
    handles.P.(pName) = pValue;
    % Update the parameter list immediately if not in the run loop
    if ~handles.runTask
        tName = sprintf('%s = %2g',pName,handles.P.(pName));
        handles.pList{get(handles.Parameters,'Value')} = tName;
        set(handles.Parameters,'String',handles.pList);
    end
    
    % handle treadmill parameters
    if any(strfind(pName, 'tread'))
        tName = pName(6:end);
        handles.treadmill.(tName) = handles.P.(pName);
    end
else
    % Revert the parameter text to the previous value
    set(hObject,'String',num2str(handles.P.(pName)));
end
% Update handles structure
guidata(hObject,handles);

function TrialMaxEdit_CreateFcn(hObject, eventdata, handles)
function TrialMaxEdit_Callback(hObject, eventdata, handles)
% Get the new count
newFinal = round(str2double(get(hObject,'String')));
% Make sure the new final trial is a positive integer
if newFinal > 0
    % Update the final trial
    handles.A.finish = newFinal;
    % Set the count
    set(handles.TrialMaxText,'String',get(hObject,'String'));
end
% Clear the edit string
set(hObject,'String','');

% Update handles structure
guidata(hObject,handles);

%%%%% SHIFT EYE POSITION CALLBACKS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function CenterEye_Callback(hObject, eventdata, handles)
[x,y] = handles.eyetrack.getgaze();
handles.A.c = [x,y];
guidata(hObject,handles);
UpdateEyeText(handles);
UpdateEyePlot(handles);

function GainSize_CreateFcn(hObject, eventdata, handles)
function GainSize_Callback(hObject, eventdata, handles)
gainSize = str2double(get(hObject,'String'));
if ~isnan(gainSize)
    handles.gainSize = gainSize;
    guidata(hObject,handles);
else
    set(handles.GainSize,'String',num2str(handles.gainSize));
end

function GainUpX_Callback(hObject, eventdata, handles)
% Note we divide by dx, so reducing dx increases gain
handles.A.dx = (1-handles.gainSize)*handles.A.dx;
guidata(hObject,handles);
UpdateEyeText(handles);
UpdateEyePlot(handles);

function GainDownX_Callback(hObject, eventdata, handles)
handles.A.dx = (1+handles.gainSize)*handles.A.dx;
guidata(hObject,handles);
UpdateEyeText(handles);
UpdateEyePlot(handles);

function GainUpY_Callback(hObject, eventdata, handles)
handles.A.dy = (1-handles.gainSize)*handles.A.dy;
guidata(hObject,handles);
UpdateEyeText(handles);
UpdateEyePlot(handles);

function GainDownY_Callback(hObject, eventdata, handles)
handles.A.dy = (1+handles.gainSize)*handles.A.dy;
guidata(hObject,handles);
UpdateEyeText(handles);
UpdateEyePlot(handles);


function ShiftSize_CreateFcn(hObject, eventdata, handles)
function ShiftSize_Callback(hObject, eventdata, handles)
shiftSize = str2double(get(hObject,'String'));
if ~isnan(shiftSize)
    handles.shiftSize = shiftSize;
    guidata(hObject,handles);
else
    set(handles.ShiftSize,'String',num2str(handles.shiftSize));
end

function ShiftLeft_Callback(hObject, eventdata, handles)
handles.A.c(1) = handles.A.c(1) + ...
    handles.shiftSize*handles.A.dx*handles.S.pixPerDeg;
guidata(hObject,handles);
UpdateEyeText(handles);
UpdateEyePlot(handles);

function ShiftRight_Callback(hObject, eventdata, handles)
handles.A.c(1) = handles.A.c(1) - ...
    handles.shiftSize*handles.A.dx*handles.S.pixPerDeg;
guidata(hObject,handles);
UpdateEyeText(handles);
UpdateEyePlot(handles);

function ShiftDown_Callback(hObject, eventdata, handles)
handles.A.c(2) = handles.A.c(2) + ...
    handles.shiftSize*handles.A.dy*handles.S.pixPerDeg;
guidata(hObject,handles);
UpdateEyeText(handles);
UpdateEyePlot(handles);

function ShiftUp_Callback(hObject, eventdata, handles)
handles.A.c(2) = handles.A.c(2) - ...
    handles.shiftSize*handles.A.dy*handles.S.pixPerDeg;
guidata(hObject,handles);
UpdateEyeText(handles);
UpdateEyePlot(handles);

function ResetCalibration_Callback(hObject, eventdata, handles)
handles.A.dx = handles.C.dx;
handles.A.dy = handles.C.dy;
handles.A.c = handles.C.c;
guidata(hObject,handles);
UpdateEyeText(handles);
UpdateEyePlot(handles);

%%%%% OUTPUT PANEL CALLBACKS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function OutputPrefixEdit_CreateFcn(hObject, eventdata, handles)
function OutputPrefixEdit_Callback(hObject, eventdata, handles)
handles.outputPrefix = get(hObject,'String');
handles = UpdateOutputFilename(handles);
guidata(hObject,handles);

function OutputSubjectEdit_CreateFcn(hObject, eventdata, handles)
function OutputSubjectEdit_Callback(hObject, eventdata, handles)
handles.outputSubject = get(hObject,'String');
handles.S.subject = handles.outputSubject;
handles = UpdateOutputFilename(handles);
guidata(hObject,handles);

function OutputDateEdit_CreateFcn(hObject, eventdata, handles)
function OutputDateEdit_Callback(hObject, eventdata, handles)
handles.outputDate = get(hObject,'String');
handles = UpdateOutputFilename(handles);
guidata(hObject,handles);

function OutputSuffixEdit_CreateFcn(hObject, eventdata, handles)
function OutputSuffixEdit_Callback(hObject, eventdata, handles)
handles.outputSuffix = get(hObject,'String');
handles = UpdateOutputFilename(handles);
guidata(hObject,handles);

%%%%% CLOSE THE GUI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function CloseGui_Callback(hObject, eventdata, handles)
% Close all screens from ptb
sca;
% If Data File Open, condense appended D's into one struct ****
CondenseAppendedData(hObject,handles);
% Close the pump
handles.reward.report()
delete(handles.reward); handles.reward = NaN;

% Save any changes to the calibration
c = handles.A.c; %#ok<NASGU>    Supressing editor errors because theses
dx = handles.A.dx; %#ok<NASGU>  variables are being saved
dy = handles.A.dy; %#ok<NASGU>
if ~handles.S.DummyEye
  save([handles.supportPath 'MarmoViewLastCalib.mat'],'c','dx','dy');
end
%********** if using the DataPixx, close it here
if (handles.S.DataPixx)
    datapixx.close();
end
IOPort('CloseAll')
if isa(handles.eyetrack, 'marmoview.eyetrack_ddpi')
    ddpiM('stop')
    ddpiM('shutdown')
end
% Close the gui window
close(handles.figure1);

%%%%% AUXILLIARY FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ChangeLight(h,col)
% THIS FUNCTION CHANGES THE TASK LIGHT
scatter(h,.5,.5,600,'o','MarkerEdgeColor','k','MarkerFaceColor',col);
axis(h,[0 1 0 1]); bkgd = [.931 .931 .931];
set(h,'XColor',bkgd,'YColor',bkgd,'Color',bkgd);

% THIS FUNCTION UPDATES THE RAW EYE CALIBRATION NUMBERS IN THE GUI
function UpdateEyeText(h)
set(h.CenterText,'String',sprintf('[%.3g %.3g]',h.A.c(1),h.A.c(2)));
dx = 100*h.A.dx; dy = 100*h.A.dy; % A LARGE MAGNIFICATION IS USED TO EFFICIENTLY DISPLAY 2 DIGITS
set(h.GainText,'String',sprintf('[%.3g %.3g]',dx,dy));

% THIS FUNCTION UPDATES PLOTS OF THE EYE TRACE
function UpdateEyePlot(handles)
if ~handles.runTask && handles.A.j > 1   % At least 1 trial must be complete in order to plot the trace
    subplot(handles.EyeTrace); hold off;  % clear old plot
    if ~handles.lastRunWasImage
       handles.PR.plot_trace(handles); hold on; % command to plot on eye traces
    else
       handles.PRI.plot_trace(handles); hold on; % command to plot on eye traces     
    end
    handles.FC.plot_eye_trace_and_flips(handles);  %plot the eye traces
end

function handles = UpdateOutputFilename(handles)
% Generate the file name
  if (~isempty(handles.outputPrefix) && ~isempty(handles.outputSubject) && ...
      ~isempty(handles.outputDate) && ~isempty(handles.outputSuffix) )
        handles.A.outputFile = strcat(handles.outputPrefix,'_',handles.outputSubject,...
               '_',handles.outputDate,'_',handles.outputSuffix,'.mat');
        set(handles.OutputFile,'String',handles.A.outputFile);
        % If the file name already exists, provide a warning that data will be
        % overwritten
        if exist([handles.outputPath handles.A.outputFile],'file')
          w=warndlg('Data file alread exists, running the trial loop will overwrite.');
          set(w,'Position',[441.75 -183 270.75 75.75]);
        end
        % Note that a new output file is being used. For example, someone might
        % want to be sure the trials list is started over if the output file name
        % changes. Currently I don't have any protocols implementing this.
        handles.A.newOutput = 1;
  else
     if ( ~isempty(handles.outputSubject) && ~strcmp(handles.outputSubject,'none') )
         %****** then it should be possible to initialize a protocol with name
         set(handles.SettingsPanel,'Visible','on');
         if ~exist([handles.settingsPath handles.settingsFile],'file')
             set(handles.Initialize,'Enable','off');
             tstring = 'Please select a settings file...';
         else
             set(handles.Initialize,'Enable','on');
             tstring = 'Ready to initialize protocol...';
         end
         % Update GUI status
         set(handles.StatusText,'String',tstring);
         %*******************************************
     end 
  end

%********* Turn on or off all controls related to eye calibration
%        state should be a string, 'On' or 'Off'
function EnableEyeCalibration(handles,state)
  set(handles.CenterEye,'Enable',state);
  set(handles.ShiftUp,'Enable',state);
  set(handles.ShiftDown,'Enable',state);
  set(handles.ShiftLeft,'Enable',state);
  set(handles.ShiftRight,'Enable',state);
  set(handles.GainUpY,'Enable',state);
  set(handles.GainDownY,'Enable',state);
  set(handles.GainUpX,'Enable',state);
  set(handles.GainDownX,'Enable',state);
  set(handles.ShiftSize,'Enable',state);
  set(handles.GainSize,'Enable',state);
  set(handles.ResetCalibration,'Enable',state);
  set(handles.GraphZoomIn,'Enable',state);
  set(handles.GraphZoomOut,'Enable',state);
  
% --- Executes on button press in Calib_Screen.
function Calib_Screen_Callback(hObject, eventdata, handles)
% hObject    handle to Calib_Screen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  
 % If a bkgd parameter exists, flip frame with background color value
  % Screen('FillRect',handles.A.window,uint8(0));
  % Screen('Flip',handles.A.window);
  handles.runImage = true;
  handles.runOneTrial = true; % keep running till paused, or true stop at one
  hold_dir = handles.SI.ImageDirectory;
  handles.PRI.load_image_dir(['SupportData',filesep,'ForagePoint']);
  guidata(hObject,handles);
  RunTrial_Callback(hObject, eventdata, handles)
  % it appears if handles changed, you need to regrab it
  % what lives in this function is the old copy of it
  handles = guidata(hObject);
  %**********
  handles.runImage = false;
  handles.runOneTrial = false;
  handles.PRI.load_image_dir(hold_dir);
  guidata(hObject,handles);


% --- Executes on button press in Background_Image.
function Background_Image_Callback(hObject, eventdata, handles)
% hObject    handle to Background_Image (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  % Idea is the following, turn on flag and run PRI object instead
  % of the PR object, otherwise data logging and other tracking identical
  handles.runImage = true;
  handles.runOneTrial = true; % keep running till paused, or true stop at one
  guidata(hObject,handles);
  RunTrial_Callback(hObject, eventdata, handles)
  % it appears if handles changed, you need to regrab it
  % what lives in this function is the old copy of it
  handles = guidata(hObject);
  %**********
  handles.runImage = false;
  handles.runOneTrial = false;
  guidata(hObject,handles);


% --- Executes on button press in GraphZoomIn.
function GraphZoomIn_Callback(hObject, eventdata, handles)
% hObject    handle to GraphZoomIn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.eyeTraceRadius > 2.5
    handles.eyeTraceRadius = handles.eyeTraceRadius-2.5; 
end
guidata(hObject,handles);
UpdateEyePlot(handles);


% --- Executes on button press in GraphZoomOut.
function GraphZoomOut_Callback(hObject, eventdata, handles)
% hObject    handle to GraphZoomOut (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.eyeTraceRadius < 30
     handles.eyeTraceRadius = handles.eyeTraceRadius+2.5;
end
guidata(hObject,handles);
UpdateEyePlot(handles);


% --- Executes on button press in Refresh_Trials.
function Refresh_Trials_Callback(hObject, eventdata, handles)
% hObject    handle to Refresh_Trials (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%REBUILD A NEW TRIALS LIST FROM CURRENT PARAMS
handles.PR.generate_trialsList(handles.S,handles.P);
% DE-INITIALIZE OBJECTS (may need to make new if Param changed)
handles.PR.closeFunc();
% RE-INITIALIZE OBJECTS (may need to make new if Param changed)
handles.PR.initFunc(handles.S,handles.P);
%******* load changes in handles back to the GUI
guidata(hObject,handles);
  

%******** We store trial by trial data while running
%******** but before closing, we condense it back to
%******** a single D struct.
%******** NOTE: if MarmoView hangs or crashes, you would
%******** still be able to call this routine on what is saved
function CondenseAppendedData(hObject, handles)

    guidata(hObject,handles); drawnow;
    A = handles.A;   % get the A struct (carries output file names)
    %******* go to outputPath and load current data
    if ~strcmp(A.outputFile,'none')  % could be in state with no open file
      cd(handles.outputPath);             % goto output directory
      if exist(A.outputFile,'file')
        NewOutput = [A.outputFile(1:(end-4)),'z.mat'];  
        fprintf('Condensing data for file %s to %s\n',A.outputFile,NewOutput);  
        zdata = load(A.outputFile);    % load in all data
        S = zdata.S;                   % get settings struct
        D = cell(1,1);
        ND = length(fields(zdata));      % includes all trials, minus one for S
        for k = 1:(ND-1)
          Dstring = sprintf('D%d',k);
          D{k,1} = zdata.(Dstring);
        end
        clear zdata;
        %********
        save(NewOutput,'S','D');   % append file
        clear D;
        fprintf('Data file %s reformatted.\n',NewOutput);
      end
      cd(handles.taskPath);            % return to task directory
    end
    


% --- Executes on slider movement.
function slider_P4intensity_Callback(hObject, eventdata, handles)
% hObject    handle to slider_P4intensity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isa(handles.eyetrack, 'marmoview.eyetrack_ddpi')
    handles.eyetrack.p4intensity = hObject.Value;
	ddpiM('setP4Template', [handles.eyetrack.p4intensity, handles.eyetrack.p4radius]);
    fprintf('Setting P4 intensity to: %f\n',  handles.eyetrack.p4intensity)
end
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function slider_P4intensity_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_P4intensity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes on slider movement.
function slider_P4radius_Callback(hObject, eventdata, handles)
% hObject    handle to slider_P4radius (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isa(handles.eyetrack, 'marmoview.eyetrack_ddpi')
    handles.eyetrack.p4radius = hObject.Value;
	ddpiM('setP4Template', [handles.eyetrack.p4intensity, handles.eyetrack.p4radius]);
    fprintf('Setting P4 radius to: %f\n',  handles.eyetrack.p4radius)
end
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function slider_P4radius_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_P4radius (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
