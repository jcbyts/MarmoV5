classdef PR_BillOri < handle
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
        stimStart double = 0;      % start of Gabor probe stimulus
        responseStart double = 0;  % start of choice period
        responseEnd double = 0;    % end of response period
        showFix logical = true;    % trial start with fixation
        flashCounter double = 0;   % counts frames, used for fade in point cue?
        rewardCount double = 0;    % counter for reward drops
        RunFixBreakSound double = 0;       % variable to initiate fix break sound (only once)
        NeverBreakSoundTwice double = 0;   % other variable for fix break sound
    end
    
    properties (Access = private)
        winPtr; % ptb window
        state double = 0;      % state counter
        error double = 0;      % error state in trial
        %*********
        S;      % copy of Settings struct (loaded per trial start)
        P;      % copy of Params struct (loaded per trial)
        trialsList;  % list of trial types to run in experiment
        trialIndexer = [];  % object to run trial order
        %********* stimulus structs for use
        stimTheta double = 0;  % direction of choice
        hFix;              % object for a fixation point
        hProbe = [];       % object for Gabor stimuli
        hChoice = [];      % object for Choice Gabor stimuli
        fixbreak_sound;    % audio of fix break sound
        fixbreak_sound_fs; % sampling rate of sound
        %****************
        D = struct;        % store PR data for end plot stats
    end
    
    methods (Access = public)
        function o = PR_BillOri(winPtr)
            o.winPtr = winPtr;
            o.trialsList = [];
        end
        
        function state = get_state(o)
            state = o.state;
        end
        
        function initFunc(o,S,P)
            
            %********** Set-up for trial indexing (required)
            cors = [0,4];  % count these errors as correct trials
            reps = [1,2];  % count these errors like aborts, repeat
            o.trialIndexer = marmoview.TrialIndexer(o.trialsList,P,cors,reps);
            o.error = 0;
            
            %********** Initialize Graphics Objects
            o.hFix = stimuli.fixation(o.winPtr);   % fixation stimulus
            o.hProbe = stimuli.grating(o.winPtr);  % grating probe
            o.hChoice{1} = stimuli.grating(o.winPtr); % choice grating, right (vertical)
            o.hChoice{2} = stimuli.grating(o.winPtr); % choice grating, left (horizontal)
            
            %********* if stimuli remain constant on all trials, set-them up here
            
            % set fixation point properties
            sz = P.fixPointRadius*S.pixPerDeg;
            o.hFix.cSize = sz;
            o.hFix.sSize = 2*sz;
            o.hFix.cColour = ones(1,3); % black
            o.hFix.sColour = repmat(255,1,3); % white
            o.hFix.position = [0,0]*S.pixPerDeg + S.centerPix;
            o.hFix.updateTextures();
            
            % set vertical choice grating
            o.hChoice{1}.position = [(S.centerPix(1) + round(P.choiceRad*S.pixPerDeg)), S.centerPix(2)];
            o.hChoice{1}.radius = round(P.radius*S.pixPerDeg);
            o.hChoice{1}.orientation = 90; % vertical for the right
            o.hChoice{1}.phase = 0;
            o.hChoice{1}.cpd = P.choiceCPD;
            o.hChoice{1}.range = 127;
            o.hChoice{1}.square = false;
            o.hChoice{1}.bkgd = P.bkgd;
            o.hChoice{1}.updateTextures();
            
            % set horizontal choice grating
            o.hChoice{2}.position = [(S.centerPix(1) + round(-P.choiceRad*S.pixPerDeg)), S.centerPix(2)];
            o.hChoice{2}.radius = round(P.radius*S.pixPerDeg);
            o.hChoice{2}.orientation = 0; % vertical for the right
            o.hChoice{2}.phase = 0;
            o.hChoice{2}.cpd = P.choiceCPD;
            o.hChoice{2}.range = 127;
            o.hChoice{2}.square = false;
            o.hChoice{2}.bkgd = P.bkgd;
            o.hChoice{2}.updateTextures();
            
            %********** load in a fixation error sound ************
            [y,fs] = audioread(['SupportData',filesep,'gunshot_sound.wav']);
            y = y(1:floor(size(y,1)/3),:);  % shorten it, very long sound
            o.fixbreak_sound = y;
            o.fixbreak_sound_fs = fs;
            %*********************
        end
        
        function closeFunc(o)
            o.hFix.CloseUp();
            o.hProbe.CloseUp();
            for k = 1:length(o.hChoice)
                o.hChoice{k}.CloseUp;
            end
        end
        
        function generate_trialsList(o,~,P)
            % nothing for this protocol
            
            % Spatial frequency sampling
            sf_sampling =  [4 6 8 10 12];
            
            % Generate trials list
            o.trialsList = [];
            for zk = 1:size(sf_sampling,2)
                for k = 1:P.apertures   % do both choice directions
                    if (k == 1)
                        xpos = P.choiceRad;   % right choice
                        ypos = 0;
                        stimori = 90;   % vertical grating on right
                    else
                        xpos = -P.choiceRad;
                        ypos = 0;
                        stimori = 0;   % horizontal grating on left
                    end
                    mjuice = 2 + floor(sf_sampling(zk)/2);  % give more juice for higher spatial freq
                    if (mjuice > P.rewardNumber)
                        mjuice = P.rewardNumber;
                    end
                    %*************
                    % storing list of trials, [Choice_xpos Choice_ypos  SpatFreq Phase Ori Juice_Amount]
                    o.trialsList = [o.trialsList ; [xpos ypos sf_sampling(zk) 0  stimori mjuice]];
                    o.trialsList = [o.trialsList ; [xpos ypos sf_sampling(zk) 90 stimori mjuice]];
                end
            end
        end
        
        function P = next_trial(o,S,P)
            %********************
            o.S = S;
            o.P = P;
            %*******************
            
            if P.runType == 1   % go through trials list
                i = o.trialIndexer.getNextTrial(o.error);
                %****** update trial parameters for next trial
                P.choiceX = o.trialsList(i,1);
                P.choiceY = o.trialsList(i,2);
                P.cpd = o.trialsList(i,3);
                P.phase = o.trialsList(i,4);
                P.orientation = o.trialsList(i,5);
                P.rewardNumber = o.trialsList(i,6);
                %******************
                o.P = P;  % set to most current
            end
            
            % Calculate this for pie slice windowing for choice
            o.stimTheta = atan2(P.choiceY,P.choiceX);
            
            % Make Gabor stimulus texture
            o.hProbe(1).position = [(S.centerPix(1) + round(P.xDeg*S.pixPerDeg)),(S.centerPix(2) - round(P.yDeg*S.pixPerDeg))];
            o.hProbe(1).radius = round(P.radius*S.pixPerDeg);
            o.hProbe(1).orientation = P.orientation; % vertical for the right
            o.hProbe(1).phase = P.phase;
            o.hProbe(1).cpd = P.cpd;
            o.hProbe(1).range = P.range;
            o.hProbe(1).square = logical(P.squareWave);
            o.hProbe(1).bkgd = P.bkgd;
            o.hProbe(1).updateTextures();
            %******************************************
        end
        
        function [FP,TS] = prep_run_trial(o)
            
            %********VARIABLES USED IN RUNNING TRIAL LOGISTICS
            o.fixDur = o.P.fixMin + ceil(1000*o.P.fixRan*rand)/1000;  % randomized fix duration
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
            % Setup the state
            o.state = 0; % Showing the face
            o.error = 0; % Start with error as 0
            o.Iti = o.P.iti;   % set ITI interval from P struct stored in trial
            %******* Plot States Struct (show fix in blue for eye trace)
            % any special plotting of states,
            % FP(1).states = 1:2; FP(1).col = 'b';
            % would show states 1,2 in blue for eye trace
            FP(1).states = 1:3;  %before fixation
            FP(1).col = 'b';
            FP(2).states = 4;  % fixation held
            FP(2).col = 'g';
            FP(3).states = 5;
            FP(3).col = 'r';
            %******* set which states are TimeSensitive, if [] then none
            TS = 1:5;  % all times during target presentation
            %********
            o.startTime = GetSecs;
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
                %***** reward here for holding of fixation
                if (isfield(o.P,'rewardFix'))
                    if (o.P.rewardFix)
                        drop = 1;
                    end
                end
                %************************
                o.stimStart = GetSecs;
            end
            % Eye must remain in the fixation window
            if o.state == 2 && norm([x y]) > o.P.fixWinRadius
                o.state = 8; % Move to iti -- inter-trial interval
                o.error = 2; % Error 2 is failure to hold fixation
                o.itiStart = GetSecs;
            end
            
            %%%%% STATE 3+4 -- SHOW STIMULUS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Eye leaving fixation indicates a saccade, move to state 4
            if ((o.state == 3) || (o.state == 4)) && norm([x y]) > o.P.fixWinRadius
                o.state = 5; % dim fixation if so, then move to saccade in flight
                o.responseStart = GetSecs;
            end
            
            %**** in this scenario, eye always leaves, only question if
            %**** it goes to the right location
            % Hold fixation through the stimulus presentation
            if o.state == 3 && currentTime > o.stimStart + o.P.stimHold
                o.state = 4; % remove stim and dim fixation to cue "Go"
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
            
            %%%%% STATE 7 -- INTER-TRIAL INTERVAL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Deliver rewards
            if o.state == 7
                if ~o.error && o.rewardCount < o.P.rewardNumber
                    if currentTime > o.itiStart + 0.2*o.rewardCount % deliver in 200 ms increments
                        o.rewardCount = o.rewardCount + 1;
                        drop = 1;
                    end
                else
                    o.state = 8;
                end
            end
            %******* fixation break feedback, but otherwise go to state 9
            if o.state == 8
                if currentTime > o.itiStart + 0.2   % enough time to flash fix break
                    o.state = 9;
                    if o.error
                        o.Iti = o.P.iti + o.P.blank_iti;
                    end
                end
            end
            
            % STATE SPECIFIC DRAWS
            switch o.state
                case 0
                    %******* flash fixation point to draw monkey to it
                    if o.showFix
                        o.hFix.beforeFrame(1);
                    end
                    o.flashCounter = mod(o.flashCounter+1,o.P.flashFrameLength);
                    if o.flashCounter == 0
                        o.showFix = ~o.showFix;
                    end
                    
                case 1
                    % Bright fixation spot, prior to stimulus onset
                    o.hFix.beforeFrame(1);
                    
                case 2
                    % Continue to show fixation for a hold period
                    o.hFix.beforeFrame(1);
                    
                case 3
                    % fixation remains on while Gabor stim is shown
                    %********* show stimulus
                    if ( currentTime < o.stimStart + o.P.stimDur )
                        o.hProbe.beforeFrame();
                    end
                    %************
                    o.hFix.beforeFrame(1);
                    
                case 4    % disappear fixation and show apertures to go
                    
                    %********* show stimulus if still appropriate
                    if ( currentTime < o.stimStart + o.P.stimDur )
                        o.hProbe.beforeFrame();
                    end
                    % Aperture choice stimuli shown
                    o.hChoice{1}.beforeFrame();
                    o.hChoice{2}.beforeFrame();
                    
                case 5    % saccade in flight, dim fixation, just in case not done before
                    
                    %********* show stimulus if still appropriate
                    if ( currentTime < o.stimStart + o.P.stimDur )
                        o.hProbe.beforeFrame();
                    end
                    % Aperture choice stimuli shown
                    o.hChoice{1}.beforeFrame();
                    o.hChoice{2}.beforeFrame();
                    
                    
                case {6 7} % once saccade landed, reappear stimulus,  show correct option
                    
                    % Only the correct aperture choice stimuli shown
                    
                    if (o.P.orientation == 0)
                        o.hChoice{2}.beforeFrame();
                    else
                        o.hChoice{1}.beforeFrame();
                    end
                    
                case 8
                    if (o.error == 2) % broke fixation
                        o.hFix.beforeFrame(2);
                        %once you have a sound object, put break fix here
                        o.RunFixBreakSound = 1;
                    end
                    % leave everything blank for a minimum ITI
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
            % This function plots the eye trace from a trial in the EyeTracker
            % window of MarmoView.
            
            h = handles.EyeTrace;
            % Fixation window
            set(h,'NextPlot','Replace');
            r = o.P.fixWinRadius;
            plot(h,r*cos(0:.01:1*2*pi),r*sin(0:.01:1*2*pi),'--k');
            set(h,'NextPlot','Add');
            
            % Stimulus window
            stimX = o.P.choiceX;
            stimY = o.P.choiceY;
            eyeRad = handles.eyeTraceRadius;
            minR = o.P.stimWinMinRad;
            maxR = o.P.stimWinMaxRad;
            errT = o.P.stimWinTheta;
            stimT = atan2(stimY,stimX);
            
            plot(h,[minR*cos(stimT+errT) maxR*cos(stimT+errT)],[minR*sin(stimT+errT) maxR*sin(stimT+errT)],'--k');
            plot(h,[minR*cos(stimT-errT) maxR*cos(stimT-errT)],[minR*sin(stimT-errT) maxR*sin(stimT-errT)],'--k');
            plot(h,minR*cos(stimT-errT:pi/100:stimT+errT),minR*sin(stimT-errT:pi/100:stimT+errT),'--k');
            plot(h,maxR*cos(stimT-errT:pi/100:stimT+errT),maxR*sin(stimT-errT:pi/100:stimT+errT),'--k');
            r = o.P.radius;
            plot(h,stimX+r*cos(0:.01:1*2*pi),stimY+r*sin(0:.01:1*2*pi),'-k');
            axis(h,[-eyeRad eyeRad -eyeRad eyeRad]);
        end
        
        function PR = end_plots(o,P,A)   %update D struct if passing back info
            
            %************* STORE DATA to PR
            PR = struct;
            PR.error = o.error;
            PR.fixDur = o.fixDur;
            PR.x = P.xDeg;
            PR.y = P.yDeg;
            PR.choiceX = P.choiceX;
            PR.choiceY = P.choiceY;
            PR.cpd = P.cpd;
            %******* this is also where you could store Gabor Flash Info
            
            %%%% Record some data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            o.D.error(A.j) = o.error;
            o.D.xDeg(A.j) = P.xDeg;
            o.D.yDeg(A.j) = P.yDeg;
            o.D.x(A.j) = P.choiceX;
            o.D.y(A.j) = P.choiceY;
            o.D.cpd(A.j) = P.cpd;
            
            %%%% Plot results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Dataplot 1, errors
            errors = [0 1 2 3 4 5;
                sum(o.D.error==0) sum(o.D.error==1) sum(o.D.error==2) sum(o.D.error==3) sum(o.D.error==4) sum(o.D.error==5)];
            bar(A.DataPlot1,errors(1,:),errors(2,:));
            title(A.DataPlot1,'Errors');
            ylabel(A.DataPlot1,'Count');
            set(A.DataPlot1,'XLim',[-.75 5.75]);
            
            % DataPlot2, fraction correct by spatial location (left or right trial)
            % Note that this plot will break down if multiple stimulus eccentricities
            % or a non horizontal hexagon are used. It will also only calculate
            % fraction correct for locations assigned by the trials list.
            locs = unique(o.trialsList(:,1:2),'rows');
            nlocs = size(locs,1);
            labels = cell(1,nlocs);
            fcXxy = zeros(1,nlocs);
            for i = 1:nlocs
                x = locs(i,1); y = locs(i,2);
                Ncorrect = sum(o.D.x == x & o.D.y == y & o.D.error == 0);
                Ntotal = sum(o.D.x == x & o.D.y == y & (o.D.error == 0 | o.D.error > 2.5));
                if  Ntotal > 0
                    fcXxy(i) = Ncorrect/Ntotal;
                end
                % Constructs labels based on the six locations
                if x > 0 && abs(y) < .01;       labels{i} = 'R';    end
                if x < 0 && abs(y) < .01;       labels{i} = 'L';    end
            end
            bar(A.DataPlot2,1:nlocs,fcXxy);
            title(A.DataPlot2,'By Location');
            ylabel(A.DataPlot2,'Fraction Correct');
            set(A.DataPlot2,'XTickLabel',labels);
            axis(A.DataPlot2,[.25 nlocs+.75 0 1]);
            
            % Dataplot3, fraction correct by cycles per degree
            % This plot only calculates the fraction correct for trials list cpds.
            cpds = unique(o.trialsList(:,3));
            ncpds = size(cpds,1);
            fcXcpd = zeros(1,ncpds);
            labels = cell(1,ncpds);
            for i = 1:ncpds
                cpd = cpds(i);
                Ncorrect = sum(o.D.cpd == cpd & o.D.error == 0);
                Ntotal = sum(o.D.cpd == cpd & (o.D.error == 0 | o.D.error > 2.5));
                if Ntotal > 0
                    fcXcpd(i) = Ncorrect/Ntotal;
                end
                labels{i} = num2str(round(10*cpd)/10);
            end
            bar(A.DataPlot3,1:ncpds,fcXcpd);
            title(A.DataPlot3,'By Cycles per Degree');
            ylabel(A.DataPlot3,'Fraction Corret');
            set(A.DataPlot3,'XTickLabel',labels);
            axis(A.DataPlot3,[.25 ncpds+.75 0 1]);
        end
        
    end % methods
    
end % classdef
