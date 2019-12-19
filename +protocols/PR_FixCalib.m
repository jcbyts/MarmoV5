classdef PR_FixCalib < handle
    % Matlab class for running an experimental protocl
    %
    % The class constructor can be called with a range of arguments:
    %
    
    properties (Access = public)
        Iti double = 1        % default Iti duration
        startTime double = 0  % trial start time
        faceOff double = 0    % trial face offset time
        fixOn double = 0      % is fixation point on
        fixStart double = 0   % time of fixation start
        fixItem double = 0   % item being fixated
    end
    
    properties (Access = private)
        winPtr  % ptb window
        state double = 0      % state counter
        error double = 0      % error state in trial
        %************
        S      % copy of Settings struct (loaded per trial start)
        P      % copy of Params struct (loaded per trial)
        %********* stimulus structs for use
        Faces      % object that stores face images for use
        hFix              % object for a fixation point
        texList  % face textures
        texRects % size of texture in pixels
        winRects % locations to draw textures
        faceConfig  % centers of draw textures, third is on or off
        fixList  % list of fixation moments, onset, offset, locations
    end
    
    methods (Access = public)
        function o = PR_FixCalib(winPtr)
            o.winPtr = winPtr;
        end
        
        function state = get_state(o)
            state = o.state;
        end
        
        function initFunc(o,S,P)
            o.Faces = stimuli.gaussimages(o.winPtr,'bkgd',S.bgColour,'gray',false);   % color images
            o.Faces.loadimages('./SupportData/MarmosetFaceLibrary.mat');
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
            o.fixList = [];
            o.fixOn = 0;
            o.fixStart = 0;
            %*******************
            
            %***** select a set of fixPts random locations
            o.winRects = zeros(4,o.P.fixPts);
            o.faceConfig = zeros(o.P.fixPts,4); % x and y locs of stims, on or off
            fr = round(o.P.faceRadius*o.S.pixPerDeg);
            cp = o.S.centerPix;
            %******
            rset = randi( (o.P.fixGrid^2), 1, o.P.fixPts);
            for i = 1:o.P.fixPts
                rr = rset(i);
                xx = (mod((rr-1),o.P.fixGrid)-floor(o.P.fixGrid/2)) * o.P.fixStep;
                yy = (floor((rr-1)/o.P.fixGrid)-floor(o.P.fixGrid/2)) * o.P.fixStep;
                o.faceConfig(i,1) = xx;
                o.faceConfig(i,2) = yy;
                %*********
                cX = round(cp(1)+xx*S.pixPerDeg);
                cY = round(cp(2)-yy*S.pixPerDeg); % INVERT FOR SCREEN DRAWS
                o.winRects(:,i) = [cX-fr cY-fr cX+fr cY+fr];
                %**********
            end
            o.faceConfig(:,3) = 1;   % all faces on to start trial
            
            %***** pick random faces from library
            fset = randi( size(o.faceConfig,1), 1, o.P.fixPts)';
            o.texList = o.Faces.tex(fset);
            o.texRects = zeros(4,o.P.fixPts);
            for i = 1:o.P.fixPts
                o.texRects(3:4,i) = zeros(2,1) + o.Faces.texDim(fset(i));
                o.faceConfig(i,4) = fset(i);  % store image number
            end
        end
        
        function [FP,TS] = prep_run_trial(o)
            % Setup the state
            o.state = 0; % Showing the face
            Iti = o.P.iti;   % set ITI interval from P struct stored in trial
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
            
            %***** if eye on a face then turn off
            F_on = find( o.faceConfig(:,3) == 1);
            for i = 1:size(F_on,1)
                ii = F_on(i);
                %**********
                if (norm([(x-o.faceConfig(ii,1)),(y-o.faceConfig(ii,2))]) < o.P.fixRadius )
                    o.faceConfig(ii,3) = 2;  % turn off face
                    %****** set fixation point to this location
                    o.hFix.position = [o.faceConfig(ii,1),-o.faceConfig(ii,2)]*o.S.pixPerDeg + o.S.centerPix;
                    o.fixItem = ii;
                    o.fixOn = 1;
                    o.fixStart = currentTime;
                    o.fixList = [o.fixList ; [currentTime,1,o.faceConfig(ii,1),o.faceConfig(ii,2)]];
                    %********************************
                end
            end
            %****** which faces are on still
            F_on = find( o.faceConfig(:,3) == 1);
            
            %****** implement state logic for fixation point
            if (o.fixOn == 1)
                if (norm([(x-o.faceConfig(o.fixItem,1)),(y-o.faceConfig(o.fixItem,2))]) < o.P.fixRadius)
                    if (currentTime > (o.fixStart + o.P.fixHold) )
                        drop = 1;  % give juice, fixation was held
                        o.fixOn = 0;  % turn off fixation, but not back on face
                        o.fixList = [o.fixList ; [currentTime,2,o.faceConfig(o.fixItem,1),o.faceConfig(o.fixItem,2)]];
                    end
                else   % fixation was broken
                    o.fixOn = 0;
                    o.faceConfig(o.fixItem,3) = 1;  % show face, not concluded
                    o.fixList = [o.fixList ; [currentTime,3,o.faceConfig(o.fixItem,1),o.faceConfig(o.fixItem,2)]];
                end
            end
            
            % GET THE DISPLAY READY FOR THE NEXT FLIP
            % STATE SPECIFIC DRAWS
            switch o.state
                case 0
                    if ~isempty(F_on)
                        Screen('DrawTextures',o.winPtr,o.texList(F_on),o.texRects(:,F_on),o.winRects(:,F_on));
                    end
                    if (o.fixOn == 1)
                        o.hFix.beforeFrame(1);
                    end
            end
            %**************************************************************
        end
        
        function Iti = end_run_trial(o)
            Iti = o.Iti;  % returns generic Iti interval (not task dep)
        end
        
        function plot_trace(o,handles)
            %********* append other things eye trace plots if you desire
            h = handles.EyeTrace;
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
            PR.fixList = o.fixList;
        end
        
    end % methods
    
end % classdef
