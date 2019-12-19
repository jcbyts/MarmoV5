classdef PR_BackImage < handle
  % Matlab class for running an experimental protocl
  %
  % The class constructor can be called with a range of arguments:
  %
  properties (Access = public)
       Iti double = 1;        % default Iti duration
       startTime double = 0;  % trial start time
       imageOff double = 0;   % offset of image
  end
      
  properties (Access = private)
    winPtr; % ptb window
    state double = 0;      % state countern trial
    error double = 0;      % default, need defined even if always 0
   %************
    S;      % copy of Settings struct (loaded per trial start)
    P;      % copy of Params struct (loaded per trial)
    ImoScreen = [];    % image to display, full screen
    ImoRect = [];
    ScreenRect = [];
    ImageDirectory = [];  % directory from which to pull images
    ImageFile = [];
    imo = [];  % matlab image struct
    grayscale = false
  end
  
  methods (Access = public)
    function o = PR_BackImage(winPtr)
      o.winPtr = winPtr;     
    end
    
    function state = get_state(o)
        state = o.state;
    end
    
    function initFunc(o,S,P)
        o.ImoScreen = [];
        o.ImageDirectory = S.ImageDirectory;
        if isfield(P, 'useGrayScale')
            o.grayscale = P.useGrayScale;
        end
    end
   
    function load_image_dir(o,imagedir)
        o.ImageDirectory = imagedir;
    end
    
    function closeFunc(o)
        if (~isempty(o.ImoScreen))
            Screen('Close',o.ImoScreen);
            o.ImoScreen = [];
        end
        if (~isempty(o.imo))
            clear o.imo;
            o.imo = [];
        end     
    end
   
    function generate_trialsList(o,S,P) %#ok<*INUSD>
           % nothing for this protocol
    end
    
    function P = next_trial(o,S,P)
          %********************
          o.S = S;
          o.P = P;       
          %*******************
          flist = dir([o.ImageDirectory,filesep,'*.*']);
          fext = cellfun(@(x) x(strfind(x, '.'):end), {flist.name}, 'uni', 0);
          isimg = cellfun(@(x) any(strcmp(x, {'.bmp', '.png', '.jpg', '.JPG', '.PNG'})), fext);
          flist = flist(isimg);
          
          o.closeFunc();  % clear any remaining images in memory
                          % before you allocated more (one per time)
          
          %******************
          if (~isempty(flist))
             fimo = 1 + floor( (rand * 0.99) * size(flist,1) );
             fname = flist(fimo).name;  % name of an image
             o.ImageFile = [o.ImageDirectory,filesep,fname];
             o.imo = imread(o.ImageFile);
             
             % image can't be bigger than screen. Don't waste texture size?
             o.imo = imresize(o.imo, S.screenRect([4 3]));
             
             if o.grayscale
                 o.imo = uint8(mean(o.imo,3));
             end
             %******* insert image in middle texture
             o.ImoScreen = Screen('MakeTexture',o.winPtr,o.imo);
             o.ImoRect = [0 0 size(o.imo,2) size(o.imo,1)];
             o.ScreenRect = S.screenRect;
          end
          
          aspectRatio = size(o.imo,1)./size(o.imo,2);
          
          % check if there are size and position variables
          if isfield(P, 'imageSizes') && isfield(P, 'imageCtrX') && isfield(P, 'imageCtrY')
              imWidthDeg = randsample(P.imageSizes, 1);
              imWidthPx = S.pixPerDeg * imWidthDeg;
              imHeightPx = aspectRatio * imWidthPx;
              
              ctr = S.centerPix + [P.imageCtrX P.imageCtrY]*S.pixPerDeg;
              o.ScreenRect = CenterRectOnPoint([0 0 imWidthPx imHeightPx], ctr(1), ctr(2));
          end
          
    end
    
    function [FP,TS] = prep_run_trial(o)
        % Setup the state
        o.state = 0; % Showing the face
%         Iti = o.P.iti;   % set ITI interval from P struct stored in trial
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
        if o.state == 0 && currentTime > o.startTime + o.P.imageDur
            o.state = 1; % Inter trial interval
            o.imageOff = GetSecs;
            drop = 1; 
        end
        % GET THE DISPLAY READY FOR THE NEXT FLIP
        % STATE SPECIFIC DRAWS
        switch o.state
           case 0
            Screen('DrawTextures',o.winPtr,o.ImoScreen,o.ImoRect,o.ScreenRect)  
        end 
        %**************************************************************
    end
    
    function Iti = end_run_trial(o)
        Iti = o.Iti;  % returns generic Iti interval (not task dep)
    end
    
    function plot_trace(o,handles)
        %***** nothing to append, just plot the basic trace
        %***** but scale and show the images inside eyetrace panel
        eyeRad = handles.eyeTraceRadius;
        %***********
        dx = size(o.imo,2)/(o.ScreenRect(3)-o.ScreenRect(1));
        dy = size(o.imo,1)/(o.ScreenRect(4)-o.ScreenRect(2));
        %******* desired screen pixels to replicate
        dp = o.S.pixPerDeg * eyeRad;
        smax = floor(min((o.ScreenRect(4) - o.ScreenRect(2)),...
                         (o.ScreenRect(3) - o.ScreenRect(1)))/2);
        if (dp >= smax)
            eR = eyeRad * ((smax-1) / dp);   
            dp = (smax-1);
        else
            eR = eyeRad;
        end        
        %******* covert to actual image pixels (not identical to screen)
        cp = [floor(size(o.imo,2)/2), floor(size(o.imo,1)/2)];
        idx = floor( dp * dx );
        idy = floor( dp * dy );
        ix = ceil(cp(1)-idx):floor(cp(1)+idx);
        iy = ceil(cp(2)-idy):floor(cp(2)+idy);
        %****** rescale for imagesc command
        cix = (ix - cp(1)) * (eR/idx);
        ciy = (iy - cp(2)) * (eR/idy);
        %*********** draw the scaled image, then overlay eye position
        subplot(handles.EyeTrace); hold off;
%         H = imagesc(cix,ciy,flipud(o.imo(iy,ix,:)));
        imagesc(cix,ciy,flipud(o.imo(iy,ix,:))); % don't output handle
        if (size(o.imo,3)==1)
            colormap('gray');
        end
        HH = gcf;
        z = get(HH,'CurrentAxes');
        set(z,'YDir','normal');       
    end
    
    function PR = end_plots(o,P,A)   %update D struct if passing back info     
        % Note, not passing in any complex information here
        PR = struct;
        PR.error = o.error;
        PR.startTime = o.startTime;
        PR.imageOff = o.imageOff;
        PR.imagefile = o.ImageFile;   % file name, if you want to load later
        PR.destRect = o.ScreenRect;
    end
    
  end % methods
    
end % classdef
