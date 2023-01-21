classdef PR_FlagMo9d < handle
  % Matlab class for running an experimental protocl
  %
  % The class constructor can be called with a range of arguments:
  %
 
  properties (Access = public), 
       Iti double = 1;            % default Iti duration
       startTime double = 0;      % trial start time
       fixStart double = 0;       % fix acquired time
       itiStart double = 0;       % start of ITI interval
       fixDur double = 0;         % fixation duration
       fixOffset double = 0;      % time of fix offset
       stimStart double = 0;      % stimulus onset 
       stimOnset double = 0;      % jitter timing of target onset
       stimTime double = 0;       % mark when stim did onset (state move)
       stimChange double = 0;     % stimulus change in sac flight
       stimOffset double = 0;     % mark frame time of stim offset
       responseStart double = 0;  % response period start time
       responseEnd double = 0;    % time entering response period
       dotflip double = 0;        % integer to know dots turn off
       DropStim double = 0;       % if 1, trial where dots disappear on saccade
       rewardCount double = 0;    % counter for reward drops
       RunFixBreakSound double = 0;       % variable to initiate fix break sound (only once)
       NeverBreakSoundTwice double = 0;   % other variable for fix break sound
       flashCounter double = 0;   % for flashing fix at start of trial
       showFix logical = true;    % for flashing fix point to start trial
       dotbandW = 0;              % store the bandW selected per trial
       trialCount = 0;            % count error 0 or 4 trials (block design swaps)
       SpatialConfig = 1;         % config 1 (use normal, 2 - flip up down)
       flipMotion = 0;            % first time in state 5 or 6 flip motion direction
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
    hReward;           % use Gauss blobs as reward cues 
    targnum;           % number of graphics targets (1 is the rewarded target)
    hProbe = [];       % object for Dot Motion stimuli
    target_item;       % 1 is when reward is in RF, otherwise other locs
    target_null;       % 0 if none, but otherwise the target number (no reward)
    last_item;         % record last chosen location, or NaN if none
    gotTarget;         % within same trial, target choosen
    chooseTarget;      % target identity chosen by saccade
    targ_x;            % target x locations
    targ_y;            % target y locations
    targ_motion;       % target directions (start of trial)
    fixbreak_sound;    % audio of fix break sound
    fixbreak_sound_fs; % sampling rate of sound
    %******* trial parameters and stored information
    targori;           % orientation of target per trial
    changori;          % orientation of change target per trial
    deltaOri;          % change in ori across saccade
    %****************
    D = struct;        % store PR data for end plot stats, will store dotmotion array
  end
  
  methods (Access = public)
    function o = PR_FlagMo9d(winPtr)
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
       o.last_item = NaN;
       o.SpatialConfig = 1;  % 1 or 2, start as 1 using defs in settings
       o.trialCount = 0;  % start from zero
       
       %******* init reward face for correct trials
       o.Faces = stimuli.gaussimages(o.winPtr,'bkgd',S.bgColour,'gray',false);   % color images
       o.Faces.loadimages('./SupportData/MarmosetFaceLibrary.mat');
       o.Faces.position = [0,0]*S.pixPerDeg + S.centerPix;
       o.Faces.radius = round(P.faceradius*S.pixPerDeg);
       o.Faces.imagenum = 1;  % start first face
       
       %******* use two different Gauss blobs as intermediate reward cues
       o.hReward = cell(1,2);
       for k = 1:3
           o.hReward{k} = stimuli.grating(o.winPtr);  % grating probe
           o.hReward{k}.radius = round(P.radius*S.pixPerDeg);
           o.hReward{k}.orientation = 0; % cpd will be zero => all one color
           o.hReward{k}.range = P.range;
           if (k == 1)
               o.hReward{k}.phase = 0;   % white
           end
           if (k == 2)
               o.hReward{k}.phase = 180; % black  
           end
           if (k == 3)
               o.hReward{k}.phase = 90; % gray interior  
           end
           o.hReward{k}.cpd = 0; % when cpd is zero, you get a Gauss
           o.hReward{k}.square = false; % true;  % if you want circle
           o.hReward{k}.ring = false;
           if (k == 3)
              o.hReward{k}.ring = true; 
           end
           o.hReward{k}.gauss = true;
           o.hReward{k}.bkgd = P.bkgd;
           o.hReward{k}.transparent = -0.5;
           o.hReward{k}.pixperdeg = S.pixPerDeg;
           o.hReward{k}.updateTextures();
       end
       
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
       o.hPoint.centerPix = S.centerPix;
       o.hPoint.pixPerDeg = S.pixPerDeg;
       o.hPoint.bkgd = P.bkgd;
       o.hPoint.FixN = P.FixN;
       o.hPoint.sigma1 = P.sigma1;
       o.hPoint.width1 = P.width1;
       o.hPoint.cue_contrast = P.cue_contrast;
       
       %***** create a Gabor target grating
       o.targnum = P.targnum;
       o.hProbe = cell(1,(2*o.targnum));
       for k = 1:(2*o.targnum)
           if (P.motionStimulus == 1)
               o.hProbe{k}=stimuli.dots(o.winPtr);
           else
               o.hProbe{k} = stimuli.grating(o.winPtr);  % grating probe
               o.hProbe{k}.transparent = -P.probecon;  % blend in proportion to gauss
               o.hProbe{k}.gauss = true;
               o.hProbe{k}.pixperdeg = S.pixPerDeg;
           end
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
        o.hPoint.CloseUp();
        for kk = 1:(o.targnum+1)
           o.hProbe{kk}.CloseUp();
        end
        for kk = 1:2
           o.hReward{kk}.CloseUp(); 
        end
    end
   
    function generate_trialsList(o,S,P)
            % Call a function outside class (easier for us to edit)
            o.trialsList = FlagMo7_TrialsList(S,P);
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
            %*******************
            o.flipMotion = 0;
            
            % Trials list control
            if P.runType == 1    
                     %******** Trial indexer handles trials list indexing intelligently
                     i = o.trialIndexer.getNextTrial(o.error);
                     %***************
                     if (o.SpatialConfig == 1)
                       P.xDeg = o.trialsList(i,1);
                       P.yDeg = o.trialsList(i,2);
                     else
                       P.xDeg = o.trialsList(i,1);
                       P.yDeg = -(o.trialsList(i,2));
                     end
                     P.ori = o.trialsList(i,3);
                     P.rewardNumber = o.trialsList(i,4);
                     P.fixation = o.trialsList(i,5);
                     P.postori = o.trialsList(i,6);
                     %******************
                     o.P = P;  % set to most current
            end
            o.deltaOri = 0;
            if ~isnan(P.postori)
                 o.deltaOri = (P.postori - P.ori);  % change in dir
                 if (o.deltaOri  ~= 0)
                     o.deltaOri = 0;   % void change trials
                     P.postori = NaN;  % turn it to blank
                 end
            end
            %******* randomly select dotbandW
            it = randi( P.dotBandwdthSteps );
            o.dotbandW = P.dotBandwdth + ((it-1) * P.dotBandwdthStepSize);
            
            %****** randomize if unlimited or limited dot life per trial
            % if (rand < 0.5)
                P.dotLife = Inf;
            % else
            %    P.dotLife = 5;
            % end
            o.P = P;
            %*******************
            
            %******** make sure the new target is not the last one
            bestdist = Inf;
            for zk = 1:o.targnum
                %***** rotate appropriate for target
                % controlled for RF target every trial (locs fixed relative
                % **  to the RF location, so probe1 is always RF location)
                if (o.SpatialConfig == 1)
                  xps = P.RF_X; % P.xDeg;
                  yps = P.RF_Y; % P.yDeg;
                else
                  xps = P.RF_X; % P.xDeg;
                  yps = -P.RF_Y; % P.yDeg;    
                end
                ango = 2*pi*(zk-1)/o.targnum;  % shift the position
                xp = (cos(ango) * xps) + (sin(ango) * yps);
                yp = (-sin(ango) * xps) + (cos(ango) * yps);
                %*************
                dist = norm([(xp-P.xDeg),(yp-P.yDeg)]);
                if (dist < bestdist)
                    o.target_item = zk;
                    bestdist = dist;
                end
            end            
            if (o.target_item == o.last_item)  % problem, cueing last choosen
               % ignore the trial list then, and pick another location
               % and pick such that last item is not selected, other equal
               % chance
               it = randi((o.targnum-1));
               if (it >= o.last_item)
                   it = it + 1;
               end
               %***** recover the location and reset the target
               if (o.SpatialConfig == 1)
                  xps = P.RF_X; % P.xDeg;
                  yps = P.RF_Y; % P.yDeg;
               else
                  xps = P.RF_X; % P.xDeg;
                  yps = -P.RF_Y; % P.yDeg;    
               end
               ango = 2*pi*(it-1)/o.targnum;  % shift the position
               o.P.xDeg = (cos(ango) * xps) + (sin(ango) * yps);
               o.P.yDeg = (-sin(ango) * xps) + (cos(ango) * yps);
               P.xDeg = o.P.xDeg;
               P.yDeg = o.P.yDeg;
               o.target_item = it;
            end
            %*************      
            
            %********************
            o.target_null = 0;  % alternate target is null by default
            if (rand < o.P.probNull)
                 igo = randi(o.targnum);
                 alto = NaN;
                 while (isnan(alto))
                     if (igo ~= o.target_item) && (igo ~= o.last_item)
                        alto = igo 
                     else
                        igo = igo + 1;
                        if (igo > o.targnum)
                            igo = 1;
                        end
                     end
                 end
                 o.target_null = alto;
            end
            %*********************
            
            %******* set state for DropStim
            o.DropStim = 0;  % keep target same
            if isnan(P.postori)
                o.DropStim = 2;
            else
                o.DropStim = 1;  % show other post-saccade ori
            end
          
            % Select a face from image set to show at center
            o.Faces.imagenum = randi(length(o.Faces.tex));  % pick any at random
            % Set location of face reward
            if (P.fixation == 0)
               o.Faces.position = [o.P.xDeg,-o.P.yDeg]*S.pixPerDeg + S.centerPix;
            else
               o.Faces.position = S.centerPix;  % fixation trial, reward at center
            end

            %******* set cue point for target location
            o.hPoint.sigma1 = P.sigma1;
            o.hPoint.UpdateTextures(o.P.xDeg,o.P.yDeg);
            
            % Make Gabor stimulus texture
            o.targori = P.ori;
            o.changori = P.postori;
            %*****
            o.targ_x = [];
            o.targ_y = [];
            o.targ_motion = [];
            %********
            for zk = 1:o.targnum
                %***** rotate appropriate for target
                % controlled for RF target every trial (locs fixed relative
                % **  to the RF location, so probe1 is always RF location)
                if (o.SpatialConfig == 1)
                  xps = P.RF_X; % P.xDeg;
                  yps = P.RF_Y; % P.yDeg;
                else
                  xps = P.RF_X; % P.xDeg;
                  yps = -P.RF_Y; % P.yDeg;    
                end
                ango = 2*pi*(zk-1)/o.targnum;  % shift the position
                xp = (cos(ango) * xps) + (sin(ango) * yps);
                yp = (-sin(ango) * xps) + (cos(ango) * yps);
                %***** if fixation, fix target 1 to fixation location
                if (o.P.fixation == 1) && (zk == 1)
                    xp = 0;
                    yp = 0;
                end
                %***********************************
                if (zk == 1)
                    ori = P.ori;
                else
                    ori = ((randi(o.P.orinum)-1) * 360 / o.P.orinum);  % random  
                end
                %****** store essential stimulus information
                o.targ_x = [o.targ_x ; xp];
                o.targ_y = [o.targ_y ; yp];
                o.targ_motion = [o.targ_motion ; ori];
            end
            for zk = 1:o.targnum
                %*********
                xp = o.targ_x(zk);
                yp = o.targ_y(zk);
                ori = o.targ_motion(zk);
                %***********
                if (o.P.motionStimulus)
                    o.hProbe{zk}.mode=1; % gaussian
                    o.hProbe{zk}.dist=1; % uniform
                    o.hProbe{zk}.numDots=P.dotNum; % number of dots in dot field 
                    o.hProbe{zk}.position = [(S.centerPix(1) + round(xp*S.pixPerDeg)),(S.centerPix(2) - round(yp*S.pixPerDeg))];
                    o.hProbe{zk}.direction = ori;  % into degrees/ direction of motion 
                    o.hProbe{zk}.bandwdth= o.dotbandW; % P.dotBandwdth; 
                    o.hProbe{zk}.lifetime=P.dotLife; %how long the dots last
                    o.hProbe{zk}.maxRadius = (P.radius * S.pixPerDeg);  % same pixel size as aperture (radius of the dot field)
                    o.hProbe{zk}.speed= (P.dotSpeed*S.pixPerDeg)/S.frameRate;   %(speed of dots)
                    o.hProbe{zk}.beforeTrial;
                    %******* gray out the stimulus if null target
                    if (zk == o.target_null)
                        o.hProbe{zk}.colour=repmat(P.bkgd,1,3);                         
                    else
                        if (P.targbrighter >= 1)
                           if (zk == 1)
                               o.hProbe{zk}.colour=repmat((P.bkgd - P.range),1,3);   
                           else
                               o.hProbe{zk}.colour=repmat((P.bkgd - floor(P.range/P.targbrighter)),1,3);
                           end
                        else
                           o.hProbe{zk}.colour=repmat((P.bkgd - P.range),1,3);
                        end
                    end
                    %*******
                    o.hProbe{zk}.size= round(P.dotSize*S.pixPerDeg);   % size of the dots
                    o.hProbe{zk}.theta=0;
                    o.hProbe{zk}.gaussian = true;   
                else
                    o.hProbe{zk}.position = [(S.centerPix(1) + round(xp*S.pixPerDeg)),(S.centerPix(2) - round(yp*S.pixPerDeg))];
                    o.hProbe{zk}.radius = round(P.radius*S.pixPerDeg);
                    o.hProbe{zk}.orientation = ori; % vertical for the right
                    o.hProbe{zk}.phase = P.phase;
                    o.hProbe{zk}.cpd = P.cpd;
                    o.hProbe{zk}.cpd2 = P.cpd2;
                    o.hProbe{zk}.range = P.range;
                    o.hProbe{zk}.square = logical(P.squareWave);
                    o.hProbe{zk}.bkgd = P.bkgd;
                    o.hProbe{zk}.transparent = -P.probecon;
                    %******* gray out the stimulus if null target
                    if (zk == o.target_null)
                        o.hProbe{zk}.range = 0;
                    end
                    %*******                
                    o.hProbe{zk}.updateTextures();
                end
            end
            %****** second probe of orthogonal orientation
            for zk = 1:o.targnum
                %*********
                xp = o.targ_x(zk);
                yp = o.targ_y(zk);
                if (o.P.motionStimulus)
                    o.hProbe{o.targnum+zk}.mode=1; % gaussian
                    o.hProbe{o.targnum+zk}.dist=1; % uniform
                    o.hProbe{o.targnum+zk}.numDots=P.dotNum; % number of dots in dot field 
                    o.hProbe{o.targnum+zk}.position = [(S.centerPix(1) + round(xp*S.pixPerDeg)),(S.centerPix(2) - round(yp*S.pixPerDeg))];
                    if isnan(P.postori)
                       o.hProbe{o.targnum+zk}.direction = 0; % not seen actually
                    else
                       o.hProbe{o.targnum+zk}.direction = o.hProbe{zk}.direction + o.deltaOri;  % into degrees/ direction of motion  
                    end
                    o.hProbe{o.targnum+zk}.bandwdth= o.dotbandW; %P.dotBandwdth; 
                    o.hProbe{o.targnum+zk}.lifetime=P.dotLife; %how long the dots last
                    o.hProbe{o.targnum+zk}.maxRadius = (P.radius * S.pixPerDeg);  % same pixel size as aperture (radius of the dot field)
                    o.hProbe{o.targnum+zk}.speed= (P.dotSpeed*S.pixPerDeg)/S.frameRate;   %(speed of dots)
                    o.hProbe{o.targnum+zk}.beforeTrial;
                    if isnan(P.postori)
                        o.hProbe{o.targnum+zk}.colour = repmat(P.bkgd,1,3);       
                    else
                       if (zk == o.target_null)
                             o.hProbe{o.targnum+zk}.colour=repmat(P.bkgd,1,3);                         
                       else
                             if (P.targbrighter >= 1)
                               if (zk == 1)
                                  o.hProbe{o.targnum+zk}.colour=repmat((P.bkgd - P.range),1,3);   
                               else
                                  o.hProbe{o.targnum+zk}.colour=repmat((P.bkgd - floor(P.range/P.targbrighter)),1,3);
                               end
                             else
                               o.hProbe{o.targnum+zk}.colour=repmat((P.bkgd - P.range),1,3);
                             end
                       end 
                       %******* gray out the stimulus if null target
