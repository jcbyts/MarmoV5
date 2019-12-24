classdef PR_FixRsvpStim < handle
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
       faceTrial logical = true;  % trial with face to start
       showFix logical = true;    % trial start with fixation
       flashCounter double = 0;   % counter to flash fixation
       rewardCount double = 0;    % counter for reward drops
       RunFixBreakSound double = 0;       % variable to initiate fix break sound (only once)
       NeverBreakSoundTwice double = 0;   % other variable for fix break sound
       BlackFixation double = 6;          % frame to see black fixation, before reward
       ImCounter double = 1;             % counter for Gabor flashing stimuli
       updateEveryNFrames double = 12
       ImSequence = 1:60
       GazeContingent logical = false
  end
      
  properties (Access = private)
    winPtr; % ptb window
    state double = 0;      % state counter
    error double = 0;      % error state in trial
    %*********
    S;      % copy of Settings struct (loaded per trial start)
    P;      % copy of Params struct (loaded per trial)
    %********* stimulus structs for use
    Faces;             % object that stores face images for use
    hFix;              % object for a fixation point
    fixbreak_sound;    % audio of fix break sound
    fixbreak_sound_fs; % sampling rate of sound
    %*********
    NoiseHistory = []; % list of noise frames over trial and their times
    FrameCount = 0;    % count noise frames
    MaxFrame = (120*20); % twenty second maximum
    %****************
    D = struct;        % store PR data for end plot stats
  end
  
  methods (Access = public)
    function o = PR_FixRsvpStim(winPtr)
      o.winPtr = winPtr;     
    end
    
    function state = get_state(o)
        state = o.state;
    end
    
    function initFunc(o,S,P)
 
        o.Faces = stimuli.gaussimages(o.winPtr,'bkgd',S.bgColour,'gray',false);   % color images
        o.Faces.loadimages('./SupportData/rsvpFixStim.mat');
        o.Faces.position = [0,0]*S.pixPerDeg + S.centerPix;
        o.Faces.radius = round(P.faceRadius*S.pixPerDeg);
   
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
        %**********************************
   
        %******** store history of flashed gratings
        o.NoiseHistory = nan(o.MaxFrame,4);   %time, x, y, id
        
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
    end
   
    function generate_trialsList(o,S,P)
           % nothing for this protocol
    end
    
    function P = next_trial(o,S,P)
          %********************
          o.S = S;
          o.P = P;      
          o.FrameCount = 0;   % for noise history
          %*******************
        
          %%%% Trial control -- Update certain parameters depending on run type %%%%%
          switch o.P.runType
            case 1  % Staircasing
                % If correct, small increment in fixation duration
                if ~o.error
                    P.fixMin = P.fixMin + S.staircase.up(1);
                    P.fixRan = P.fixRan + S.staircase.up(2);
                    % cannot exceed limit
                    P.fixMin = min([P.fixMin S.staircase.durLims(3)]);
                    P.fixRan = min([P.fixRan S.staircase.durLims(4)]);
                % If entered fixationand failed to maintain it, large reduction in
                % fixation duration
                elseif o.error == 2
                    P.fixMin = P.fixMin - S.staircase.down(1);
                    P.fixRan = P.fixRan - S.staircase.down(2);
                    % cannot exceed limit
                    P.fixMin = max([P.fixMin S.staircase.durLims(1)]);
                    P.fixRan = max([P.fixRan S.staircase.durLims(2)]);
                end
          end
          %*************************************
          
          % Set up fixation duration
          o.fixDur = P.fixMin + ceil(1000*P.fixRan*rand)/1000;

          % Reward schedule is automated based on fix duration for staircasing
          if S.runType
              P.rewardNumber = find(o.fixDur > S.staircase.rewardSchedule,1,'last');
          end

          % Select a face from image set to show at center
          o.Faces.imagenum = randi(length(o.Faces.tex));  % pick any at random
          if rand < P.faceTrialFraction
              o.faceTrial = true;
          else
              o.faceTrial = false;
          end
    end
    
    function [FP,TS] = prep_run_trial(o)
        
          %********VARIABLES USED IN RUNNING TRIAL LOGISTICS
          % showFix is a flag to check whether to show the fixation spot or not while
          % it is flashing in state 0
          o.showFix = true;
          % flashCounter counts the frames to switch ShowFix off and on
          o.flashCounter = 0;
          % rewardCount counts the number of juice pulses, 1 delivered per frame
          o.rewardCount = 0;
          %****** deliver sound on fix breaks
          o.RunFixBreakSound =0;
          o.NeverBreakSoundTwice = 0;  
          o.BlackFixation = 6;  % frame to see black fixation, before reward
          o.ImCounter = 1;
          % Setup the state
          o.state = 0; % Showing the face
          o.error = 0; % Start with error as 0
          o.Iti = o.P.iti;   % set ITI interval from P struct stored in trial
          %******* Plot States Struct (show fix in blue for eye trace)
          % any special plotting of states, 
          % FP(1).states = 1:2; FP(1).col = 'b';
          % would show states 1,2 in blue for eye trace
          FP(1).states = 1;  %before fixation
          FP(1).col = 'k';
          FP(2).states = 2;  % fixation held
          FP(2).col = 'b';
          %******* set which states are TimeSensitive, if [] then none
          TS = 2;  % state 2 is senstive, during Gabor flashing
          %********
          o.startTime = GetSecs;
    end
    
    function keepgoing = continue_run_trial(o,screenTime)
        keepgoing = 0;
        if (o.state < 4)
            keepgoing = 1;
        end
        %****** store the last screen flip for noise history
        if (o.FrameCount)
           o.NoiseHistory(o.FrameCount,1) = screenTime;
        end
        %*******************    
    end
   
    %******************** THIS IS THE BIG FUNCTION *************
    function drop = state_and_screen_update(o,currentTime,x,y) 
        drop = 0;
        %******* THIS PART CHANGES WITH EACH PROTOCOL ****************

        %%%%% STATE 0 -- GET INTO FIXATION WINDOW %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % If eye travels within the fixation window, move to state 1
        if o.state == 0 && norm([x y]) < o.P.fixWinRadius
           o.state = 1; % Move to fixation grace
           o.fixStart = GetSecs;
        end
        % Trial expires if not started within the start duration
        if o.state == 0 && currentTime > o.startTime + o.P.startDur
           o.state = 3; % Move to iti -- inter-trial interval
           o.error = 1; % Error 1 is failure to initiate
           o.itiStart = GetSecs;
        end
    
        %%%%% STATE 1 -- GRACE PERIOD TO BE IN FIXATION WINDOW %%%%%%%%%%%%%%%%
        % A grace period is given before the eye must remain in fixation
        if o.state == 1 && currentTime > o.fixStart + o.P.fixGrace
            o.state = 2; % Move to hold fixation
        end
    
        %%%%% STATE 2 -- HOLD FIXATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if o.state == 2    % show flashing stimuli at random points each frame
            %***pick a random screen location but not overlapping fixation
            ampo = o.P.gabMinRadius + (o.P.gabMaxRadius-o.P.gabMinRadius)*rand;
            ango = rand*2*pi;
            dx = cos(ango)*ampo;
            dy = sin(ango)*ampo;
            cX = o.S.centerPix(1)+ round( o.S.pixPerDeg * dx);
            cY = o.S.centerPix(2)+ round( o.S.pixPerDeg * dy);   %
            %****** update one of the Gabor's locations
            %****** store starting locations, set time as NaN
            o.FrameCount = o.FrameCount + 1;
            if mod(o.FrameCount, o.updateEveryNFrames)==0
                o.ImCounter = o.ImCounter + 1;
                if (o.ImCounter > numel(o.ImSequence))
                    o.ImCounter = 1;
                end
                o.Faces.imagenum = o.ImSequence(o.ImCounter);
                if o.GazeContingent
                    o.Faces.position = [o.S.centerPix(1)+x, o.S.centerPix(2)+y];
                end
            end
            o.NoiseHistory(o.FrameCount,:) = [NaN,o.Faces.position,o.Faces.imagenum];
            %*********************
            
            
        end
    
        % If fixation is held for the fixation duration, then reward
        if o.state == 2 && currentTime > o.fixStart + o.fixDur
            o.state = 3; % Move to iti -- inter-trial interval
            o.itiStart = GetSecs;
        end
        % Eye must remain in the fixation window
        if o.state == 2 && norm([x y]) > o.P.fixWinRadius
            o.state = 3; % Move to iti -- inter-trial interval
            o.error = 2; % Error 2 is failure to hold fixation
            o.itiStart = GetSecs;
        end
    
        %%%%% STATE 3 -- INTER-TRIAL INTERVAL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Deliver rewards
        if o.state == 3 
           if ~o.error && o.rewardCount < o.P.rewardNumber
             if currentTime > o.itiStart + 0.2*o.rewardCount % deliver in 200 ms increments
               o.rewardCount = o.rewardCount + 1;
               drop = 1;   % this is where you return with instruction to give reward
             end
           else
             if currentTime > o.itiStart + 0.2   % enough time to flash fix break 
               o.state = 4; 
               if o.error 
                 o.Iti = o.P.iti + o.P.timeOut;
               end
             end
           end
        end
    
        % STATE SPECIFIC DRAWS
        switch o.state
            case 0
                if o.showFix
                    if ~o.faceTrial
                         o.hFix.beforeFrame(1);
                    else
                         o.Faces.beforeFrame();  %draw an image at random
                    end
                end
                o.flashCounter = mod(o.flashCounter+1,o.P.flashFrameLength);
                if o.flashCounter == 0
                    o.showFix = ~o.showFix;
                    if o.showFix && o.faceTrial
                        if rand < o.P.faceTrialFraction
                            o.faceTrial = true;
                        end
                    else
                        o.faceTrial = false;
                    end
                end
            case 1
                o.hFix.beforeFrame(1);
            case 2    
