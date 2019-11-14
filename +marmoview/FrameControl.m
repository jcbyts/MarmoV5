% core task controller
% 8-30-2018 - Jude Mitchell

classdef FrameControl < handle
  %
  % To see the public properties of this class, type
  %
  %  properties(marmoview.TaskControl)
  %
  % To see a list of methods, type
  %
  %   methods(marmoview.TaskControl)
  %
  % The class constructor can be called with a range of arguments:
  %
  %  This is the workhorse class of any experiment:
  %       1) It store the parameter structs for each trial
  %       2) It controls the screen flips and Show Eye feature
  %       3) It regulates any access back to GUI during run function
  %       4) It send out timing signals for eye tracker and ephys
  %       5) It stores the eye position and screen flip times
  %       6) It plots the eye position traces per trial and screen flip dT
  %       7) It writes out to a data file all of its information
  %                accumulated over a block of trials
  
  properties (SetAccess = private, GetAccess = public)
     %********
     winPtr;     % pointer to Screen window
     %******** storage across a session 
     PInit;      % initialized Param struct
     %******* what states are time sensitive
     TimeSensitive; 
     %******** storage within a single trial
     FData;      % buffer to store within trial data
     FCount;     % counter to store flips during trial
     c;          % struct that holds eye calibration data, center
     dx;         %   eye calib x scale
     dy;         %   eye calib y scale
     dontclear   % Screen('Flip') argument. 0=clear the buffer (default) 1=don't clear
     dontsync    % Screen('Flip') argument. 0=synchronize with vertical retrace, 1-2=don't synchronize
     FMAX;       % Max screen flips in any trial
     FIELDS;     % Max number of fields to store in eye data
     eyeColor;   % for ShowEye of eye position tracker
     FP;         % know how to plot eye traces (supplied from Run)
  end % properties

  % dependent properties, calculated on the fly...
  properties (SetAccess = public, GetAccess = public)
     showEye@double = 0;
     eyeIntensity@double = 20;
     Bkgd@double = 127;       % need to know for screen flip
     eyeRadius@double = 2.0;  % of screen pointer
     centerPix = [0,0];
     pixPerDeg = 30; 
     frameRate = 60; 
  end

  methods
    function o = FrameControl()
      %******** For now, set other variables to defaults 
      %***** and "initialize" will detail them in Protocol will spec them
      o.winPtr = [];
      %*********
      o.PInit = struct;    % store parameter fields struct, never allow new fields
      %*************
      o.TimeSensitive = [];  %no states time sensitive by default
      %*************
      o.FMAX = 5000;  %capped at a Max of 5000 screen flips
      o.FIELDS = 9;
      o.FData = nan(o.FMAX,o.FIELDS);   %per trial data storage
      o.FCount = 0;
      o.c  = [0,0];
      o.dx = 1;
      o.dy = 1;
      o.dontclear = 0;
      o.dontsync = 0;
      %**************
      o.FP = [];
    end
  end % methods

  methods (Access = public)
  
     function o = initialize(o,winPtr,P,C,S,varargin)
           % winPtr is the window point of psych display
           % P is the parameter struct defined by settings
           % C is the eye calibration struct
           % varargin are other important parameters
           
        %*** initialize data storage and counters
        o.winPtr = winPtr;  % screen pointer
        %*********
        o.PInit = P;    % store parameter fields struct, never allow new fields
        %*************
        o.FData(:) = NaN; 
        o.FCount = 0;
        %***********
        o.c = C.c;
        o.dx = C.dx;
        o.dy = C.dy;
        %**************
        o.frameRate = S.frameRate;
        o.FMAX = ceil(20*o.frameRate); % max trial is 20 seconds, regardless of framerate
        o.centerPix = S.centerPix;
        o.pixPerDeg = S.pixPerDeg;
        
        if isfield(P, 'dontclear')
            o.dontclear = P.dontclear;
        else
            o.dontclear = 0;
        end
        
        if isfield(P, 'dontsync')
            o.dontsync = P.dontsync;
        else
            o.dontsync = 0;
        end
        %*************
        
        % initialise input parser
        p = inputParser;
        p.KeepUnmatched = true;
        p.StructExpand = true;

        p.addParameter('showEye',0,@isfloat);
        p.addParameter('eyeIntensity',20,@isfloat); % default 
        p.addParameter('Bkgd',127,@isfloat);
        p.addParameter('eyeRadius',2.0,@isfloat);
        
        p.parse(varargin{:});
        args = p.Results;
 
        o.showEye = args.showEye;
        o.eyeIntensity = args.eyeIntensity;
        o.Bkgd = args.Bkgd;
        o.eyeRadius = args.eyeRadius;
       
        %******* if parameters are in the Pinit, use them 
        o.update_args_from_Pstruct(o.PInit);
        
        % Color for gaze indicator color, % purple, replace later 
        o.eyeColor = uint8(repmat(o.Bkgd,[1 3])) + ...
                     uint8(o.eyeIntensity * [1,-1,1]);
     end  
    
     function update_args_from_Pstruct(o,P)
        %****** NOTE, these arguments could load from the Pinit as well
        if (isfield(P,'showEye'))
          o.showEye = P.('showEye');
        end
        if (isfield(P,'eyeIntensity'))
          o.eyeIntensity = P.('eyeIntensity');
          o.eyeColor = uint8(repmat(o.Bkgd,[1 3])) + ...
                     uint8(o.eyeIntensity * [1,-1,1]);
        end
        if (isfield(P,'Bkgd'))
          o.Bkgd = P.('Bkgd');
        end
        if (isfield(P,'eyeRadius'))
          o.eyeRadius = P.('eyeRadius');  
        end
        %*************************
     end
     
     function set_task(o,FP,TS)    % call to set private property of class
         o.FP = FP;
         o.TimeSensitive = TS;   % set time sensitive states
     end
    
     function eyeData = upload_eyeData(o)
           if o.FCount
             eyeData = o.FData(1:o.FCount,:);
           else
             eyeData = [];
           end
     end
    
     function [c,dx,dy] = upload_C(o)
          c = o.c;
          dx = o.dx;
          dy = o.dy;
     end
    
     %********* main routines below for the work during trials
     function CL = prep_run_trial(o,eyepos,pupil)
          %*************
          o.FData(:,:) = NaN;  % set all to NaN at start
          o.FCount = 5;   % flip counter, why at 5 though? 
          o.FData(1:o.FCount,1) = GetSecs;  % column 1 timelock on eye pos
          %*************
          
          % Setup first frame
          Screen('FillRect',o.winPtr,o.Bkgd);
          % when flipping, store time in eyeData
          [vbl, stimOnset, FlipTimestamp, Missed] = Screen('Flip',o.winPtr,0);
          %***** Get initial into *************
          o.FData(1:o.FCount,2) = eyepos(1);
          o.FData(1:o.FCount,3) = eyepos(2); 
          o.FData(1:o.FCount,4) = pupil; 
          o.FData(1:o.FCount,5) = 0;    %default, start state = 0
          o.FData(1:o.FCount,6) = vbl; 
          o.FData(1:o.FCount,7) = stimOnset;
          o.FData(1:o.FCount,8) = FlipTimestamp;
          o.FData(1:o.FCount,9) = Missed;
          %******* Store the Clock Sixlet ***********
          CL = fix(clock);
          CL(1) = CL(1) - 2000;
          %******************************************
     end
    
    function [currentTime,x,y] = grabeye_run_trial(o,state,eyepos,pupil)
          currentTime = GetSecs;
          % GET EYE POSITION
          o.FCount = o.FCount + 1;
          k = o.FCount;
          if (k <= o.FMAX)  %drops data if over max
             o.FData(k,1) = currentTime;
             o.FData(k,2) = eyepos(1);
             o.FData(k,3) = eyepos(2);  
             o.FData(k,4) = pupil; 
             o.FData(k,5) = state;
          else
             disp('Over MAX eye data within trial, expand buffer'); 
          end
          x = (eyepos(1)-o.c(1)) / (o.dx*o.pixPerDeg);
          y = (eyepos(2)-o.c(2)) / (o.dy*o.pixPerDeg);
    end
    
    function [updateGUI,vblTime] = screen_update_run_trial(o,state)  
       % OTHER DRAWS
       eyeI = o.FCount;
       if o.showEye
          % Convert eye position from last 5 samples to pixel space
          x = mean(o.FData(eyeI-4:eyeI,2)-o.c(1)) / o.dx;
          y = mean(o.FData(eyeI-4:eyeI,3)-o.c(2)) / o.dy;
          cX = o.centerPix(1)+round(x);
          cY = o.centerPix(2)-round(y);   % INVERT FOR SCREEN DRAWS!
          eR = round(o.eyeRadius*o.pixPerDeg);
          position = double([cX-eR cY-eR cX+eR cY+eR]);
          Screen('FrameOval',o.winPtr,o.eyeColor,position,2);
       end
      
       % FLIP SCREEN NOW
       [vblTime,stimOnset, FlipTimestamp, Missed] = Screen('Flip',o.winPtr,0,o.dontclear,o.dontsync);
