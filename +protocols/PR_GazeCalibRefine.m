classdef PR_GazeCalibRefine < protocols.protocol
  % Experimental protocol for refining gaze calibration
  % 
  % In this protocol, we show the marmoset his/her eye position for brief epochs.
  % Hopefully, they saccade at the eye position and that lets us measure the 
  %
  % The class constructor can be called with a range of arguments:
  %
 
  properties (Access = public) 
       itiStart double = 0       % start of ITI interval
       
       states double % track state transitions
       stimXY double % track the position of the stimulus at every state transition
       eyeXY  double % track position of eye at every state transition
       
       
       lastEyePos double
       eyeVelThresh double
       rewardCount double = 0            % counter for reward drops
       
       useFace logical = true            % use marmoset faces as the target
  end
      
  properties (Access = private)
    trialIndexer      % will call TrialIndexer object to choose trial numbers
    trialsList        % store copy of trial list (not good to keep in S struct)

    %********* stimulus structs for use
    Faces              % object that stores face images for use
    hFix               % object for a fixation point
    hTarg
    fixbreak_sound     % audio of fix break sound
    fixbreak_sound_fs  % sampling rate of sound
    
    D = struct         % store PR data for end plot stats, will store dotmotion array
  end
  
  methods (Access = public)
    function o = PR_GazeCalibRefine(winPtr, varargin)
      
        % instantiate object with parent class so we inherit methods and
        % properties from the protocol class
        o = o@protocols.protocol(winPtr);
    
    end
    
    function initFunc(o,S,P)
  
       
       %******* setup faces if using face
       o.Faces = stimuli.gaussimages(o.winPtr,'bkgd',S.bgColour,'gray',false);   % color images
       o.Faces.loadimages('./SupportData/MarmosetFaceLibrary.mat');
       o.Faces.position = [0,0]*S.pixPerDeg + S.centerPix;
       o.Faces.radius = round(P.targRadius*S.pixPerDeg);
       o.Faces.imagenum = 1;  % start first face
       
       
       %******* create fixation point ****************
       o.hFix = stimuli.fixation(o.winPtr);   % fixation stimulus
       % set fixation point properties
       sz = P.targRadius*S.pixPerDeg;
       o.hFix.cSize = sz;
       o.hFix.sSize = 2*sz;
       o.hFix.cColour = ones(1,3); % black
       o.hFix.sColour = repmat(255,1,3); % white
       o.hFix.position = [0,0]*S.pixPerDeg + S.centerPix;
       o.hFix.updateTextures();
       
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
        % hTarg is either Faces or hFix, so it doesn't need to close
    end
   
    
    function P = next_trial(o,S,P)
            %********************
            o.S = S;
            o.P = P;
            %*******************

            % ******* Setup all possible stimulus objects **********************

            % Select a face from image set to show at center
            o.Faces.imagenum = randi(length(o.Faces.tex));  % pick any at random

            o.hFix.updateTextures();

            if o.P.useFace
                o.hTarg = o.Faces;
            else
                o.hTarg = o.hFix;
            end

            % Set default location of target
            o.hTarg.position = S.centerPix;
            
            
    end
    
    function [FP,TS] = prep_run_trial(o)
         
      
            %******* Plot States Struct (show fix in blue for eye trace)
                      % any special plotting of states, 
                      % FP(1).states = 1:2; FP(1).col = 'b';
                      % would show states 1,2 in blue for eye trace
            FP(1).states = 1:3;  %before fixation
            FP(1).col = 'b';
            FP(2).states = 4;  % fixation held
            FP(2).col = 'g';           
            TS = 1:2;  % most states are time sensitive due to dot motion
            %****************
            
            o.state = 0;
            o.startTime = GetSecs;
            o.Iti = o.P.iti;  % default ITI, could be longer if error
            
            % initialize first state
            o.states = [o.states [o.state; o.startTime]];
            % store eye pos and stimXY as NaNs
            o.stimXY = nan(2,1);
            o.eyeXY = nan(2,1);
            
            % setup eye velocity threshold
            frameDuration = (1./o.S.frameRate);
%             pixPerSec = o.P.eyeVelThresh * o.S.pixPerDeg;

            % eye position is in d.v.a, so we want a threshold on the
            % change in degrees per frame
            o.eyeVelThresh = o.P.eyeVelThresh * frameDuration;
            
            o.lastEyePos = [0 0]; % initialize eye position tracking
    end
    
    function keepgoing = continue_run_trial(o,screenTime)
        keepgoing = 0;
        if (o.state < 3)
            keepgoing = 1;
        end
    end
   
    %******************** THIS IS THE BIG FUNCTION *************
    function drop = state_and_screen_update(o,currentTime,x,y) 
        
        drop = 0; % initialize reward state
        
        %******* THIS PART CHANGES WITH EACH PROTOCOL ****************
        EyeVel = hypot(x-o.lastEyePos(1),y-o.lastEyePos(2));