%                 o.hFix.beforeFrame(1);
                o.Faces.beforeFrame();
            case 3
                if ~o.error
                    if (o.BlackFixation)
                       o.hFix.beforeFrame(3);
                       o.BlackFixation = o.BlackFixation - 1; 
                    else
                       o.Faces.beforeFrame(); 
                    end
                end
                if (o.error == 2)  % fixation break
                    o.hFix.beforeFrame(2);
                    o.RunFixBreakSound = 1;
                end
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
        fixX = o.P.xDeg;
        fixY = o.P.yDeg;
        plot(h,fixX+r*cos(0:.01:1*2*pi),fixY+r*sin(0:.01:1*2*pi),'--k');
        axis(h,[-eyeRad eyeRad -eyeRad eyeRad]);
        set(h,'NextPlot','Add');
    end
    
    function PR = end_plots(o,P,A)   %update D struct if passing back info
        
        %************* STORE DATA to PR
        PR = struct;
        PR.error = o.error;
        PR.fixDur = o.fixDur;
        PR.x = P.xDeg;
        PR.y = P.yDeg;
        %******* this is also where you store Gabor Flash Info
        PR.NoiseHistory = o.NoiseHistory(1:o.FrameCount,:);
    
        %%%% Record some data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        o.D.error(A.j) = o.error;
        o.D.x(A.j) = P.xDeg;
        o.D.y(A.j) = P.yDeg;
        o.D.fixDur(A.j) = o.fixDur;
        
        %%%% Plot results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Dataplot 1, errors
        errors = [0 1 2; sum(o.D.error==0) sum(o.D.error==1) sum(o.D.error==2)];
        bar(A.DataPlot1,errors(1,:),errors(2,:));
        title(A.DataPlot1,'Errors');
        ylabel(A.DataPlot1,'Count');
        set(A.DataPlot1,'XLim',[-.75 errors(1,end)+.75]);

        %% show the number - 2016-05-05 - Shaun L. Cloherty <s.cloherty@ieee.org> 
        x = errors(1,:);
        y = 0.15*max(ylim);

        h = [];
        for ii = 1:size(errors,2)
          axes(A.DataPlot1);
          h(ii) = text(x(ii),y,sprintf('%i',errors(2,ii)),'HorizontalAlignment','Center');
          if errors(2,ii) > 2*y
            set(h(ii),'Color','w');
          end
        end
        %%

        % Dataplot 2, wait time histogram
        if any(o.D.error==0)
            hist(A.DataPlot2,o.D.fixDur(o.D.error==0));
        end
        % title(A.DataPlot2,'Successful Trials');
        % show the numbers - 2016-05-06 - Shaun L. Cloherty <s.cloherty@ieee.org> 
        title(A.DataPlot2,sprintf('%.2fs %.2fs',median(o.D.fixDur(o.D.error==0)),max(o.D.fixDur(o.D.error==0))));
        ylabel(A.DataPlot2,'Count');
        xlabel(A.DataPlot2,'Time');

    end
    
  end % methods
    
end % classdef