%                        if (zk == o.target_null)
%                            o.hProbe{o.targnum+zk}.colour=repmat(P.bkgd,1,3);                         
%                        else
%                            o.hProbe{o.targnum+zk}.colour=repmat((P.bkgd - P.range),1,3); 
%                        end
                       %*******
                    end
                    o.hProbe{o.targnum+zk}.size= round(P.dotSize*S.pixPerDeg);   % size of the dots
                    o.hProbe{o.targnum+zk}.theta=0;
                    o.hProbe{o.targnum+zk}.gaussian = true;      
                else
                    o.hProbe{o.targnum+zk}.position = [(S.centerPix(1) + round(P.xDeg*S.pixPerDeg)),(S.centerPix(2) - round(P.yDeg*S.pixPerDeg))];
                    o.hProbe{o.targnum+zk}.radius = round(P.radius*S.pixPerDeg);
                    o.hProbe{o.targnum+zk}.phase = P.phase;
                    o.hProbe{o.targnum+zk}.cpd = P.cpd;
                    o.hProbe{o.targnum+zk}.cpd2 = P.cpd2;
                    o.hProbe{o.targnum+zk}.range = P.range;
                    o.hProbe{o.targnum+zk}.square = logical(P.squareWave);
                    o.hProbe{o.targnum+zk}.bkgd = P.bkgd;
                    o.hProbe{o.targnum+zk}.transparent = -P.probecon;
                    o.hProbe{o.targnum+zk}.orientation = o.hProbe{zk}.orientation + o.deltaOri; % vertical for the right
                    if isnan(P.postori)
                        o.hProbe{o.targnum+zk}.orientation = 0;
                        o.hProbe{o.targnum+zk}.phase = 0; % white Gabor blob
                        o.hProbe{o.targnum+zk}.cpd = 0;
                        o.hProbe{o.targnum+zk}.cpd2 = NaN;
                        o.hProbe{o.targnum+zk}.range = 0; % lowest con, hardly visible? 
                    end
                     %******* gray out the stimulus if null target
                    if (zk == o.target_null)
                        o.hProbe{o.targnum+zk}.range = 0;
                    end
                    %*******     
                    o.hProbe{o.targnum+zk}.updateTextures();
                end
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
            o.flashCounter = 0;
            o.gotTarget = 0;
            o.chooseTarget = 0;
            
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
    
    function keepgoing = continue_run_trial(o,screenTime)
        keepgoing = 0;
        if (o.state < 9)
            keepgoing = 1;
        end
    end
   
    %******************** THIS IS THE BIG FUNCTION *************
    function drop = state_and_screen_update(o,currentTime,x,y) 
        drop = 0;
        %******* THIS PART CHANGES WITH EACH PROTOCOL ****************

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
                o.responseEnd = o.stimTime;
                % o.state = 7;
                % o.itiStart = o.stimTime;
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
            %******* determine if a stimulus is select by saccade
            if (o.chooseTarget == 0)
                bestdist = Inf;
                for zk = 1:o.targnum
                    dist = norm([x-o.targ_x(zk),y-o.targ_y(zk)]);
                    if (dist < o.P.choiceRadius)
                       if (dist < bestdist) 
                         o.chooseTarget = zk;
                         bestdist = dist;
                       end
                    end
                end
            end
            %******* no state transition till you choose a target 
            if (o.chooseTarget > 0)
                if (o.chooseTarget ~= o.last_item)
                    o.state = 6; % Move to hold stimulus
                    o.responseEnd = GetSecs;
                   % Otherwise the response failed to select the stimulus
                else
                    o.gotTarget = o.chooseTarget;  % mark where they went
                    o.state = 6; % Move to iti -- inter-trial interval
                    o.error = 4; % Error 4 is failure to select good stimulus.
                    o.responseEnd = GetSecs;
                end
            end
            %*************
        end
        if o.state == 5 && currentTime > o.responseStart + o.P.flightWait
           o.state = 7;
           o.error = 4;
           o.itiStart = GetSecs;   % failed to find any target, goofing off
        end

        %%%%% STATE 6 -- HOLD STIMULUS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % If the eye does not leave the stimulus, then reward
        if o.state == 6 && currentTime > o.responseEnd + o.P.holdDur
            o.state = 7; % Move to iti -- trial is over
            o.itiStart = GetSecs;
            if (o.chooseTarget == o.target_item)
                o.P.rewardNumber = o.P.rewardNumber * 2;  % double reward 
            else
               if (o.chooseTarget == o.target_null)
                  o.P.rewardNumber = 0;  % no rewards for null! 
               end
            end
            o.gotTarget = o.chooseTarget;    
        end
        % If the eye leaves before hold duration, no reward
        if o.state == 6 && (o.chooseTarget > 0)
            %**** check if eye still held in same target
            zk = o.chooseTarget;
            dist = norm([x-o.targ_x(zk),y-o.targ_y(zk)]);
            if (dist > o.P.choiceRadius)
                %********** if not held, then give an error for hold
                o.state = 7; % Move to iti -- inter-trial interval
                o.error = 5; % Error 5 is failure to hold the stimulus
                o.itiStart = GetSecs;
            end
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
                if currentTime > ( o.responseEnd + o.P.dotdelay + 0.1 )
                   o.state = 8;
                end
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
                
                % Hold fixation some period
                o.hFix.beforeFrame(1);  % very brief, in case were at
                                        % fixation as trial started
                
            case 2

                % continue to hold fixation   
                if (o.P.fixation == 0) && (o.P.cue_contrast)
                   if (o.P.showCue == 1)
                      o.hPoint.beforeFrame(1);  % cue direction briefly
                   end
                end
                o.hFix.beforeFrame(1);  % very brief, in case were at
                
            case 3    % show gaze cue

                % continue to hold fixation   
                o.hFix.beforeFrame(1);  % very brief, in case were at
                
            case 4    % waiting for him to leave fixation 
                % Disappear the fixation spot 

                
                % show grating target
                if (o.P.fixation == 0)
                    if (currentTime < o.stimTime + o.P.stimDur)                
                        %****** also show other targets
                        for k = 1:o.targnum
                           o.hProbe{k}.beforeFrame();
                        end
                        %******
                    else
                       if (o.stimOffset == 0)
                           o.stimOffset = GetSecs; % will be off next frame flip
                       end
                    end
                else
                   % otherwise show target directly at fixation
                    if (currentTime < o.stimTime + o.P.stimDur)                
                        o.hProbe{1}.beforeFrame();  % location will be at fixation
                    end
                end
                

            case 5    % saccade in flight, dim fixation, just in case not done before
                
                %**********
                if (o.flipMotion == 0)
                    o.flipMotion = 1;
                    o.stimChange = GetSecs; % will be off next frame flip
                    for k = 1:o.targnum
                      o.hProbe{k}.dx = o.hProbe{o.targnum+k}.dx;
                      o.hProbe{k}.dy = o.hProbe{o.targnum+k}.dy;
                      o.hProbe{k}.direction = o.hProbe{o.targnum+k}.direction;
                      o.hProbe{k}.colour = o.hProbe{o.targnum+k}.colour;
                    end
                end
                
                if (o.P.fixation == 0)
                    %****** swap to new target immediately in flight
                    if (currentTime < o.stimTime + o.P.stimDur)
                       for k = 1:o.targnum
                           o.hProbe{k}.beforeFrame();
                       end
                    end
                else
                    % otherwise show target directly at fixation
                    if (currentTime < o.stimTime + o.P.stimDur)                
                        o.hProbe{1}.beforeFrame();  % location will be at fixation
                    end
                end
                
                %**********
                if (o.fixOffset == 0)
                    o.fixOffset = GetSecs;
                end
                %************
                
                
            case {6 7} % once saccade landed, reappear stimulus,  show correct option
                
                %**********
                if (o.flipMotion == 0)
                    o.flipMotion = 1;
                    o.stimChange = GetSecs; % will be off next frame flip
                    for k = 1:o.targnum
                      o.hProbe{k}.dx = o.hProbe{o.targnum+k}.dx;
                      o.hProbe{k}.dy = o.hProbe{o.targnum+k}.dy;
                      o.hProbe{k}.direction = o.hProbe{o.targnum+k}.direction;
                      o.hProbe{k}.colour = o.hProbe{o.targnum+k}.colour;
                    end
                end          
                
                % Face instead of grating if correct, as an extra reward
                %********* Modified by Shanna to give 300ms motion after
                if (o.error == 5)
                        % if error 5, give feedback immediately and change stimulus
                        % this would not be used as post-saccadic stim anyway
                        o.hReward{3}.position = o.hProbe{o.chooseTarget}.position;
                        o.hReward{3}.beforeFrame();
                else
                       if (currentTime > o.responseEnd + o.P.dotdelay)
                                   if ~o.error
                                      if (o.P.fixation == 1)
                                         o.Faces.position = o.hProbe{1}.position;
                                         o.Faces.beforeFrame(); 
                                      else
                                        if (o.chooseTarget == o.target_item)
                                          o.Faces.position = o.hProbe{o.chooseTarget}.position;
                                          o.Faces.beforeFrame();
                                        else
                                          o.hReward{1}.position = o.hProbe{o.chooseTarget}.position;
                                          o.hReward{1}.beforeFrame();  % White Gauss                               
                                        end
                                      end
                                   else
                                      %**** show black Gauss (wrong, repeat)
                                      if (o.chooseTarget)
                                         o.hReward{2}.position = o.hProbe{o.chooseTarget}.position;
                                         o.hReward{2}.beforeFrame();
                                      end
                                   end
                       else
                               if (o.P.fixation == 0)
                                   %******
                                   for k = 1:o.targnum
                                      o.hProbe{k}.beforeFrame();
                                   end
                                   %******
                               else
                                   o.hProbe{1}.beforeFrame();  % location will be at fixation
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
        %***********
         %***********
        if (o.P.motionStimulus == 1)
           if (o.state < 5)
              for k = 1:o.targnum
                 o.hProbe{k}.afterFrame;
              end
           else
              if (o.P.fixation == 1)
                  o.hProbe{1}.afterFrame;
              else
                  for k = 1:o.targnum
                       o.hProbe{k}.afterFrame;  
                  end                  
              end
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
        fixX = 0; 
        fixY = 0; 
        plot(h,fixX+r*cos(0:.01:1*2*pi),fixY+r*sin(0:.01:1*2*pi),'--k');
        set(h,'NextPlot','Add');
        % Stimulus window
        %******* plot target options
        for zk = 1:o.targnum
           r = o.P.radius; 
           if (zk == o.target_item)
               plot(h,o.targ_x(zk)+r*cos(0:.01:1*2*pi),o.targ_y(zk)+r*sin(0:.01:1*2*pi),'r-');
           else
               if (zk == o.last_item)
                  plot(h,o.targ_x(zk)+r*cos(0:.01:1*2*pi),o.targ_y(zk)+r*sin(0:.01:1*2*pi),'b-');       
               else
                  plot(h,o.targ_x(zk)+r*cos(0:.01:1*2*pi),o.targ_y(zk)+r*sin(0:.01:1*2*pi),'k-');
               end
           end
        end
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
        PR.DropStim = o.DropStim;
        PR.targori = o.targori;
        PR.target_item = o.target_item;
        PR.target_null = o.target_null;
        PR.last_item = o.last_item;
        PR.chooseTarget = o.chooseTarget;
        PR.gotTarget = o.gotTarget;
        if (o.gotTarget)
          o.last_item = o.gotTarget;  % store for next trial
        end
        PR.changori = o.changori;
        PR.deltaOri = o.deltaOri;
        PR.stimOffset = o.stimOffset;  % time of offset (next frame off)
        PR.targ_x = o.targ_x;
        PR.targ_y = o.targ_y;
        PR.targ_motion = o.targ_motion;
        PR.dotbandW = o.dotbandW;
        PR.SpatialConfig = o.SpatialConfig;
        PR.trialCount = o.trialCount;
        PR.stimChange = o.stimChange;
        %******* this is also where you could store Gabor Flash Info
        
        %%%% Record some data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%% It is advised not to store things too large here, like eye movements, 
        %%%% that would be very inefficient as the experiment progresses
        
        %********** UPDATE ERROR, if Line Cue correct is standard
        if (o.error == 0)  % reward was given, but is it line cue correct?
          if (o.chooseTarget == o.target_item)
            o.D.error(A.j) = 0; %o.error;
          else
            o.D.error(A.j) = 4; % wrong target
          end
          
          %***************************
        else
            o.D.error(A.j) = o.error;
        end
        
        if ( (o.error == 0) || (o.error == 4) )
          o.trialCount = o.trialCount + 1;  % add to corrects, ready for block swap
          %***** counter-balance space based on config
          if (o.trialCount >= o.P.trialSwap)
               o.trialCount = 0;  % reset it
               if (o.SpatialConfig == 1)
                    o.SpatialConfig = 2;
               else
                    o.SpatialConfig = 1; 
               end
          end
        end
        
        %********
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
