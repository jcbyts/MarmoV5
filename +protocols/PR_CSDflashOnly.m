classdef PR_CSDflashOnly < protocols.protocol
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
       NoiseHistory double
       MaxFrames double
       FrameCount double = 0
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
    function o = PR_CSDflashOnly(winPtr, varargin)
      
        % instantiate object with parent class so we inherit methods and
        % properties from the protocol class
        o = o@protocols.protocol(winPtr);
    
    end
    
    function initFunc(o,S,P)
        
        o.P = P;
        o.S = S;
        o.MaxFrames = o.P.trialDuration * o.S.frameRate;
        o.NoiseHistory = nan(o.MaxFrames, 2);
      % do nothing 
      
    end
   
    function closeFunc(o)
        % do nothing
        % hTarg is either Faces or hFix, so it doesn't need to close
    end
   
    
    function P = next_trial(o,S,P)
            %********************
            o.S = S;
            o.P = P;
            %*******************
            
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
            o.FrameCount = 1;
            o.state = 0;
            o.startTime = GetSecs;
            o.Iti = o.P.iti;  % default ITI, could be longer if error
            

    end
    
    function keepgoing = continue_run_trial(o,screenTime)
        keepgoing = 0;
        o.NoiseHistory(o.FrameCount, 1) = screenTime;
        if (o.FrameCount < o.MaxFrames)
            keepgoing = 1;
        end
    end
   
    %******************** THIS IS THE BIG FUNCTION *************
    function drop = state_and_screen_update(o,~,~,~) 
        o.state = 1;
        drop = 0; % initialize reward state
       
        kk = 0;
        step = mod(o.FrameCount,(o.P.noisedur + o.P.noiseoff));
        if (step >= o.P.noiseoff)
            kk = 1;
            Screen('FillRect', o.winPtr, 127 + o.P.noiserange);
        else
            Screen('FillRect', o.winPtr, 127);
        end
        
        %**********
        o.FrameCount = o.FrameCount + 1;
        % NOTE: store screen time in "continue_run_trial" after flip
        o.NoiseHistory(o.FrameCount,2) = kk;  % store orientation number
    
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
     
        if o.FrameCount == 0
            PR.NoiseHistory = [];
        else
            PR.NoiseHistory = o.NoiseHistory(1:o.FrameCount,:);
        end
        
        %%%% Record some data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%% It is advised not to store things too large here, like eye movements, 
        %%%% that would be very inefficient as the experiment progresses
        
%         %********** UPDATE ERROR, if Line Cue correct is standard
%         if (o.error == 0)  % reward was given, but is it line cue correct?
%             o.D.error(A.j) = 0; %o.error;
%         else
%             o.D.error(A.j) = o.error;
%         end
        
       % Data plots go here
      
    end
    
  end % methods
    
end % classdef