%        o.FData(eyeI,5) = state; 
        o.FData(eyeI,6) = vblTime;
        o.FData(eyeI,7) = stimOnset;
        o.FData(eyeI,8) = FlipTimestamp;
        o.FData(eyeI,9) = Missed;
       % Reset the screen
%        Screen('FillRect',o.winPtr,o.Bkgd);
    
       %********* if not time sensitive state, allow GUI updating
       if (~ismember(state,o.TimeSensitive))
         updateGUI = true;
       else
         updateGUI = false;
       end
       %***********************************
    end
    
    function update_eye_calib(o,c,dx,dy)
          o.c = c;
          o.dx = dx;
          o.dy = dy;
    end
    
    function CL = last_screen_flip(o)
        % Reset the screen and leave blank for ITI
        o.FCount = o.FCount + 1;
        eyeI = o.FCount;
        Screen('FillRect',o.winPtr,o.Bkgd);
        FEnd = Screen('Flip',o.winPtr,GetSecs);
        o.FData(eyeI,6) = FEnd;
        %******* Store the Clock Sixlet ***********
        CL = fix(clock);
        CL(1) = CL(1) - 2000;
        %******************************************
    end

    function plot_eye_trace_and_flips(o,handles)
        % function plot_eye_trace_and_flips(handles)
        %
        % This function plots the eye trace from a trial in the EyeTracker
        % window of MarmoView.
        %
        % And it also plots the screen frame flips 
        
        h = handles.EyeTrace;
        dx = handles.A.dx;
        dy = handles.A.dy;
        c = handles.A.c;
        ppd = handles.S.pixPerDeg;
        eyeRad = handles.eyeTraceRadius;
        
        % set(h,'NextPlot','Replace');
        set(h,'NextPlot','Add');
        plot(h,0,0,'+k','LineWidth',2);
        plot(h,[-eyeRad eyeRad],[0 0],'--','Color',[.5 .5 .5]);
        plot(h,[0 0],[-eyeRad eyeRad],'--','Color',[.5 .5 .5]);
        %********* special labeling of states
        if o.FCount
          if (isempty(o.FP))  % default case, plot all traces
            ind = 1:o.FCount;  %any reasonable states
            x = (o.FData(ind,2)-c(1)) / (dx*ppd);
            y = (o.FData(ind,3)-c(2)) / (dy*ppd);
            plot(h,x,y,'b.');          
          else
            for k = 1:length(o.FP)
              ind = ismember(o.FData(:,5),o.FP(k).states);
              x = (o.FData(ind,2)-c(1)) / (dx*ppd);
              y = (o.FData(ind,3)-c(2)) / (dy*ppd);
              plot(h,x,y,[o.FP(k).col,'.']);
            end
          end
        end
        axis(h,[-eyeRad eyeRad -eyeRad eyeRad]);
        
        %********* Show the screen flip times ****************
        h = handles.DataPlot4;
        dT = (1/o.frameRate);
        set(h,'NextPlot','Replace');
        if (o.FCount > 1)
          tN = o.FCount - 1;  %drop last flip, worst one
          txx = 2:tN;
          flips = o.FData(txx,1) - o.FData((txx-1),1);
          mflips = max(flips);
          plot(h,[2,tN],[dT,dT],'k-');
          set(h,'NextPlot','Add');
          tstates = ismember( o.FData(txx,5), o.TimeSensitive );
          plot(h,txx(~tstates),flips(~tstates),'k.');
          plot(h,txx(tstates),flips(tstates),'r.');
          axis(h,[2 tN 0 (mflips*1.5)]);
          set(h,'NextPlot','Replace');
        end
        %*********************************
    end
    
  end  % (public methods)
    
end % classdef

