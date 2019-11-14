function handles = runTrial(handles, hObject, PR)
% This function replaces frame control to remove some overhead

% --- Initialize variables
% eyeColor = uint8(repmat(o.Bkgd,[1 3])) + ...
%                      uint8(o.eyeIntensity * [1,-1,1]);
P = handles.P;
S = handles.S;
A = handles.A;

winPtr = handles.A.window;                
rewardtimes = [];
runloop = 1;

% variables we need
pixPerDeg = handles.S.pixPerDeg;
dx = handles.C.dx;
dy = handles.C.dy;
c = handles.C.c;

%****** added to control when juice drop is delivered based on graphics
%****** demands, drop juice on frames with low demands basically

frameTime = (0.5/handles.S.frameRate);
drop = 0; % initialize reward state
holdrop = 0;
dropreject = 0;

% track eye data and frame
EyeData = nan(25e3,9);
EyeDataNames = {'LoopCounter', 'EyeX', 'EyeY', 'Pupil', 'State', 'ScreenTime', 'StimOnset', 'Missed'};

% track each loop iteration
FrameStates = nan(25e3, 8);
LoopCounter = 1;
StateNames = {'Start', 'State', 'GetEye', 'UpdateProtocol', 'Reward', 'Screen', 'GUI', 'continue'};
updateGUI = false;

%******* This is where to perform TimeStamp Syncing (start of trial)
STARTCLOCK = handles.FC.prep_run_trial([nan nan],nan);
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

% --- start trial time
screenTime = Screen('Flip', winPtr, 0); % get us started at the right time

%**************
while runloop
    
    % ---------------------------------------------------------------------
    % --- FrameState 1: Get Protocol State and Eye position
    FrameStates(LoopCounter, 1) = GetSecs;
    EyeData(LoopCounter, 1) = LoopCounter;
    
    state = PR.get_state();
    
    FrameStates(LoopCounter, 2) = state;
    
    [ex,ey] = handles.eyetrack.getgaze();
    pupil = handles.eyetrack.getpupil();    
    
    x = (ex-c(1)) / (dx*pixPerDeg);
    y = (ey-c(2)) / (dy*pixPerDeg);
    
    currentTime = GetSecs;
    FrameStates(LoopCounter, 3) = currentTime;
    
    EyeData(LoopCounter, 2) = ex;
    EyeData(LoopCounter, 3) = ey;
    EyeData(LoopCounter, 4) = pupil;
    EyeData(LoopCounter, 5) = state;
    % ---------------------------------------------------------------------
    
    
    
    
    
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
    FrameStates(LoopCounter, 4) = GetSecs;
    
    %**********************************
    %        if  (drop > 0)
    %            rewardtimes = [rewardtimes GetSecs];
    %            handles.reward.deliver();
    %        end
    %**********************************
    % EYE DISPLAY (SHOWEYE), SCREEN FLIP, and
    % ANY GUI UPDATING (if not time sensitive states)
    currentTime = GetSecs;
    if (currentTime - screenTime) > frameTime
        
        % drawing
        drop = PR.state_and_screen_update(currentTime,x,y);
        
        FrameStates(LoopCounter, 5) = GetSecs;
        
        [screenTime, stimOnset, ~, Missed] = Screen('Flip',winPtr,0);
        runloop = PR.continue_run_trial(LoopCounter);
        
        EyeData(LoopCounter,6) = screenTime;
        EyeData(LoopCounter,7) = stimOnset;
        EyeData(LoopCounter,8) = Missed;
        
        if (~ismember(state,handles.S.TimeSensitive))
            updateGUI = true;
        else
            updateGUI = false;
        end
       
    end
    
    FrameStates(LoopCounter, 6) = GetSecs;
    
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
    
    FrameStates(LoopCounter, 7) = GetSecs;
        
    
    if (screenTime - STARTCLOCKTIME) > 20
        runloop = false;
    end
    FrameStates(LoopCounter, 8) = GetSecs;
    
    LoopCounter = LoopCounter + 1;
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

% handles.FC.plot_eye_trace_and_flips(handles);  %plot the eye traces
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

D.FrameStates = FrameStates(1:LoopCounter-1,:);
D.FrameStateNames = StateNames;

D.PR = PR.end_plots(P,A);   %if critical trial info save as D.PR

if ~handles.runImage
    D.PR.name = handles.S.protocol;
%     if (D.PR.error == 0)
%         CorCount = CorCount + 1;
%     end
else
    D.PR.name = 'BackImage';
end
D.eyeData = EyeData;% handles.FC.upload_eyeData();
D.eyeDataNames = EyeDataNames;
% [c,dx,dy] = handles.FC.upload_C();
D.c = c;
D.dx = dx;
D.dy = dy;
D.rewardtimes = rewardtimes;    % log the time of juice pulses
D.juiceButtonCount = handles.A.juiceCounter; % SUPPLEMENTARY JUICE DURING THE TRIAL
D.juiceVolume = A.juiceVolume; % THE VOLUME OF JUICE PULSES DURING THE TRIAL
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