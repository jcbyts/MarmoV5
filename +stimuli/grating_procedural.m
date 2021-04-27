classdef grating_procedural < stimuli.stimulus
  % Matlab class for drawing a grating using the psych. toolbox.
  %
  % The class constructor can be called with a range of arguments:
  %
  %   position - center of target (x,y; pixels)
  %   radius - radius of target (r; pixels) (if Gabor, 2 sigma within it)
  %   orientation - orientation of grating (degs)
  %   phase - phase of grating (radians)
  %   square - 0 or 1, 1 if square wave grating
  %   bkgd - background grey of texture
  %   range - offset of max rgb value from bkgd
  
  % 14-08-2018 - Jude Mitchell
  % 07-11-2019 - Jake Yates wrote procedural version that *should* be
  %              backwards compatible
  
  properties (Access = public)
    position double = [0.0, 0.0]; % [x,y] (pixels)
    radius double = 50; % (pixels)
    orientation double = 0;  % horizontal
    cpd double = 2; % cycles per degree
    cpd2 double = NaN; % default not used, else composite stim
    phase double = 0;  % (radians)
    square logical = false;  
    bkgd double = 127;  
    range double = 127;
    gauss logical = true;  %gaussian aperture
    transparent double = 0.5;  % from 0 to 1, how transparent
    pixperdeg double = 0;  % set non-zero to use for CPD computation
    screenRect = [];   % if radius Inf, then fill whole area
    texRect
  end
        
  properties (Access = private)
    winPtr; % ptb window
    tex;
    
    goRect;  % default, define same scale as texture
  end
  
  methods (Access = public)
    function o = grating_procedural(winPtr,varargin) % marmoview's initCmd?
      o.winPtr = winPtr;
      o.tex = [];
      o.texRect = [];
      o.goRect = [];
      
      if nargin == 1
        return
      end

      % initialise input parser
      args = varargin;
      p = inputParser;
      p.StructExpand = true;
      
      p.addParameter('position',o.position,@isfloat); % [x,y] (pixels)
      p.addParameter('radius',o.radius,@isfloat);
      p.addParameter('orientation',o.orientation,@isfloat);
      p.addParameter('cpd',o.cpd,@isfloat);
      p.addParameter('cpd2',o.cpd2,@isfloat);
      p.addParameter('phase',o.phase,@isfloat);
      p.addParameter('square',o.square,@islogical);
      p.addParameter('gauss',o.gauss,@islogical);
      p.addParameter('bkgd',o.bkgd,@isfloat);
      p.addParameter('range',o.range,@isfloat);
      p.addParameter('pixperdeg',o.pixperdeg,@isdouble);
                  
      try
        p.parse(args{:});
      catch
        warning('Failed to parse name-value arguments.');
        return;
      end
      
      args = p.Results;
    
      o.position = args.position;
      o.radius = args.radius;
      o.orientation = args.orientation;
      o.cpd = args.cpd;
      o.cpd2 = args.cpd2;
      o.phase = args.phase;
      o.square = args.square;
      o.gauss = args.gauss;
      o.bkgd = args.bkgd;
      o.range = args.range;
      o.pixperdeg = args.pixperdeg;
 
    end
        
    function beforeTrial(o)
    end
    
    function beforeFrame(o)
      o.drawGrating();
    end
        
    function afterFrame(o)
    end
    
    function updateTextures(o)  
       %****** clear previous texture if updaing