%         if EyeVel == 0 % not valid
%             EyeVel = nan;
%         end
           
    
        TimeSinceLastState = currentTime - o.states(2,end);
        
        disp([TimeSinceLastState EyeVel o.state])
        o.lastEyePos = [x y]; % store this eye position
        
        % State 0: wait for fixation
        
        if (o.state == 0) && (TimeSinceLastState > o.P.refractoryDur) && (EyeVel < o.eyeVelThresh) % eye is still?
            
            if rand() < o.P.probShow % STATE TRANSITION
                o.state = 1; % show target
                o.states = [o.states [o.state; GetSecs]];
                
                % eye and stim are the same
                o.stimXY = [o.stimXY o.lastEyePos'];
                o.eyeXY = [o.eyeXY o.lastEyePos'];
                return
            end
        end

        % State 1: show stimulus
        if o.state == 1
            
            if (TimeSinceLastState > o.P.stimDur) % time to turn off?
                % turn it off transition back to state 
                o.state = 0;
                o.states = [o.states [o.state; GetSecs]];
                o.stimXY = [o.stimXY nan(2,1)];
                o.eyeXY = [o.eyeXY o.lastEyePos'];
                return % update over (nothing happens here)
                
            elseif (EyeVel > o.eyeVelThresh) % saccade initiated ?
                % transition to post-saccade grace period, stimulus and eye
                % position are not connected
                o.state = 2;
                o.states = [o.states [o.state; GetSecs]];
                o.stimXY = [o.stimXY o.stimXY(:,end)]; % stimXY is the same
                o.eyeXY = [o.eyeXY o.lastEyePos']; % eye position has changed
                drop = true;
                return
            else
                % draw stimulus at eye position
                o.hTarg.position = o.S.centerPix + [1 -1].*o.lastEyePos*o.S.pixPerDeg;
                o.hTarg.beforeFrame();
            end
                
        end
        
        if o.state == 2
            
           if TimeSinceLastState > o.P.postSacGraceDur
               o.state = 0;
               o.states = [o.states [o.state; GetSecs]];
               o.stimXY = [o.stimXY nan(2,1)]; % stim turns off
               o.eyeXY = [o.eyeXY o.lastEyePos']; % eye position updates
               return
           else
               % don't update eye position in state 2
               o.hTarg.beforeFrame();
           end
               
        end
        
        if (currentTime - o.startTime) > o.P.trialDuration
            o.state = 3; % end trial
            o.states = [o.states [o.state; GetSecs]];
            o.stimXY = [o.stimXY nan(2,1)]; % stim is off
            o.eyeXY = [o.eyeXY o.lastEyePos']; % eye position updates
            return
        end
    
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
        
        state2 = find(o.states(1,:)==2);
        if ~isempty(state2)
            
            stimXYplot = o.stimXY(:,state2);
            eyeXY0 = o.eyeXY(:,state2-1);
            eyeXYvel = o.eyeXY(:,state2) - eyeXY0;
            plot(h, stimXYplot(1,:), stimXYplot(2,:), 'ok'); hold on
            quiver(h, eyeXY0(1,:), eyeXY0(2,:), eyeXYvel(1,:), eyeXYvel(2,:), 0)
            % Stimulus window
            
        end
        
       %*********************
        axis(h,[-eyeRad eyeRad -eyeRad eyeRad]);
    end
    
    function PR = end_plots(o,P,A)   %update D struct if passing back info
        
        %************* STORE DATA to PR
        %**** NOTE, no need to copy anything from P itself, that is saved
        %**** already on each trial in data .... copy parts that are not
        %**** reflected in P at all and generated random per trial
        warning('off'); % suppress warning about converting to struct
        PR = struct(o); % convert the entire protocol to a struct
        warning('on'); % turn warnings back on
     
        %%%% Record some data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%% It is advised not to store things too large here, like eye movements, 
        %%%% that would be very inefficient as the experiment progresses
        
        %********** UPDATE ERROR, if Line Cue correct is standard
        if (o.error == 0)  % reward was given, but is it line cue correct?
            o.D.error(A.j) = 0; %o.error;
        else
            o.D.error(A.j) = o.error;
        end
        
       % Data plots go here
      
    end
    
  end % methods
    
end % classdef
