classdef PR_FaceCal < handle
  % Matlab class for running an experimental protocl
  %
  % The class constructor can be called with a range of arguments:
  %
  
  properties (Access = public)   
       Iti double = 1;        % default Iti duration
       startTime double = 0;  % trial start time
       faceOff double = 0;    % trial face offset time
  end
      
  properties (Access = private)
    winPtr; % ptb window
    state double = 0;      % state counter
    error double = 0;      % error state in trial
    %************
    S;      % copy of Settings struct (loaded per trial start)
    P;      % copy of Params struct (loaded per trial)
    %********* stimulus structs for use
    Faces;      % object that stores face images for use
    faceConfig; % configuration of images shown per trial number
    texList;  % face textures
    texRects; % size of texture in pixels
    winRects; % locations to draw textures
  end
  
  methods (Access = public)
    function o = PR_FaceCal(winPtr)
      o.winPtr = winPtr;     
    end
    
    function state = get_state(o)
        state = o.state;
    end
    
    function initFunc(o,S,P)
        o.Faces = stimuli.gaussimages(o.winPtr,'bkgd',S.bgColour,'gray',false);   % color images
        o.Faces.loadimages('./SupportData/MarmosetFaceLibrary.mat');
    end
   
    function closeFunc(o)
        o.Faces.CloseUp();
    end
   
    function generate_trialsList(o,S,P) %#ok<*INUSD>
           % nothing for this protocol
    end
    
    function P = next_trial(o,S,P)
          %********************
          o.S = S;
          o.P = P;       
          %*******************
          
          % UPDATE THE FACE CONFIGURATION
          P.faceConfig = P.faceConfig+1;
          if P.faceConfig > length(S.faceConfigs)
             P.faceConfig = 1;
          end

          % Grab the face configuration to use on this trial
          o.faceConfig = S.faceConfigs{P.faceConfig};
          % Get how many faces in this configuration
          N = size(o.faceConfig,1);
          % Get texture list
          F = o.faceConfig(:,3); % face indices
          o.texList = o.Faces.tex(F); % corresponding textures

          % Rectangles of the source textures
          o.texRects = zeros(4,N);
          for i = 1:N
              o.texRects(3:4,i) = zeros(2,1) + o.Faces.texDim(F(i));
          end

          % Rectangles of the window placement
          o.winRects = zeros(4,N);
          fr = round(P.faceRadius*S.pixPerDeg);
          cp = S.centerPix;
          X = o.faceConfig(:,1); % X coordinate in degrees
          Y = o.faceConfig(:,2); % Y coordinate in degrees
          for i = 1:N
             cX = round(cp(1)+X(i)*S.pixPerDeg);
             cY = round(cp(2)-Y(i)*S.pixPerDeg); % INVERT FOR SCREEN DRAWS
             o.winRects(:,i) = [cX-fr cY-fr cX+fr cY+fr];
          end
    end
    
    function [FP,TS] = prep_run_trial(o)
        % Setup the state
        o.state = 0; % Showing the face
        Iti = o.P.iti;   %#ok<*PROP> % set ITI interval from P struct stored in trial
        %*******
        FP(1).states = 0;  % any special plotting of states, 
        FP(1).col = 'b';   % FP(1).states = 1:2; FP(1).col = 'b';
                           % would show states 1,2 in blue for eye trace
        %******* set which states are TimeSensitive, if [] then none
        TS = [];  % no sensitive states in FaceCal
        %********
        o.startTime = GetSecs;
    end
    
    function keepgoing = continue_run_trial(o,screenTime)
        keepgoing = 0;
        if (o.state < 1)
            keepgoing = 1;
        end
    end
   
    %******************** THIS IS THE BIG FUNCTION *************
    function drop = state_and_screen_update(o,currentTime,x,y) 
        drop = 0;
        %******* THIS PART CHANGES WITH EACH PROTOCOL ****************
        if o.state == 0 && currentTime > o.startTime + o.P.faceDur
            o.state = 1; % Inter trial interval
            o.faceOff = GetSecs;
            drop = 1; % handles.reward.deliver();
        end
        % GET THE DISPLAY READY FOR THE NEXT FLIP
        % STATE SPECIFIC DRAWS
        switch o.state
           case 0
            Screen('DrawTextures',o.winPtr,o.texList,o.texRects,o.winRects)  
        end 
        %**************************************************************
    end
    
    function Iti = end_run_trial(o)
        Iti = o.Iti;  % returns generic Iti interval (not task dep)
    end
    
    function plot_trace(o,handles)
        %********* append other things eye trace plots if you desire
        h = handles.EyeTrace;
        faceConfig = o.S.faceConfigs{o.P.faceConfig};
        set(h,'NextPlot','Replace');
        for i = 1:size(o.faceConfig,1)
              xF = o.faceConfig(i,1);
              yF = o.faceConfig(i,2);
              rF = o.P.faceRadius;
              plot(h,[xF-rF xF+rF xF+rF xF-rF xF-rF],[yF-rF yF-rF yF+rF yF+rF yF-rF],'-k');
              if (i == 1)
                set(h,'NextPlot','Add');
              end
        end
        
    end
    
    function PR = end_plots(o,P,A)   %update D struct if passing back info     
        % Note, not passing in any complex information here
        PR = struct;
        PR.error = o.error;
        PR.faceconfig = o.faceConfig;
    end
    
  end % methods
    
end % classdef