%        o.CloseUp(); 

       %******** Make Gabor Texture for later use   
       if isinf(o.radius)
           if isempty(o.screenRect)
               disp('Must define screenRect to grating class for Inf radius');
               return;
           end
           res = max(o.screenRect);
       else
           res = o.radius*2;
       end
       
       disableNormalization = 1; % don't normalize the gabor by the gaussian sigma
       modulateColor = [0 0 0 0]; %  zeros means don't offset the background (depends on blend function)
       contrastPreMultiplicator = 0.5; % 0.5 scales max response to contrast is interpretable

       if o.winPtr ~= 0
           if o.square % TODO: this has not been tested
               o.tex = CreateProceduralSquareWaveGrating(o.winPtr,res, res, modulateColor, o.radius);
           elseif o.gauss % gabor
               o.tex = CreateProceduralGabor(o.winPtr, res, res, [], modulateColor, disableNormalization,contrastPreMultiplicator);
           else
               o.tex = CreateProceduralSineGrating(o.winPtr, res, res, modulateColor, o.radius, contrastPreMultiplicator);
           end
       end
       
       
       % Determine the texture placement
       if isinf(o.radius)
           o.texRect = [1 1 o.screenRect(3) o.screenRect(4)];
       else
           o.texRect = [0 0 res res];
           dPix2 = floor(res/2);
           o.goRect = o.texRect + kron(dPix2,[-1, -1, -1, -1]);
       end
    end
    
    function CloseUp(o)
       if ~isempty(o.tex)
           Screen('Close',o.tex);
           o.tex = [];
       end
    end
    
  end % methods
    
  methods (Access = public)        
    function drawGrating(o)
       if (~isempty(o.tex))
         if isinf(o.radius)
             rect = o.texRect;  % same size as screen itself
         else
             rect = CenterRectOnPointd([0 0 o.radius o.radius]*2, o.position(1), o.position(2));
         end
         
         if o.gauss
             rPix = floor(o.radius);
             dPix = 2*rPix+1;
             sigma = dPix / 8; % apply sigma
             
             freq = o.cpd/o.pixperdeg;
             % Procedural gabor textures blend using shaders, so we want
             % them to sum, instead of doing complicated alpha-blending
             % switch to GL_ONE, GL_ONE and store the old blend function
             [sourceFactorOld, destinationFactorOld] = Screen('BlendFunction', o.winPtr, GL_ONE, GL_ONE);
             Screen('DrawTexture', o.winPtr, o.tex, o.texRect, rect, 90+o.orientation, [], [], [], [], kPsychDontDoRotation, [-o.phase+90, freq, sigma, o.transparent, 1, 0, 0, 0]);
             % reset old blend function
             Screen('BlendFunction', o.winPtr, sourceFactorOld, destinationFactorOld);
             
         else 
             [sourceFactorOld, destinationFactorOld] = Screen('BlendFunction', o.winPtr, GL_ONE, GL_ONE);
             freq = o.cpd/o.pixperdeg;
             Screen('DrawTexture', o.winPtr, o.tex, [], rect, 90-o.orientation, [], [], [], [], [], [o.phase, freq, o.transparent, 0]);
             Screen('BlendFunction', o.winPtr, sourceFactorOld, destinationFactorOld);
         end
         
       end
    end
    
    function I = getImage(o, rect, binSize)
        
        if nargin < 3
            binSize = 1;
        end
        
        if nargin < 2
            if isinf(o.radius)
                rect = o.screenRect;
            else
                rect = o.position([1 2 1 2]) + [-1 -1 1 1].*o.radius/2;
            end
        end
        
        % use values from our openGL shaders
        twopi = 2.0 * 3.141592654;
        deg2rad = 3.141592654 / 180.0;
        
        % build axes
        xax = rect(1):binSize:(rect(3)-binSize);
        yax = rect(2):binSize:(rect(4)-binSize);
        
        [xx, yy] = meshgrid(xax,yax);
        
        % offset the texture center
        X = xx - o.position(1);
        Y = yy - o.position(2);
        
        if isinf(o.radius)
            el = ones(size(X));
        else
            % Create the gaussian (e1)
            % Find diameter
            rPix = floor(o.radius);
            dPix = 2*rPix+1;
            % Standard deviation of gaussian (e1)
            sigma = dPix/8;
            e1 = exp(-.5*(X.^2 + Y.^2)/sigma^2);
        end
        
        maxRadians = twopi * o.cpd / o.pixperdeg;
        
        % Create the sinusoid
        pha = (o.phase - 0) * deg2rad;
        ori = (90 - o.orientation)*deg2rad;
        
        gx = cos(ori) * (maxRadians*X) + sin(ori) * (maxRadians*Y) + pha;
        s1 = cos(gx);
        %*********
        % Filter for square wave
        if (o.square)
            s1( s1 > 0 ) = 1;
            s1( s1 < 0 ) = -1;
        end
        if ~isinf(o.radius)
            if (o.square)
                e1( e1 > 0.01) = 1;
                e1( e1 <= 0.01) = 0;
            end
            
            %***** Gauss window
            if (o.gauss)
                g1 = s1.*e1;
            else
                g1 = s1 .* (e1 > 0.01);
            end
        else
            
            g1 = s1;
        end
        
        % Convert the gabor (g1) to uint8
        g1 = (o.bkgd + g1 * o.range * o.transparent);
        
        I = g1;
        
        % %         I = modulatecolor * contrast * contrastPreMultiplicator * sin(x*2*pi*freq + phase) + Offset;
    end
    
  end % methods
  
end % classdef
