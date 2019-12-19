classdef PR_Flag_back < handle
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
       stimOnset double = 0;      % jitter timing of target onset
       stimTime double = 0;       % mark when stim did onset (state move)
       stimOffset double = 0;     % mark frame time of stim offset
       responseStart double = 0;  % response period start time
       responseEnd double = 0;    % time entering response period
       dotflip double = 0;        % integer to know dots turn off
       DropStim double = 0;       % if 1, trial where dots disappear on saccade
       rewardCount double = 0;    % counter for reward drops
       RunFixBreakSound double = 0;       % variable to initiate fix break sound (only once)
       NeverBreakSoundTwice double = 0;   % other variable for fix break sound
       flashCounter double = 0;   % counts frames, used for fade in point cue?
       showFix logical = true;    % for flashing fix point to start trial
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
    hProbe = [];       % object for Dot Motion stimuli
    hNoise = [];       % random flashing background grating
    noiseNum = 1;      % number of oriented textures
    fixbreak_sound;    % audio of fix break sound
    fixbreak_sound_fs; % sampling rate of sound
    %******* trial parameters and stored information
    stimTheta;         % direction of target per trial
    target_item;       % integer for target location, 0 -> 0 degs, counter-clock 8 locs
    targori;           % orientation of target per trial
    changori;          % orientation of change target per trial
    %******* parameters for Noise History grating stimulus 
    NoiseHistory = []; % list of noise frames over trial and their times
    MaxFrame = (120*10); % ten second maximum
    FrameCount = 0;    % count noise frames
    %****************
    D = struct;        % store PR data for end plot stats, will store dotmotion array
  end
  
  methods (Access = public)
    function o = PR_Flag(winPtr)
      o.winPtr = winPtr;
      o.trialsList = [];  % should be set by generate call
    end
    
    function state = get_state(o)
        state = o.state;
    end
    
    function initFunc(o,S,P);
  
       %********** Set-up for trial indexing (required) 
       cors = [0];  % count these errors as correct trials
       reps = [1:7];  % count these errors like aborts, repeat
       if (~isempty(o.trialsList))
         o.trialIndexer = marmoview.TrialIndexer(o.trialsList,P,cors,reps);
       else
         disp('Error generating proper trialsList .... check function');
       end
       o.error = 0;
       
       %******* init Noise History with MaxDuration **************
       o.NoiseHistory = zeros(o.MaxFrame,2);
       
       %******* init reward face for correct trials
       o.Faces = stimuli.gaussimages(o.winPtr,'bkgd',S.bgColour,'gray',false);   % color images
       o.Faces.loadimages('./SupportData/MarmosetFaceLibrary.mat');
       o.Faces.position = [0,0]*S.pixPerDeg + S.centerPix;
       o.Faces.radius = round(P.faceradius*S.pixPerDeg);
       o.Faces.imagenum = 1;  % start first face

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

       %***** create a Gabor target grating
       o.hProbe = cell(1,2);
       for k = 1:2
           o.hProbe{k} = stimuli.grating(o.winPtr);  % grating probe
           o.hProbe{k}.transparent = -P.probecon;  % blend in proportion to gauss
           o.hProbe{k}.gauss = true;
           o.hProbe{k}.pixperdeg = S.pixPerDeg;
       end
       %***** but don't set stim properties yet
       o.noiseNum = P.noisenum;
       % Make Noise stimulus textures, pre-allocate textures for speed
       o.hNoise = cell(1,o.noiseNum);
       for k = 1:o.noiseNum
           o.hNoise{k} = stimuli.grating(o.winPtr);  % grating probe
           o.hNoise{k}.position = S.centerPix; 
           if isinf(P.noiseradius)
               o.hNoise{k}.radius = Inf;    %fill entire screen
               o.hNoise{k}.screenRect = S.screenRect;
           else
               o.hNoise{k}.radius = round(P.noiseradius*S.pixPerDeg);
           end
           o.hNoise{k}.orientation = (k-1) * 180 / o.noiseNum; % vertical for the righ
           o.hNoise{k}.phase = 0;
           o.hNoise{k}.cpd = P.noisecpd;  
           o.hNoise{k}.range = P.noiserange;
           o.hNoise{k}.square = logical(P.squareWave);
           o.hNoise{k}.gauss = true;
           o.hNoise{k}.bkgd = P.bkgd;
           o.hNoise{k}.transparent = 0.5;
           o.hNoise{k}.pixperdeg = S.pixPerDeg;
           o.hNoise{k}.updateTextures();
       end
       
       %********** load in a fixation error sound ************
       [y,fs] = audioread(['SupportData',filesep,'gunshot_sound.wav']);
       y = y(1:floor(size(y,1)/3),:);  % shorten it, very long sound
       o.fixbreak_sound = y;
       o.fixbreak_sound_fs = fs;
       %*********************
     
    end
   
    function closeFunc(o),
        o.Faces.CloseUp();
        o.hFix.CloseUp();
        for kk = 1:2
           o.hProbe{kk}.CloseUp();
        end
        for kk = 1:o.noiseNum
           o.hNoise{kk}.CloseUp();
        end
    end
   
    function generate_trialsList(o,S,P)
            % Call a function outside class (easier for us to edit)
            o.trialsList = Flag_TrialsList(S,P);
            %******** HERE FOR REFERENCE, JUST LIST THE FIELDS OF LIST
            %   Field 1, 2:   xpos and ypos of target
            %   Field 3:      orientation of target stimulus
            %   Field 4:      size of juice reward (based on condition)
            %   Field 5:      fixation trial or not
            %   Field 6:      post-saccade orientation (NaN if blank)
    end
    
    function P = next_trial(o,S,P);
            %********************
            o.S = S;
            o.P = P;
            o.FrameCount = 0;
            %*******************

            % Trials list control
            if P.runType == 1    
                     %******** Trial indexer handles trials list indexing intelligently
                     i = o.trialIndexer.getNextTrial(o.error);
                     %***************
                     P.xDeg = o.trialsList(i,1);
                     P.yDeg = o.trialsList(i,2);
                     P.ori = o.trialsList(i,3);
                     P.rewardNumber = o.trialsList(i,4);
                     P.fixation = o.trialsList(i,5);
                     P.postori = o.trialsList(i,6);
                     %******************
                     o.P = P;  % set to most current
            end
            %******* set state for DropStim
            o.DropStim = 0;  % keep target same
            if isnan(P.postori)
                o.DropStim = 2;
            else
                o.DropStim = 1;  % show other post-saccade ori
            end
          
            % Calculate this for pie slice windowing and contast cues
            o.stimTheta = atan2(P.yDeg,P.xDeg);
            % Select a face from image set to show at center
            o.Faces.imagenum = randi(length(o.Faces.tex));  % pick any at random
            % Set location of face reward
            if (P.fixation == 0)
               o.Faces.position = [P.xDeg,-P.yDeg]*S.pixPerDeg + S.centerPix;
            else
               o.Faces.position = S.centerPix;  % fixation trial, reward at center
            end

            % Make Gabor stimulus texture
            o.hProbe{1}.position = [(S.centerPix(1) + round(P.xDeg*S.pixPerDeg)),(S.centerPix(2) - round(P.yDeg*S.pixPerDeg))];
            o.hProbe{1}.radius = round(P.radius*S.pixPerDeg);
            o.hProbe{1}.orientation = P.ori; % vertical for the right
            o.targori = P.ori;
            o.hProbe{1}.phase = P.phase;
            o.hProbe{1}.cpd = P.cpd;
            o.hProbe{1}.cpd2 = P.cpd2;
            o.hProbe{1}.range = P.range;
            o.hProbe{1}.square = logical(P.squareWave);
            o.hProbe{1}.bkgd = P.bkgd;
            o.hProbe{1}.transparent = -P.probecon;
            o.hProbe{1}.updateTextures();
            %****** second probe of orthogonal orientation
            o.hProbe{2}.position = [(S.centerPix(1) + round(P.xDeg*S.pixPerDeg)),(S.centerPix(2) - round(P.yDeg*S.pixPerDeg))];
            o.hProbe{2}.radius = round(P.radius*S.pixPerDeg);
            o.hProbe{2}.phase = P.phase;
            o.hProbe{2}.cpd = P.cpd;
            o.hProbe{2}.cpd2 = P.cpd2;
            o.hProbe{2}.range = P.range;
            if isnan(P.postori)
                o.hProbe{2}.orientation = 0;
                o.hProbe{2}.phase = 0; % white Gabor blob
                o.hProbe{2}.cpd = 0;
                o.hProbe{2}.cpd2 = NaN;
                o.hProbe{2}.range = 4; % lowest con, hardly visible? 
            else
                o.hProbe{2}.orientation = P.postori; % vertical for the right
            end
            o.changori = P.postori;
            o.hProbe{2}.square = logical(P.squareWave);
            o.hProbe{2}.bkgd = P.bkgd;
            o.hProbe{2}.transparent = -P.probecon;
            o.hProbe{2}.updateTextures();
            
            %******** Probably more complicated than necessary, but it works
            %*********** setup aperture position and direction of motion
            aR = round(P.radius*S.pixPerDeg);
            aC = S.pixPerDeg*norm([P.xDeg P.yDeg]);
            my_radius = norm([P.xDeg P.yDeg]);
            o.target_item = -1;
            z = 1;
            for i = 1:P.apertures
                   ango =  2*pi*(i-1)/P.apertures;
                   x = aC*cos(ango);
                   y = aC*sin(ango);
                   my_x = my_radius * cos(ango);  % in visual degs
                   my_y = my_radius * sin(ango);  % in vis degs
                   %**************************
                   dist = sqrt( (P.xDeg - my_x)^2 + (P.yDeg - my_y)^2 );
                   if (dist < 0.5)
                       o.target_item = z;
                   end
                   z = z + 1;
                   %**********************************************
            end
    end
    
    function [FP,TS] = prep_run_trial(o)
            %********** Trial delay times *******************
            o.fixDur = o.P.fixMin + ceil(1000*o.P.fixRan*rand)/1000;
            %******* jitter timing of Stim Onset
            if (o.P.fixation == 1)
                o.stimOnset = 0;
            else
               o.stimOnset = rand * o.P.stimOnDel;
            end
            %*********************
            o.dotflip = 0;  % default
            
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
            % showFix is a flag to check whether to show the fixation spot or not while
            % it is flashing in state 0
            o.showFix = true;
            % flashCounter counts the frames to switch ShowFix off and on
            o.flashCounter = 0;
            %****** mark time of stim offset for analysis, 0 if not marked
            o.stimOffset = 0;
            % rewardCount counts the number of juice pulses, 1 delivered per frame
            % refresh
            o.rewardCount = 0;
            %****** deliver sound on fix breaks
            o.RunFixBreakSound =0;
            o.NeverBreakSoundTwice = 0;  
            %************
            % Grab start time and initial eye data
            % The reason 5 repeats are collected is for eye point smoothing
           
            %******* Plot States Struct (show fix in blue for eye trace)
                      % any special plotting of states, 
                      % FP(1).states = 1:2; FP(1).col = 'b';
                      % would show states 1,2 in blue for eye trace
            FP(1).states = 1:3;  %before fixation
            FP(1).col = 'b';
            FP(2).states = 4;  % fixation held
            FP(2).col = 'g';
            FP(3).states = 5;  % saccade in flight 
            FP(3).col = 'm';
            FP(4).states = 6:7;  % holding at target 
            FP(4).col = 'r';
            TS = 1:7;  % most states are time sensitive due to dot motion
            %****************
            o.startTime = GetSecs;
            o.responseEnd = o.startTime;   %over-written later, but crashes first trial if not
            o.Iti = o.P.iti;  % default ITI, could be longer if error        
    end
    
    function updateNoise(o,xx,yy)
         if (o.FrameCount < o.MaxFrame)  
            kk = 0;
            if (o.P.noiserange)
              if (rand < o.P.probNoise)  % fraction of grating noise impulses
                 kk = randi(o.noiseNum);
                 if ~isnan(xx) && ~isnan(yy)
                  o.hNoise{kk}.position = [(o.S.centerPix(1) + round(xx*o.S.pixPerDeg)),(o.S.centerPix(2) - round(yy*o.S.pixPerDeg))];
                 else
                  o.hNoise{kk}.position = o.S.centerPix; 
                 end    
                 o.hNoise{kk}.beforeFrame();
              end
            end
            %**********
            o.FrameCount = o.FrameCount + 1;
            o.NoiseHistory(o.FrameCount,2) = kk;  % store orientation number
            %**********
         end
    end    
    
    function keepgoing = continue_run_trial(o,screenTime)
        keepgoing = 0;
        if (o.state < 9)
            keepgoing = 1;
        end
        %********* good place to store screen flip times
        if (o.FrameCount)
          o.NoiseHistory(o.FrameCount,1) = screenTime;  % screen flip
        end
        %**********************************************
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
            o.error = 2; % Error 2 is failure to hold fixation
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

         if o.state == 3 && currentTime > o.stimStart + o.stimOnset
            o.state = 4; % show stim, marmoset can go
            o.stimTime = GetSecs;
            if (o.P.fixation == 1)
                o.state = 7;
                o.itiStart = o.stimTime;
            else
                if (isfield(o.P,'rewardFix'))
                   if (o.P.rewardFix)
                     drop = 1; % DELIVER REWARD
                   end
                end
            end
            % for staying center
         end


         % Eye must leave fixation within stimulus duration or counted as no
         % response after some much longer interval
         if o.state == 4 && currentTime > o.stimStart + o.P.noresponseDur
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
               if currentTime > o.itiStart + 0.2 * o.rewardCount  % deliver in 200 ms increments before face reward
                 o.rewardCount = o.rewardCount + 1;
                 drop = 1;
                 if (o.P.fixation == 0)
                    o.dotflip = 1;   
                 end
               end
            else
                o.state = 8;
            end
        end
        if o.state == 8
                if currentTime > o.itiStart + 0.2  % enough time to flash fix break 
                  o.state = 9; 
                  if o.error 
                     if (o.error == 1)
                         Iti = o.P.iti + o.P.abort_iti;
                     else
                         Iti = o.P.iti + o.P.blank_iti;
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
                end
                % Aperture outlines

            case 1
                
                % Update background noise flashing
                o.updateNoise(NaN,NaN);
                % Hold fixation some period
                o.hFix.beforeFrame(1);  % very brief, in case were at
                                        % fixation as trial started
                
            case 2

                % Update background noise flashing
                o.updateNoise(NaN,NaN);
                % continue to hold fixation   
                
            case 3    % show gaze cue

                % Update background noise flashing
                o.updateNoise(NaN,NaN);  
               
            case 4    % waiting for him to leave fixation 
                % Disappear the fixation spot 

                % Update background noise flashing
                o.updateNoise(NaN,NaN);
                % show grating target
                if (o.P.fixation == 0)
                    if (currentTime < o.stimTime + o.P.stimDur)
                       o.hProbe{1}.beforeFrame();
                    else
                       if (o.stimOffset == 0)
                           o.stimOffset = GetSecs; % will be off next frame flip
                       end
                    end
                end

            case 5    % saccade in flight, dim fixation, just in case not done before
                             
                % Disappear the last face
                if (o.P.fixation == 0)
                  if (o.DropStim == 0)
                      % show grating target
                      o.hProbe{1}.beforeFrame();
                  else % for Drop Stimulus, instead swap to orthogonal texture
                      o.hProbe{2}.beforeFrame();
                  end
                end

            case {6 7} % once saccade landed, reappear stimulus,  show correct option
                               
                % Face instead of grating if correct, as an extra reward
                %********* Modified by Shanna to give 300ms motion after
                if (o.P.fixation == 0) 
                       if (currentTime > o.responseEnd + o.P.dotdelay)
                           if ~o.error
                              o.Faces.beforeFrame();  
                           end
                       else
                           if (o.DropStim == 0)
                               % show grating target
                               o.hProbe{1}.beforeFrame();
                           else
                               % show grating target
                               o.hProbe{2}.beforeFrame();
                           end
                       end
                else
                      if ~o.error  
                             o.Faces.beforeFrame();  
                      end
                end


            case 8
               if ( (o.error == 2) || (o.error == 6) )  % fixation break
                    o.hFix.beforeFrame(3);
                    o.RunFixBreakSound = 1;
                end
                % leave a blank ITI, or give error feedback          
        end
        %******** if sound, do here
        if (o.RunFixBreakSound == 1) & (o.NeverBreakSoundTwice == 0)  
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
        r = o.P.radius;
        plot(h,stimX+r*cos(0:.01:1*2*pi),stimY+r*sin(0:.01:1*2*pi),'-k');
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
        PR.target_item = o.target_item;
        PR.DropStim = o.DropStim;
        PR.targori = o.targori;
        PR.changori = o.changori; 
        PR.stimOffset = o.stimOffset;  % time of offset (next frame off)
        if o.FrameCount == 0
            PR.NoiseHistory = [];
        else
            PR.NoiseHistory = o.NoiseHistory(1:o.FrameCount,:);
        end
        %******* this is also where you could store Gabor Flash Info
        
        %%%% Record some data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%% It is advised not to store things too large here, like eye movements, 
        %%%% that would be very inefficient as the experiment progresses
        o.D.error(A.j) = o.error;
        o.D.fixDur(A.j) = o.fixDur;
        if (P.fixation == 1)
           o.D.x(A.j) = 0;  % fixation trial
           o.D.y(A.j) = 0;  % fixation trial
        else
           o.D.x(A.j) = P.xDeg;
           o.D.y(A.j) = P.yDeg;
        end
        o.D.delay(A.j) = 0; % not used anymore, P.delay;
        o.D.targloc(A.j) = o.target_item;
        o.D.fixation(A.j) = P.fixation;
        
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
        for ii = 1:size(errors,2),
          axes(A.DataPlot1);
          h(ii) = text(x(ii),y,sprintf('%i',errors(2,ii)),'HorizontalAlignment','Center');
          if errors(2,ii) > 2*y,
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
            Ncorrect = sum(o.D.targloc == ti & o.D.error == 0 & o.D.fixation == 0);
            Ntotal = sum(o.D.targloc == ti & o.D.fixation == 0 & ...
                         (o.D.error == 0 | o.D.error > 1.5 & o.D.error < 6 ));
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
        
        %******* performance for targeted saccades or fixation trials
        cpds = unique(o.D.fixation);
        ncpds = length(cpds); 
        fcXcpd = zeros(1,ncpds);
        labels = cell(1,ncpds);
        for i = 1:ncpds
            cpd = cpds(i);
            Ncorrect = sum(o.D.fixation == cpd & o.D.error == 0);
            Ntotal = sum(o.D.fixation == cpd & (o.D.error == 0 | o.D.error > 1.5 & o.D.error < 6));
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
