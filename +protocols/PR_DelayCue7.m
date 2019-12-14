classdef PR_DelayCue7 < handle
    % Matlab class for running an experimental protocl
    %
    % The class constructor can be called with a range of arguments:
    %
    
    properties (Access = public)
        Iti double = 1;            % default Iti duration
        startTime double = 0;      % trial start time
        fixStart double = 0;       % fix acquired time
        itiStart double = 0;       % start of ITI interval
        fixDur double = 0;         % fixation duration
        stimStart double = 0;      % stimulus onset
        responseStart double = 0;  % response period start time
        responseEnd double = 0;    % time entering response period
        dotflip double = 0;        % integer to know dots turn off
        DropStim double = 0;       % if 1, trial where dots disappear on saccade
        rewardCount double = 0;    % counter for reward drops
        RunFixBreakSound double = 0;       % variable to initiate fix break sound (only once)
        NeverBreakSoundTwice double = 0;   % other variable for fix break sound
        BlackFixation double = 6;          % frame to see black fixation, before reward
        colorstep double = 2.0;            % per frame, gray value fade in dots
        DelayPeriod double = 0;            % detect entry into delay period
        targonly double = 0;               % set if singleton trial
        cued double = 0;           % if point-cue has happened in trial yet
        showFace logical = false;       % showFace to start trial, or fix
        showFix logical = false;        % to show fixation point
        flashCounter double = 0;   % counts frames, used for fade in point cue?
    end
    
    properties (Access = private)
        winPtr; % ptb window
        state double = 0;      % state counter
        error double = 0;      % error state in trial
        %*********
        S;              % copy of Settings struct (loaded per trial start)
        P;              % copy of Params struct (loaded per trial)
        trialIndexer;      % will call TrialIndexer object to choose trial numbers
        trialsList;        % store copy of trial list (not good to keep in S struct)
        %********* stimulus structs for use
        Faces;             % object that stores face images for use
        hFix;              % object for a fixation point
        hPoint;            % line cue object for cueing
        nDots;             % number of dot stimuli objects (4 or 8)
        hDots = [];        % object for Dot Motion stimuli
        fixbreak_sound;    % audio of fix break sound
        fixbreak_sound_fs; % sampling rate of sound
        %******* trial parameters and stored information
        stimTheta;         % direction of target per trial
        target_item;       % integer for target location, 0 -> 0 degs, counter-clock 8 locs
        dotmotion;         % double array (4,8) ... motion infor for each of 8 locations
        % field 1 - clockwise or counter-clock motion
        % field 2 - angle to describe motion direction
        % field 3,4 - aperture x,y location
        DotLoc;            % integer rep for stimulus location 1-8
        %****************
        D = struct;        % store PR data for end plot stats, will store dotmotion array
    end
    
    methods (Access = public)
        function o = PR_DelayCue7(winPtr)
            o.winPtr = winPtr;
            o.trialsList = [];  % should be set by generate call
        end
        
        function state = get_state(o)
            state = o.state;
        end
        
        function initFunc(o,S,P)
            
            %********** Set-up for trial indexing (required)
            cors = [0,4];  % count these errors as correct trials
            reps = [1,2];  % count these errors like aborts, repeat
            if (~isempty(o.trialsList))
                o.trialIndexer = marmoview.TrialIndexer(o.trialsList,P,cors,reps);
            else
                disp('Error generating proper trialsList .... check function');
            end
            o.error = 0;
            
            %******* init reward face for correct trials
            o.Faces = stimuli.gaussimages(o.winPtr,'bkgd',S.bgColour,'gray',false);   % color images
            o.Faces.loadimages('./SupportData/ellie_face.mat');
            o.Faces.position = [0,0]*S.pixPerDeg + S.centerPix;
            o.Faces.radius = round(P.faceRadius*S.pixPerDeg);
            o.Faces.imagenum = 1;  % show single Ellie face
            
            %******* create fixation point ****************
            o.hFix = stimuli.fixation(o.winPtr);   % fixation stimulus
            % set fixation point properties
            sz = P.fixPointRadius*S.pixPerDeg;
            o.hFix.cSize = sz;
            o.hFix.sSize = 2*sz;
            o.hFix.cColour = ones(1,3); % black
            o.hFix.sColour = repmat(255,1,3); % white
            o.hFix.position = [0,0]*S.pixPerDeg + S.centerPix;
            o.hFix.updateTextures();
            
            %******* create object for point-cue stim near fixation
            o.hPoint = stimuli.pointcue(o.winPtr);  % pointcue stimulus
            o.hPoint.FixN = P.FixN;
            o.hPoint.pixPerDeg = S.pixPerDeg;
            o.hPoint.bkgd = P.bkgd;
            o.hPoint.sigma1 = P.sigma1;
            o.hPoint.width1 = P.width1;
            o.hPoint.cue_contrast = P.cue_contrast;
            o.hPoint.centerPix = S.centerPix;
            
            %*** Build a set of 4 dot motion stimuli
            % %*************** setup motion stimuli here at init .... then only change
            %************ their positions and directions of motions in the task
            if (P.SamplingDirections == 4)
                o.nDots = 8;
            else
                o.nDots=4;
            end
            %****
            for k=1:o.nDots
                o.hDots{k}=stimuli.dots(o.winPtr);
            end
            %*******************************************************************
            
            %********** load in a fixation error sound ************
            [y,fs] = audioread(['SupportData',filesep,'gunshot_sound.wav']);
            y = y(1:floor(size(y,1)/3),:);  % shorten it, very long sound
            o.fixbreak_sound = y;
            o.fixbreak_sound_fs = fs;
            %*********************
            
        end
        
        function closeFunc(o)
            o.Faces.CloseUp();
            o.hFix.CloseUp();
            o.hPoint.CloseUp();
            for k = 1:o.nDots
                o.hDots{k}.CloseUp();
            end
        end
        
        function generate_trialsList(o,S,P)
            % Call a function outside class (easier for us to edit)
            o.trialsList = DelayCue7_TrialsList(S,P);
            %******** HERE FOR REFERENCE, JUST LIST THE FIELDS OF LIST
            %   Field 1, 2:   xpos and ypos of target
            %   Field 3:      length of central line cue
            %   Field 4:      size of juice reward (based on condition)
            %   Field 5:      delay from cue onset before saccade allowed
            %   Field 6:      delay number (integer of condition)
            %   Field 7:      cueColor - brightness (or darkness) of cue
            %   Field 8:      cued peak time (cue fades in and out)
            %   Field 9:      cued width (duration of fade in and out)
            %   Field 10:     singleton (on some trials run single stim, no
            %                            distractors ... sample a location)
        end
        
        function P = next_trial(o,S,P)
            %********************
            o.S = S;
            o.P = P;
            %*******************
            
            % Trials list control
            if P.runType == 1
                %******** Trial indexer handles trials list indexing intelligently
                i = o.trialIndexer.getNextTrial(o.error);
                %***************
                P.xDeg = o.trialsList(i,1);
                P.yDeg = o.trialsList(i,2);
                P.sigma1 = o.trialsList(i,3);  % keep fixed
                P.rewardNumber = o.trialsList(i,4);
                P.delay = o.trialsList(i,5);
                P.delayNumber = o.trialsList(i,6);
                P.cueColor = o.trialsList(i,7);
                P.cue_peak = o.trialsList(i,8);
                P.cue_width = o.trialsList(i,9);
                P.SingletonTrial = o.trialsList(i,10);
                %*******************
                if P.SingletonTrial
                    rd = randi(size(S.SingletonDirs,2));
                    ango = ( (2*pi) * S.SingletonDirs(rd) / 360);
                    P.xDeg = P.stimEcc * cos(ango);
                    P.yDeg = P.stimEcc * sin(ango);
                end
                %******************
                o.P = P;  % set to most current
            end
            
            % Calculate this for pie slice windowing and contast cues
            o.stimTheta = atan2(P.yDeg,P.xDeg);
            % Set location of face reward
            if P.sigma1 >= 1.0
                o.Faces.position = [P.xDeg,-P.yDeg]*S.pixPerDeg + S.centerPix;
            else
                o.Faces.position = S.centerPix;  % fixation trial, reward at center
            end
            
            %********* Make a third fix point, with the symbolic cue included
            o.hPoint.sigma1 = P.sigma1;
            o.hPoint.UpdateTextures(P.xDeg,P.yDeg);
            
            %******** Probably more complicated than necessary, but it works
            %*********** setup aperture position and direction of motion
            aR = round(P.apertureRadius*S.pixPerDeg);
            aC = S.pixPerDeg*norm([P.xDeg P.yDeg]);
            my_radius = norm([P.xDeg P.yDeg]);
            
            if (P.SamplingDirections == 4)
                o.dotmotion = zeros(4,8);
                o.DotLoc = ones(1,8);
            else
                o.dotmotion = zeros(4,4);
                o.DotLoc = ones(1,4);
            end
            o.target_item = -1;
            
            %*********
            if (P.SamplingDirections == 1) || (P.SamplingDirections == 4)
                if (P.SamplingDirections == 4)
                    klist = 1:P.apertures;
                else
                    % must determine by P.xDeg and P.yDeg if cardinal or not
                    if ( abs(P.xDeg * P.yDeg) < 1)  % cardinal
                        klist = 1:2:P.apertures;
                    else
                        klist = 2:2:P.apertures;
                    end
                end
            else
                if (P.SamplingDirections == 2)  % cardinal
                    klist = 1:2:P.apertures;
                else
                    klist = 2:2:P.apertures;  % diagonals
                end
            end
            %***********
            
            z = 1;
            for i = klist    % draw every other
                ango =  2*pi*(i-1)/P.apertures;
                x = aC*cos(ango);
                y = aC*sin(ango);
                my_x = my_radius * cos(ango);  % in visual degs
                my_y = my_radius * sin(ango);  % in vis degs
                cX = S.centerPix(1)+round(x);
                cY = S.centerPix(2)-round(y);   % FOR SCREEN DRAWS, VERTICAL IS INVERTED
                dotposition(z,1) = cX; %#ok<*AGROW>
                dotposition(z,2) = cY;
                %*****************
                o.DotLoc(1,z) = i;  % dot field location in aperture coordinates
                %*********************** inverse tangent computation
                ango = InverTan(x,y);
                %***********
                if (rand < 0.5)  % pick tangental direction, equal prob & save direction
                    dotdirection_ang(z) = ango + (pi/2);
                    dotdirection = 1;
                else
                    dotdirection_ang(z) = ango - (pi/2);
                    dotdirection = 2;
                end
                %********** everything we need is in the A vector
                o.dotmotion(1,z) = dotdirection;
                o.dotmotion(2,z) = dotdirection_ang(z);
                o.dotmotion(3,z) = x;   %aperture location
                o.dotmotion(4,z) = y;   %
                %**************************
                dist = sqrt( (P.xDeg - my_x)^2 + (P.yDeg - my_y)^2 );
                if (dist < 0.5)
                    o.target_item = z;
                end
                z = z + 1;
                %**********************************************
            end
            %**********
            for k=1:o.nDots
                o.hDots{k}.mode=1; % gaussian
                o.hDots{k}.dist=0; % gaussian
                o.hDots{k}.numDots=P.dotNum; % number of dots in dot field
                o.hDots{k}.position=[dotposition(k,1) dotposition(k,2)]; % where to plot dot field
                o.hDots{k}.direction=dotdirection_ang(k) * (360/(2*pi));  % into degrees/ direction of motion
                o.hDots{k}.bandwdth=1;
                o.hDots{k}.lifetime=inf; %how long the dots last
                o.hDots{k}.maxRadius=aR;   % same pixel size as aperture (radius of the dot field)
                o.hDots{k}.speed= (P.dotSpeed*S.pixPerDeg)/S.frameRate;   %(speed of dots)
                o.hDots{k}.beforeTrial;
                o.hDots{k}.colour=[0 0 0];%(rand(1,3)<.1)*255; (coded in the colorstep)
                o.hDots{k}.size= round(P.dotSize*S.pixPerDeg);   % size of the dots
                o.hDots{k}.theta=0;
                o.hDots{k}.gaussian = true;
            end
        end
        
        function draw_apertures(o)
            %******** update motion stimuli to graphics buffer
            for k = 1:o.nDots
