classdef dgrating < handle
  % Matlab class for drawing a Gabor grating using the psych. toolbox.
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
  
  properties (Access = public),
    position double = [0.0, 0.0]; % [x,y] (pixels)
    radius double = 50; % (pixels)
    orientation double = 0;  % horizontal
    cpd double = 2; % cycles per degree
    cpd2 double = NaN; % default not used, else composite stim
    phase double = 0;  % (radians)
    square logical = false;  
    ring logical = false;
    bkgd double = 127;  
    range double = 127;
    gauss logical = true;  %gaussian aperture
    driftSpeed double = 15;  % speed of drifting grating
    framerate double = 120;  % monitor frame rate
    transparent double = 0.5;  % from 0 to 1, how transparent
    pixperdeg double = 0;  % set non-zero to use for CPD computation
    screenRect = [];   % if radius Inf, then fill whole area
    phaCounter double = 1;    % phase Counter
    phaN double = 16;          % number of phases
    pattern double = 0; 
  end
        
  properties (Access = private)
    winPtr; % ptb window
    tex;
    texRect;
    goRect;  % default, define same scale as texture
  end
  
  methods (Access = public)
    function o = dgrating(winPtr,varargin) % marmoview's initCmd?
      o.winPtr = winPtr;
      o.tex = [];
      o.texRect = [];
      o.goRect = [];
      
      if nargin == 1,
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
      p.addParameter('pattern',o.pattern,@isfloat);
      p.addParameter('ring',o.ring,@islogical);
      p.addParameter('gauss',o.gauss,@islogical);
      p.addParameter('bkgd',o.bkgd,@isfloat);
      p.addParameter('range',o.range,@isfloat);
      p.addParameter('driftSpeed',o.driftSpeed,@isfloat);
      p.addParameter('framerate',o.framerate,@isfloat);
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
      o.pattern = args.pattern;
      o.ring = args.ring;
      o.gauss = args.gauss;
      o.bkgd = args.bkgd;
      o.range = args.range;
      o.pixperdeg = args.pixperdeg;
      o.driftSpeed = args.driftSpeed;
      o.framerate = args.framerate;
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
       o.CloseUp(); 
       %**** recompute the number of phase steps
       o.phaN = 1 + floor(o.framerate/(o.driftSpeed * o.cpd));
       %******** Make Gabor Texture for later use   
       if isinf(o.radius)
           if isempty(o.screenRect)
               disp('Must define screenRect to grating class for Inf radius');
               return;
           end
           [X,Y] = meshgrid(1:o.screenRect(3),1:o.screenRect(4));
           e1 = ones(size(X));
       else
          % Find diameter
          rPix = floor(o.radius);
          dPix = 2*rPix+1;
          % Create a meshgrid
          [X,Y] = meshgrid(-rPix:rPix);
          % Standard deviation of gaussian (e1)
          sigma = dPix/8;
          % Create the gaussian (e1)
          e1 = exp(-.5*(X.^2 + Y.^2)/sigma^2);
          % Convert cycles to max radians (s1)
       end
       if (o.pixperdeg > 0)
           maxRadians = pi * o.cpd /o.pixperdeg;
       else
           maxRadians = pi * o.cpd / 20;
       end   
       % Create the sinusoid (s1)
       % but do it phaN times
       for pkk = 1:o.phaN
           phaval = (pkk-1)*2*pi/o.phaN;
           pha = (o.phase * pi/180) + phaval;  %shifted phase for pkk
           ango = o.orientation*pi/180;  % points in direction
           if (~o.pattern)
             va = -cos(ango);
             vb = sin(ango);
             s1 = sin( va * (maxRadians*X) + ...
                       vb * (maxRadians*Y) + pha);
           else
             va1 = -cos(ango+(pi/4));
             vb1 = sin(ango+(pi/4));
             va2 = -cos(ango-(pi/4));
             vb2 = sin(ango-(pi/4));
             s1 = sin( va1 * (maxRadians*X) + ...
                       vb1 * (maxRadians*Y) + pha);
             s1 = s1 + sin( va2 * (maxRadians*X) + ...
                            vb2 * (maxRadians*Y) + pha);
           end
           %********** composite grating with two CPD
           if ~isnan(o.cpd2)
               if (o.pixperdeg > 0)
                   maxRadians2 = pi * o.cpd2 /o.pixperdeg;
               else
                   maxRadians2 = pi * o.cpd2 / 20;
               end   
               s2 = cos( va * (maxRadians2*X) + ...
                         vb * (maxRadians2*Y) + pha);
               s1 = s1 + s2;
           end   
           %*********
           % Filter for square wave
           if (o.square)
              s1( s1 > 0 ) = 1;
              s1( s1 < 0 ) = -1;
           end
           if ~isinf(o.radius)
              % if (o.square)
              %  e1( e1 > 0.01) = 1;
              %  e1( e1 <= 0.01) = 0;
              % end
              %Create the gabor (g1)
              if (o.transparent < 0)
                 t1 = (255 * abs(o.transparent)) * e1; 
              else
                 t1 = (o.transparent * 255) * (e1 > 0.01);
              end
              %***** Gauss window
              if (o.gauss)
                 g1 = s1.*e1;   %s1 is the sine wave in X,Y,  e1 is the gauss
              else
                 g1 = s1 .* (e1 > 0.01);   %this uses 1 inside the aperture
              end
              %***** aperture bounding ring?
              if (o.ring)
                 z = find( (e1 >= 0.01) & (e1 <= 0.015) );
                 g1(z) = -0.5;
                 t1(z) = 255;
              end
           else
              if (o.transparent)
                  g1 = s1;
                  t1 = (o.transparent * 255) * ones(size(X));
              end
           end   
           % Convert the gabor (g1) to uint8
           g1 = uint8(o.bkgd + g1 *o.range);
           % then define transparency for g-blending
           rim = uint8( zeros(size(g1,1),size(g1,2),4) );
           rim(:,:,1) = g1;
           rim(:,:,2) = g1;
           rim(:,:,3) = g1;
           %**** set transparency
           rim(:,:,4) = uint8(t1);
           % Create the gabor texture 
           o.tex{pkk} = Screen('MakeTexture',o.winPtr,rim);
       end
       
       
       % Determine the texture placement
       if isinf(o.radius)
           o.texRect = [1 1 o.screenRect(3) o.screenRect(4)];
       else
           o.texRect = [0 0 dPix dPix];
           dPix2 = floor(dPix/2);
           o.goRect = o.texRect + kron(dPix2,[-1, -1, -1, -1]);
       end
    end
    
    function CloseUp(o),
       if ~isempty(o.tex)
           for pkk = 1:o.phaN
              Screen('Close',o.tex{pkk});
           end
           o.tex = [];
       end
    end
    
  end % methods
    
  methods (Access = public)        
    function drawGrating(o)
       if (~isempty(o.tex))
         %**** update phase of grating with each graphics call
         o.phaCounter = o.phaCounter + 1;
         if (o.phaCounter > o.phaN)
             o.phaCounter = 1;
         end
         %*************  
         if isinf(o.radius)
             rect = o.texRect;  % same size as screen itself
         else
             if ~isempty(o.goRect)
                 rect = kron([1,1],o.position) + o.goRect;  % fast if identical size to texture?
             else
                 rect = kron([1,1],o.position) + kron(o.radius,[-1, -1, +1, +1]);
             end
         end
         %****** we would replace o.tex with o.tex{o.phaCounter}  where
         %****** o.tex becomes a cell structer with o.phaN items in it
         % Screen('DrawTexture',o.winPtr,o.tex,o.texRect,rect);
         Screen('DrawTexture',o.winPtr,o.tex{o.phaCounter},o.texRect,rect);
       end
    end
    
  end % methods
  
end % classdef
