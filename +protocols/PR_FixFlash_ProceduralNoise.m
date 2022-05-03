classdef PR_FixFlash_ProceduralNoise < handle
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
       GABcounter double = 1;             % counter for Gabor flashing stimuli
        
       % ******* Parameters for tracking fixation
       fixHistory = [] % like noise history

       %******** Procedural Noise parameters ****
       hNoise = []       % random flashing background grating
       noiseNum = 1      % number of oriented textures
       spatoris = []     % list of tested orientations
       spatfreqs = []    % list of tested spatial freqs
       %******* parameters for Noise History grating stimulus
       noisetype = 0     % type of background noise stimulus
       NoiseHistory = [] % list of noise frames over trial and their times
       FrameCount = 0    % count noise frames
       ProbeHistory = [] % list of history for probe objects
       PFrameCount = 0   % count probe frames (should be same as noise for now)
       MaxFrame = (120*20); % twenty second maximum
       TrialDur = 0;     % store internally the trial duration (make less than 20)
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

    %****************
    D = struct;        % store PR data for end plot stats
  end
  
  methods (Access = public)
    function o = PR_FixFlash_ProceduralNoise(winPtr)
      o.winPtr = winPtr;     
    end
    
    function state = get_state(o)
        state = o.state;
    end
    
    function initFunc(o,S,P)
 
        o.Faces = stimuli.gaussimages(o.winPtr,'bkgd',S.bgColour,'gray',false);   % color images
        o.Faces.loadimages('./SupportData/MarmosetFaceLibrary.mat');
        o.Faces.position = [0,0]*S.pixPerDeg + S.centerPix;
        o.Faces.radius = round(P.faceRadius*S.pixPerDeg);
   
        %******* create fixation point ****************
        o.hFix = stimuli.fixation(o.winPtr);   % fixation stimulus
        o.fixHistory = nan(o.MaxFrame, 3); % time, fix state (1, 2, 3, 0=off, -1+=face)
        
        % set fixation point properties
        sz = P.fixPointRadius*S.pixPerDeg;
        o.hFix.cSize = sz;
        o.hFix.sSize = 2*sz;
        o.hFix.cColour = ones(1,3); % black
        o.hFix.sColour = repmat(255,1,3); % white
        o.hFix.position = [0,0]*S.pixPerDeg + S.centerPix;
        o.hFix.updateTextures();
        %**********************************
   
        %************** PROCEDURAL NOISE **********************
        %******* SETUP NOISE BACKGROUND BASED ON TYPE, HARTLEY, SPATIAL, ETC
        o.noisetype = P.noisetype;
        %**********

        switch o.noisetype

            %***************************************************************
            % for o.noisetype == 0 would be no background at all!
            case 0 % no background
                o.noiseNum = 0;
                o.hNoise = [];

                %***************************************************************
            case 1 % "Hartley" background

                o.NoiseHistory = nan(o.MaxFrame,3);

                % select spatial frequencies
                if (P.spfnum > 1) && (P.spfmax > P.spfmin)
                    o.spatfreqs = exp( log(P.spfmin):(log(P.spfmax)-log(P.spfmin))/(P.spfnum-1):log(P.spfmax));
                else
                    o.spatfreqs = ones(1,P.spfnum) * P.spfmax;
                end

                % select possible orientations
                o.spatoris = (0:(P.noiseorinum-1))*180/P.noiseorinum;
                if (isfield(P,'orioffset'))
                    o.spatoris = o.spatoris + P.orioffset;
                end
                o.noiseNum = P.noiseorinum * P.spfnum;

                % noise object is created here
                o.hNoise = stimuli.gratingFFnoise(o.winPtr, 'pixPerDeg', S.pixPerDeg);
                o.hNoise.numOrientations = P.noiseorinum;
                o.hNoise.orientations = o.spatoris;
                o.hNoise.spatialFrequencies = o.spatfreqs;
                o.hNoise.randomizePhase = P.noiseRandomizePhase;
                o.hNoise.updateEveryNFrames = ceil(S.frameRate / P.noiseFrameRate);
                o.hNoise.updateTextures(); % create the procedural texture
                o.hNoise.contrast = P.noiseContrast;


                %***************************************************************
            case 2 % use Spatial reverse correlation background
                o.noiseNum = P.snoisenum * 2;
                o.NoiseHistory = nan(o.MaxFrame,(1+(o.noiseNum * 2)));  % store time, then x,y positions
                o.hNoise = cell(1,o.noiseNum);

                for k = 1:o.noiseNum
                    o.hNoise{k} = stimuli.grating_procedural(o.winPtr);  % grating probe
                    o.hNoise{k}.radius = round((P.snoisediam/2)*S.pixPerDeg);
                    o.hNoise{k}.orientation = 0; % cpd will be zero => all one color
                    if (mod(k,2) == 1)
                        o.hNoise{k}.phase = 0;   % white
                    else
                        o.hNoise{k}.phase = 180; % black
                    end
                    o.hNoise{k}.cpd = 0; % when cpd is zero, you get a Gauss
                    o.hNoise{k}.range = P.range;
                    o.hNoise{k}.square = false; % true;  % if you want circle
                    o.hNoise{k}.gauss = true;
                    o.hNoise{k}.bkgd = P.bkgd;
                    o.hNoise{k}.transparent = -0.5;
                    o.hNoise{k}.pixperdeg = S.pixPerDeg;
                    o.hNoise{k}.updateTextures();
                end

                %***************************************************************
            case 3 % CSD flash

                % CSD will be similar to hartley, but all white (SF=0)
                % and a different on duration of stimulus

                o.NoiseHistory = nan(o.MaxFrame,2);
                o.noiseNum = 1;
                o.hNoise = [];

                %***************************************************************
            case 4 % Garborium noise
                o.NoiseHistory = nan(o.MaxFrame,3);

                % noise object is created here
                o.hNoise = stimuli.gabornoise(o.winPtr, 'pixPerDeg', S.pixPerDeg, 'numGabors', P.numGabors);

                x = P.noiseCenterX*S.pixPerDeg + S.centerPix(1);
                y = -P.noiseCenterY*S.pixPerDeg + S.centerPix(2);
                o.hNoise.position = [x y];
                o.hNoise.radius = P.noiseRadius * S.pixPerDeg;
                o.hNoise.contrast = P.noiseContrast;
                o.hNoise.scaleRange = P.scaleRange;
                o.hNoise.minScale = P.minScale;
                o.hNoise.minSF = P.spfmin;
                o.hNoise.sfRange =  P.spfrange;

                o.hNoise.updateEveryNFrames = ceil(S.frameRate / P.noiseFrameRate);
                o.hNoise.updateTextures(); % create the procedural texture

            case 5 % dot spatial noise
                o.noiseNum = min(P.numDots, 100); % only store up to 500 dots
                o.NoiseHistory = nan(o.MaxFrame,(1+(o.noiseNum * 2)));
                % noise object is created here
                o.hNoise = stimuli.dotspatialnoise(o.winPtr, 'numDots', P.numDots, ...
                    'sigma', P.noiseApertureSigma*S.pixPerDeg);
                o.hNoise.contrast = P.noiseContrast;
                o.hNoise.size = P.dotSize * S.pixPerDeg;
                o.hNoise.speed = P.dotSpeedSigma * S.pixPerDeg / S.frameRate;
                o.hNoise.updateEveryNFrames = ceil(S.frameRate / P.noiseFrameRate);

                %***************************************************************
            case 6 % Drifting grating background

                o.NoiseHistory = nan(o.MaxFrame,7); % time, orientation, cpd, phase, direction, speed, contrast

                % position
                x = P.GratCtrX*S.pixPerDeg + S.centerPix(1);
                y = -P.GratCtrY*S.pixPerDeg + S.centerPix(2);

                % noise object is created here
                o.hNoise = stimuli.grating_drifting(o.winPtr, ...
                    'numDirections', P.numDir, ...
                    'minSF', P.GratSFmin, ...
                    'numOctaves', P.GratNumOct, ...
                    'pixPerDeg', S.pixPerDeg, ...
                    'frameRate', S.frameRate, ...
                    'speeds', P.GratSpeed, ...
                    'position', [x y], ...
                    'screenRect', S.screenRect, ...
                    'diameter', P.GratDiameter, ...
                    'durationOn', P.GratDurOn, ...
                    'durationOff', P.GratDurOff, ...
                    'isiJitter', P.GratISIjit, ...
                    'contrasts', P.GratCon, ...
                    'randomizePhase', P.RandPhase);

                o.hNoise.updateTextures(); % create the procedural texture

        end
        %**********************************************************

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
        if iscell(o.noiseNum) % backwards compatible with old-style noise
            for kk = 1:o.noiseNum
                if ~isempty(o.hNoise{kk})
                    o.hNoise{kk}.CloseUp();
                end
            end
        elseif isa(o.hNoise, 'stimuli.stimulus')
            o.hNoise.CloseUp();
        end
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
          o.GABcounter = 1;
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


          % ********* PROCEDURAL NOISE ******
          if isa(o.hNoise, 'stimuli.stimulus')

              if isprop(o.hNoise, 'probBlank')
                  o.hNoise.probBlank = 1-o.P.probNoise;
              end

              if isprop(o.hNoise, 'contrast') && isfield(o.P, 'noiseContrast')
                  o.hNoise.contrast = o.P.noiseContrast;
              end

              o.hNoise.beforeTrial();
          end


          o.startTime = GetSecs;
    end

    function updateNoise(o,xx,yy,currentTime)
        if (o.FrameCount < o.MaxFrame)

            switch o.noisetype

                case 1 % "Hartley" noise

                    o.hNoise.afterFrame(); % update parameters
                    o.hNoise.beforeFrame(); % draw

                    %**********
                    % NOTE: store screen time in "continue_run_trial" after flip
                    o.NoiseHistory(o.FrameCount,2) = o.hNoise.orientation;  % store orientation
                    o.NoiseHistory(o.FrameCount,3) = o.hNoise.cpd;  % store spatialfrequency


                case 2 % spatial reverse correlation
                    %******** select random locations in noise circle and draw
                    nlist = zeros(1,2*o.noiseNum);
                    for kk = 1:o.noiseNum
                        sx = (rand - 0.5) * 2 * o.P.snoisewidth;
                        sy = (rand - 0.5) * 2 * o.P.snoiseheight;
                        nlist(1,1+(kk-1)*2) = sx;
                        nlist(1,2+(kk-1)*2) = sy;
                        %*********
                        % o.hNoise{kk}.position = [(o.S.centerPix(1) + round(sx*o.S.pixPerDeg)),...
                        %                         (o.S.centerPix(2) - round(sy*o.S.pixPerDeg))];
                        % o.hNoise{kk}.beforeFrame();
                        %***********
                        if mod((kk-1),2)
                            col = 127 - o.P.range;
                        else
                            col = 127 + o.P.range;
                        end
                        position = [(o.S.centerPix(1) + round(sx*o.S.pixPerDeg)),...
                            (o.S.centerPix(2) - round(sy*o.S.pixPerDeg))];
                        r = round((o.P.snoisediam/2)*o.S.pixPerDeg);
                        rect = kron([1,1],position) + kron(r(:),[-1, -1, +1, +1]);
                        Screen('FillOval',o.winPtr,[col,col,col],rect');
                        %**************
                    end
                    %*********
                    o.NoiseHistory(o.FrameCount,:) = [NaN nlist];  % first element time, others x,y positions
                    %**********

                case 3 % CSD
                    kk = 0;
                    step = mod(o.FrameCount,(o.P.noisedur + o.P.noiseoff));
                    if (step >= o.P.noiseoff)
                        kk = 1;
                        Screen('FillRect', o.winPtr, 127 + o.P.noiserange);
                    else
                        Screen('FillRect', o.winPtr, 127);
                    end
                    %**********
                    % NOTE: store screen time in "continue_run_trial" after flip
                    o.NoiseHistory(o.FrameCount,2) = kk;  % store orientation number
                    %**********

                case 4 % "Garborium" noise

                    o.hNoise.afterFrame(); % update parameters
                    o.hNoise.beforeFrame(); % draw

                    %**********
                    % NOTE: store screen time in "continue_run_trial" after flip
                    o.NoiseHistory(o.FrameCount,2) = o.hNoise.x(1);  % xposition of first gabor
                    o.NoiseHistory(o.FrameCount,3) = o.hNoise.mypars(2);

                case 5 % dot spatial noise
                    o.hNoise.afterFrame(); % update parameters
                    o.hNoise.beforeFrame(); % draw

                    %**********
                    % NOTE: store screen time in "continue_run_trial" after flip
                    o.NoiseHistory(o.FrameCount,2:end) = [o.hNoise.x(1:o.noiseNum) o.hNoise.y(1:o.noiseNum)];  % xposition of first gabor

                case 6 % drifting gratings

                    o.hNoise.afterFrame(); % update parameters
                    o.hNoise.beforeFrame(); % draw

                    %**********
                    % NOTE: store screen time in "continue_run_trial" after flip
                    o.NoiseHistory(o.FrameCount,2) = o.hNoise.orientation;  % store orientation
                    o.NoiseHistory(o.FrameCount,3) = o.hNoise.cpd;  % store spatialfrequency
                    o.NoiseHistory(o.FrameCount,4) = o.hNoise.phase;
                    o.NoiseHistory(o.FrameCount,5) = o.hNoise.orientation-90;
                    o.NoiseHistory(o.FrameCount,6) = o.hNoise.speed;
                    o.NoiseHistory(o.FrameCount,7) = o.hNoise.contrast;

                    % time, orientation, cpd, phase, direction, speed, contrast

            end
            %****************
        end
    end
    
    function keepgoing = continue_run_trial(o,screenTime)
        keepgoing = 0;
        if (o.state < 4)
            keepgoing = 1;
        end
        %****** store the last screen flip for noise history
        if (o.FrameCount)
           o.NoiseHistory(o.FrameCount,1) = screenTime;
           o.fixHistory(o.FrameCount,1) = screenTime;
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
        o.FrameCount = o.FrameCount + 1; % always update noise counter regardless of whether the noise updates
        if o.state == 2    % show flashing stimuli at random points each frame
            % UPDATE BACKGROUND
            o.updateNoise(NaN,NaN,currentTime);
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
                         o.fixHistory(o.FrameCount,2) = 1;
                    else
                         o.Faces.beforeFrame();  %draw an image at random
                         o.fixHistory(o.FrameCount,2) = -1;
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
                o.fixHistory(o.FrameCount,2) = 1;
            case 2    
                o.hFix.beforeFrame(1);
                o.fixHistory(o.FrameCount,2) = 1;
                %***** then display all P.OriNum of the Gabors
            case 3
                if ~o.error
                    if (o.BlackFixation)
                       o.hFix.beforeFrame(3);
                       o.fixHistory(o.FrameCount,2) = 3;
                       o.BlackFixation = o.BlackFixation - 1; 
                    else
                       o.Faces.beforeFrame(); 
                       o.fixHistory(o.FrameCount,2) = 1;
                    end
                end
                if (o.error == 2)  % fixation break
                    o.hFix.beforeFrame(2);
                    o.fixHistory(o.FrameCount,2) = 2;
                    o.RunFixBreakSound = 1;
                end
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
        if o.FrameCount == 0
            PR.NoiseHistory = [];
            PR.fixHistory = [];
        else
            PR.NoiseHistory = o.NoiseHistory(1:o.FrameCount,:);
            PR.fixHistory = o.fixHistory(1:o.FrameCount,:);
        end

        if isa(o.hNoise, 'stimuli.stimulus')
            PR.hNoise = copy(o.hNoise); % store noise object
        end

        PR.noisetype = o.noisetype;

        if isa(o.hFix, 'matlab.mixin.Copyable')
            disp("COPYING FIXATION OBJECT")
            PR.hFix = copy(o.hFix);
            PR.hFace = copy(o.Faces);
        end
    
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
        for ii = 1:size(errors,2),
          axes(A.DataPlot1);
          h(ii) = text(x(ii),y,sprintf('%i',errors(2,ii)),'HorizontalAlignment','Center');
          if errors(2,ii) > 2*y,
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