%                 zk = o.DotLoc(k);  % value from 1 to 8
                o.hDots{k}.colour = o.colorstep * [1 1 1];
                if (o.dotflip == 1)   % if correct saccade, hold target on dotdelay
                    % otherwise leave all targets if fixation
                    if (k ~= o.target_item)
                        o.hDots{k}.colour = [o.P.bkgd o.P.bkgd o.P.bkgd];
                    end
                end
                if (o.targonly == 1)
                    if (k == o.target_item)
                        o.hDots{k}.beforeFrame;
                    end
                else
                    o.hDots{k}.beforeFrame;
                end
            end
        end
        
        function CT = compute_CT(o,ctime,stimStart)
            start_cue = stimStart + o.P.stimForwardDur + o.P.cue_peak - (0.5 * o.P.cue_width);
            tval = (ctime - start_cue)/(0.5 * o.P.cue_width);
            if (tval < 0) || (tval > 2)
                tval = 0;
            else
                if (tval > 1)
                    tval = (2-tval);
                end
            end
            CT = 1 + floor( o.P.FixN * tval * 0.99999);
        end
        
        function [FP,TS] = prep_run_trial(o)
            %********** Trial delay times *******************
            o.fixDur = o.P.fixMin + ceil(1000*o.P.fixRan*rand)/1000;
            %*********************
            o.dotflip = 0;  % default
            o.DropStim = 0;
            if (isfield(o.P,'dropStimulus'))
                if (rand < o.P.dropStimulus )
                    o.DropStim = 1;
                end
            end
            
            % WHAT TO DO HERE ... direct communication out to the eyetrack
            % for sending out commands .... need a way to do this ...   THIS SHOULD NOT BE NECESSARY, REBUILD ANALYSIS!
            % THOSE THINGS BEING CODED HERE ARE STORED IN THE PR STRUCT
            %****** Send TTL to eyefile
            %handles.eyetrack.sendcommand(sprintf('dataFile_InsertString "%i -3 %8.5f %8.5f %8.5f %8.5f %2d"',handles.A.j,...
            %                   handles.A.c(1),handles.A.c(2),handles.A.dx,handles.A.dy,DropStim));
            
            
            % Flags that control transitions
            % State is the main variable to control transitions. A protocol can be
            % described by shifting through states. For this protocol:
            % State 0 -- Fixation not yet initiated, flash the fixation spot
            % State 1 -- Fixation entered, grace period
            % State 2 -- Hold fixation before stimulus onset
            % State 3 -- Stimulus is present, wait for saccade
            % State 4 -- Stimulus off, dim fix to cue saccade
            % State 5 -- Saccade initiated, flight time grace, fixation spot off
            % State 6 -- Hold stimulus until reward
            % State 7 -- Inter-trial Interval, just waiting, eye collection off
            % State 8 -- end of the trial, blank frame ITI period
            % State 9 -- end of trial
            o.state = 0;
            % Errors describe why a trial was not completed
            % Error 1 -- Failure to enter fixation window
            % Error 2 -- Failure to hold fixation until stimulus onset
            % Error 3 -- Failure to initiate a saccade to leave fixation window
            % Error 4 -- Failure to saccade to the stimulus
            % Error 5 -- Failure to hold the stimulus once selected
            o.error = 0;
            %********* Cued says if the spatial cue occured or he went early
            % Cued = 0  .... he went early
            % Cued = 1  ... he waited and saw the cue
            o.cued = 0;
            o.showFace = false;  % prob to show face at start
            % showFix is a flag to check whether to show the fixation spot or not while
            % it is flashing in state 0
            o.showFix = true;
            % flashCounter counts the frames to switch ShowFix off and on
            o.flashCounter = 0;
            % rewardCount counts the number of juice pulses, 1 delivered per frame
            % refresh
            o.rewardCount = 0;
            %****** deliver sound on fix breaks
            o.RunFixBreakSound =0;
            o.NeverBreakSoundTwice = 0;
            o.BlackFixation = 0;  % frame to see black fixation, before reward
            %************
            o.colorstep = o.P.bkgd;  % starts as background, fade in dots
            % Grab start time and initial eye data
            % The reason 5 repeats are collected is for eye point smoothing
            o.startTime = GetSecs;
            %********
            o.DelayPeriod = 0;   % one if the delay period is entered
            if (o.P.SingletonTrial)
                o.targonly = 1;   % to flag singleton trials
            else
                o.targonly = 0;
            end
            %**************
            
            %******* Plot States Struct (show fix in blue for eye trace)
            % any special plotting of states,
            % FP(1).states = 1:2; FP(1).col = 'b';
            % would show states 1,2 in blue for eye trace
            FP(1).states = 1:3;  %before fixation
            FP(1).col = 'b';
            FP(2).states = 4;  % fixation held
            FP(2).col = 'g';
            FP(3).states = 5;  % fixation held
            FP(3).col = 'r';
            TS = 1:7;  % most states are time sensitive due to dot motion
            %****************
            o.startTime = GetSecs;
            o.responseEnd = o.startTime;   %over-written later, but crashes first trial if not
            o.Iti = o.P.iti;  % default ITI, could be longer if error
        end
        
        function keepgoing = continue_run_trial(o,~)
            keepgoing = 0;
            if (o.state < 9)
                keepgoing = 1;
            end
        end
        
        %******************** THIS IS THE BIG FUNCTION *************
        function drop = state_and_screen_update(o,currentTime,x,y)
            drop = 0;
            %******* THIS PART CHANGES WITH EACH PROTOCOL ****************
            
            % POLAR COORDINATES FOR PIE SLICE METHOD, note three values of polT to
            % ensure atan2 discontinuity does not wreck shit
            polT = atan2(y,x)+[-2*pi 0 2*pi];
            polR = norm([x y]);
            
            %%%%% STATE 0 -- GET INTO FIXATION WINDOW %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % If eye travels within the fixation window, move to state 1
            if o.state == 0 && norm([x y]) < o.P.initWinRadius
                o.state = 1; % Move to fixation grace
                o.fixStart = GetSecs;
            end
            
            % Trial expires if not started within the start duration
            if o.state == 0 && currentTime > o.startTime + o.P.startDur
                o.state = 8; % Move to iti -- inter-trial interval
                o.error = 1; % Error 1 is failure to initiate
                o.itiStart = GetSecs;
            end
            
            %%%%% STATE 1 -- GRACE PERIOD TO BE IN FIXATION WINDOW %%%%%%%%%%%%%%%%
            % A grace period is given before the eye must remain in fixation
            if o.state == 1 && currentTime > o.fixStart + o.P.fixGrace
                if norm([x y]) < o.P.initWinRadius
                    o.state = 2; % Move to hold fixation
                else
                    o.state = 8;
                    o.error = 1; % Error 1 is failure to initiate
                    o.itiStart = GetSecs;
                end
            end
            
            %%%%% STATE 2 -- HOLD FIXATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % If fixation is held for the fixation duration, move to state 3
            if o.state == 2 && currentTime > o.fixStart + o.fixDur
                o.state = 3; % Move to show stimulus
                o.stimStart = GetSecs;
            end
            % Eye must remain in the fixation window for state 2 and 3
            if ( (o.state == 2) || (o.state ==3) ) && norm([x y]) > o.P.fixWinRadius
                o.state = 8; % Move to iti -- inter-trial interval
                if (o.DelayPeriod == 0)
                    o.error = 2; % Error 2 is failure to hold fixation
                else
                    o.error = 6; % Failure to hold in delay
                end
                o.itiStart = GetSecs;
            end
            
            %%%%% STATE 4 -- SHOW STIMULUS, free to saccade %%%%%%%%%%%%%%%%%%%%
            % Eye leaving fixation indicates a saccade, move to state 4
            if ((o.state == 4)) && norm([x y]) > o.P.fixWinRadius
                o.state = 5; % dim fixation if so, then move to saccade in flight
                o.responseStart = GetSecs;
            end
            
            %**** in this scenario, eye always leaves, only question if
            %**** it goes to the right location
            % Eye must leave fixation within stimulus duration or counted as no
            % response
            
            if o.state == 3 && currentTime > o.stimStart + (o.P.stimForwardDur + o.P.delay)
                o.state = 4; % remove stim and dim fixation to cue "Go"
                if (o.P.sigma1 < 1.0)
                    o.state = 7;
                    o.itiStart = GetSecs;
                else
                    if (isfield(o.P,'rewardFix'))
                        if (o.P.rewardFix)
                            drop = 1; % DELIVER REWARD
                        end
                    else
                        drop = 1;  % DELIVER REWARD
                    end
                end
                % for staying center
            end
            
            
            % Eye must leave fixation within stimulus duration or counted as no
            % response after some much longer interval
            if o.state == 4 && currentTime > o.stimStart + o.P.noresponseDur + o.P.delay
                o.state = 7; % Move to iti -- inter-trial interval
                o.error = 3; % Error 3 is failure to make a saccade
                o.itiStart = GetSecs;
            end
            
            %%%%% STATE 5 -- IN FLIGHT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Give the saccade time to finish flight
            if o.state == 5 && currentTime > o.responseStart + o.P.flightDur
                % If the saccade shifted gaze to the stimulus, proceed to state 5
                if polR > o.P.stimWinMinRad && polR < o.P.stimWinMaxRad && min(abs(o.stimTheta-polT)) < o.P.stimWinTheta
                    o.state = 6; % Move to hold stimulus
                    o.responseEnd = GetSecs;
                    % Otherwise the response failed to select the stimulus
                else
                    o.state = 7; % Move to iti -- inter-trial interval
                    o.error = 4; % Error 4 is failure to select the stimulus.
                    o.itiStart = GetSecs;
                end
            end
            
            %%%%% STATE 6 -- HOLD STIMULUS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % If the eye does not leave the stimulus, then reward
            if o.state == 6 && currentTime > o.responseEnd + o.P.holdDur
                o.state = 7; % Move to iti -- trial is over
                o.itiStart = GetSecs;
            end
            % If the eye leaves before hold duration, no reward
            if o.state == 6 && ~(polR > o.P.stimWinMinRad && polR < o.P.stimWinMaxRad && min(abs(o.stimTheta-polT)) < o.P.stimWinTheta)
                o.state = 7; % Move to iti -- inter-trial interval
                o.error = 5; % Error 5 is failure to hold the stimulus
                o.itiStart = GetSecs;
            end
            
            if o.state == 7
                if ~o.error && o.rewardCount < o.P.rewardNumber
                    if currentTime > o.itiStart + 0.2 * o.rewardCount % deliver in 200 ms increments before face reward
                        o.rewardCount = o.rewardCount + 1;
                        drop = 1;
                        if (o.P.sigma1 >= 1)
                            o.dotflip = 1;
                        end
                    end
                else
                    o.state = 8;
                end
            end
            if o.state == 8
                if currentTime > o.itiStart + 0.2   % enough time to flash fix break
                    o.state = 9;
                    if o.error
                        if (o.error == 1)
%                             Iti = o.P.iti + o.P.abort_iti;
                        else
%                             Iti = o.P.iti + o.P.blank_iti;
                        end
                    end
                end
            end
            
            % STATE SPECIFIC DRAWS
            switch o.state
                case 0
                    
                    if o.showFix
                        o.hFix.beforeFrame(1);
                    end
                    o.flashCounter = mod(o.flashCounter+1,o.P.flashFrameLength);
                    if o.flashCounter == 0
                        o.showFix = ~o.showFix;
                        if (~o.showFace)
                            if (rand < o.P.probShowFace)  %
                                o.showFace = true;
                            end
                        else
                            o.showFace = false;
                        end
                    end
                    % Aperture outlines
                    
                case 1
                    % Hold fixation some period
                    
                    % Aperture outlines
                    o.hFix.beforeFrame(1);
                    
                case 2
                    
                    % continue to hold fixation
                    o.hFix.beforeFrame(1);
                    % Aperture outlines
                    o.draw_apertures();
                    
                case 3    % show gaze cue
                    
                    if o.P.sigma1 < 1.0
                        o.hFix.beforeFrame(1);
                    else
                        if (currentTime > o.stimStart + o.P.stimForwardDur)
                            o.DelayPeriod = 1;
                        end
                        %****** fade in pointing cue over time ... slow him down?
                        CT = o.compute_CT(currentTime,o.stimStart); %,o.P.stimForwardDur,o.P.cue_peak,o.P.cue_width,o.P.FixN);
                        o.hPoint.beforeFrame(CT);
                        %*******************
                        o.hFix.beforeFrame(1);
                    end
                    % Aperture outlines
                    o.draw_apertures();
                    
                case 4    % waiting for him to leave fixation
                    % Disappear the fixation spot
                    
                    %****** fade in pointing cue over time ... slow him down?
                    CT = o.compute_CT(currentTime,o.stimStart); %,P.stimForwardDur,P.cue_peak,P.cue_width,P.FixN);
                    o.hPoint.beforeFrame(CT);
                    
                    % Aperture outlines
                    o.draw_apertures(); %A,P.bkgd,colorstep,dotcolorsteps,0, targonly);
                    
                    %********
                    if (o.BlackFixation)
                        o.hFix.beforeFrame(3);
                        o.BlackFixation = o.BlackFixation - 1;
                    end
                    %*************************************
                    
                case 5    % saccade in flight, dim fixation, just in case not done before
                    
                    % Disappear the last face
                    
                    % Aperture outlines
                    if (o.DropStim == 0)
                        o.draw_apertures(); % A,P.bkgd,colorstep,dotcolorsteps,0, targonly);
                    end
                    
                    %********
                    if (o.BlackFixation)
                        o.hFix.beforeFrame(3);
                        o.BlackFixation = o.BlackFixation - 1;
                    end
                    
                case {6 7} % once saccade landed, reappear stimulus,  show correct option
                    
                    % Face instead of grating if correct, as an extra reward
                    %********* Modified by Shanna to give 300ms motion after
                    if o.P.sigma1 >= 1.0
                        if (currentTime > o.responseEnd + o.P.dotdelay)
                            if ~o.error
                                o.Faces.beforeFrame();
                            end
                        else
                            if (o.DropStim == 0)
                                o.draw_apertures();
                            end
                            if (o.BlackFixation)
                                o.hFix.beforeFrame(3);
                                o.BlackFixation = o.BlackFixation - 1;
                            end
                        end
                    else
                        if (o.DropStim == 0)
                            o.draw_apertures();
                        end
                        if (o.BlackFixation)
                            o.hFix.beforeFrame(3);
                            o.BlackFixation = o.BlackFixation - 1;
                        else
                            if ~o.error
                                o.Faces.beforeFrame();
                            end
                        end
                    end
                    
                    
                case 8
                    if ( (o.error == 2) || (o.error == 6) )  % fixation break
                        o.hFix.beforeFrame(3);
                        o.RunFixBreakSound = 1;
                    end
                    % leave a blank ITI, or give error feedback
            end
            
            %******** fade in peripheral apertures during fixation
            if (o.P.dotFade < 0)
                if (o.colorstep > o.P.dotColor)
                    o.colorstep = o.colorstep + o.P.dotFade;
                end
            else
                if (o.colorstep < o.P.dotColor)
                    o.colorstep = o.colorstep + o.P.dotFade;
                end
            end
            %************** update state on dot fields
            for k = 1:o.nDots
                o.hDots{k}.afterFrame;
            end
            
            %******** if sound, do here
            if (o.RunFixBreakSound == 1) && (o.NeverBreakSoundTwice == 0)
                sound(o.fixbreak_sound,o.fixbreak_sound_fs);
                o.NeverBreakSoundTwice = 1;
            end
            %**************************************************************
        end
        
        function Iti = end_run_trial(o)
            Iti = o.Iti - (GetSecs - o.itiStart); % returns generic Iti interval
        end
        
        function plot_trace(o,handles)
            %********* append other things eye trace plots if you desire
            h = handles.EyeTrace;
            set(h,'NextPlot','Replace');
            eyeRad = handles.eyeTraceRadius;
            % Fixation window
            r = o.P.fixWinRadius;
            fixX = 0;
            fixY = 0;
            plot(h,fixX+r*cos(0:.01:1*2*pi),fixY+r*sin(0:.01:1*2*pi),'--k');
            set(h,'NextPlot','Add');
            % Stimulus window
            stimX = o.P.xDeg;
            stimY = o.P.yDeg;
            minR = o.P.stimWinMinRad;
            maxR = o.P.stimWinMaxRad;
            errT = o.P.stimWinTheta;
            stimT = atan2(stimY,stimX);
            %******* plot pie slice
            plot(h,[minR*cos(stimT+errT) maxR*cos(stimT+errT)],[minR*sin(stimT+errT) maxR*sin(stimT+errT)],'--k');
            plot(h,[minR*cos(stimT-errT) maxR*cos(stimT-errT)],[minR*sin(stimT-errT) maxR*sin(stimT-errT)],'--k');
            plot(h,minR*cos(stimT-errT:pi/100:stimT+errT),minR*sin(stimT-errT:pi/100:stimT+errT),'--k');
            plot(h,maxR*cos(stimT-errT:pi/100:stimT+errT),maxR*sin(stimT-errT:pi/100:stimT+errT),'--k');
            %****** plot aperture of stim
            r = o.P.apertureRadius;
            plot(h,stimX+r*cos(0:.01:1*2*pi),stimY+r*sin(0:.01:1*2*pi),'-k');
            %****** plot cue line with its length *******
            nomo = sqrt( stimX^2 + stimY^2 );
            H = plot(h,[0,(o.P.sigma1*stimX/nomo)],[0,(o.P.sigma1*stimY/nomo)],'b-');
            set(H,'Linewidth',3);
            %*********************
            axis(h,[-eyeRad eyeRad -eyeRad eyeRad]);
        end
        
        function PR = end_plots(o,P,A)   %update D struct if passing back info
            
            %************* STORE DATA to PR
            %**** NOTE, no need to copy anything from P itself, that is saved
            %**** already on each trial in data .... copy parts that are not
            %**** reflected in P at all and generated random per trial
            PR = struct;
            PR.error = o.error;
            PR.fixDur = o.fixDur;
            PR.dotmotion = o.dotmotion;   % all info about dot motion stims
            PR.target_item = o.target_item;
            PR.DotLoc = o.DotLoc;
            %******* this is also where you could store Gabor Flash Info
            
            %%%% Record some data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%% It is advised not to store things too large here, like eye movements,
            %%%% that would be very inefficient as the experiment progresses
            o.D.error(A.j) = o.error;
            o.D.fixDur(A.j) = o.fixDur;
            o.D.cued(A.j) = o.cued;
            o.D.delayNumber(A.j) = P.sigma1;
            if (o.D.delayNumber(A.j) < 1.0)
                o.D.x(A.j) = 0;  % fixation trial
                o.D.y(A.j) = 0;  % fixation trial
            else
                o.D.x(A.j) = P.xDeg;
                o.D.y(A.j) = P.yDeg;
            end
            o.D.delay(A.j) = P.delay;
            o.D.targloc(A.j) = o.DotLoc(o.target_item);  % integer rep of targ location
            o.D.single(A.j) = P.SingletonTrial;   % flag which trials are singleton
            
            %%%% Plot results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Dataplot 1, errors
            errors = [0 1 2 3 4 5 6;
                sum(o.D.error==0) sum(o.D.error==1) sum(o.D.error==2) sum(o.D.error==3) sum(o.D.error==4) sum(o.D.error==5) sum(o.D.error==6)];
            bar(A.DataPlot1,errors(1,:),errors(2,:));
            title(A.DataPlot1,'Errors');
            ylabel(A.DataPlot1,'Count');
            set(A.DataPlot1,'XLim',[-.75 6.75]);
            x = errors(1,:);
            y = 0.15*max(ylim);
            h = [];
            for ii = 1:size(errors,2)
                axes(A.DataPlot1); %#ok<LAXES>
                h(ii) = text(x(ii),y,sprintf('%i',errors(2,ii)),'HorizontalAlignment','Center');
                if errors(2,ii) > 2*y
                    set(h(ii),'Color','w');
                end
            end
            
            % DataPlot2, fraction correct by spatial location but
            % Note that this plot will break down if multiple stimulus eccentricities
            % or a non horizontal hexagon are used. It will also only calculate
            % fraction correct for locations assigned by the trials list.
            locs = sort( unique(o.D.targloc) );  % integer reps of target location
            lablist = cell(1,8);
            lablist{1} = 'R'; lablist{2} = 'UR'; lablist{3} = 'U'; lablist{4} = 'UL';
            lablist{5} = 'L'; lablist{6} = 'DL'; lablist{7} = 'D'; lablist{8} = 'DR';
            nlocs = length(locs);
            labelsloaded = 0;
            if ~isempty(locs)
                labels = cell(1,nlocs);
                fcXxy = zeros(1,nlocs);
                Fraction = zeros(1, nlocs);
                for i = 1:nlocs
                    ti = locs(i);
                    Ncorrect = sum(o.D.targloc == ti & o.D.error == 0 & o.D.cued == 0 & o.D.delayNumber > 1.0 & o.D.single == 0);
                    Ntotal = sum(o.D.targloc == ti & o.D.cued == 0 & o.D.delayNumber > 1.0 & o.D.single == 0 & ...
                        (o.D.error == 0 | o.D.error > 1.5 & o.D.error < 6 & o.D.delayNumber > 1.0));
                    if  Ntotal > 0
                        fcXxy(i) = Ncorrect/Ntotal;
                        Fraction(i) = fcXxy(i);
                    end
                    %   Constructs labels based on the 8 locations
                    if (ti>=1) && (ti<=8)
                        labelsloaded = 1;
                        labels{i} = lablist{ti};
                    end
                end
                bar(A.DataPlot2,1:nlocs,fcXxy);
                title(A.DataPlot2,'By Location (Pred)');
                ylabel(A.DataPlot2,'Fraction Correct');
                if (labelsloaded)
                    set(A.DataPlot2,'XTickLabel',labels); % Hard coded for eight positions
                end
                axis(A.DataPlot2,[.25 nlocs+.75 0 1]);
            end
            
            cpds = unique(o.D.delay);
            ncpds = length(cpds);
            fcXcpd = zeros(1,ncpds);
            labels = cell(1,ncpds);
            for i = 1:ncpds
                cpd = cpds(i);
                Ncorrect = sum(o.D.delay == cpd & o.D.error == 0);
                Ntotal = sum(o.D.delay == cpd & (o.D.error == 0 | o.D.error > 1.5 & o.D.error < 6));
                if Ntotal > 0
                    fcXcpd(i) = Ncorrect/Ntotal;
                end
                labels{i} = num2str(round(10*cpd)/10);
            end
            bar(A.DataPlot3,1:ncpds,fcXcpd,'group');
            title(A.DataPlot3,'By Delay Time');
            ylabel(A.DataPlot3,'Fraction Corret');
            set(A.DataPlot3,'XTickLabel',labels);
            axis(A.DataPlot3,[.25 ncpds+.75 0 1]);
        end
        
    end % methods
    
end % classdef
