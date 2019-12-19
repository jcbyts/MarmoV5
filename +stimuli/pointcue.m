classdef pointcue < handle
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
  
  properties (Access = public)
      FixN double = 8;   % frames of cue extending out
      pixPerDeg double = 30;  % pixels per deg
      bkgd double = 127;   % background
      sigma1 double = 2;   %dva
      width1 double = 0.4; %dva
      cue_contrast double = 1; %0 to 1
      centerPix double = [0,0];
  end
        
  properties (Access = private)
    winPtr; % ptb window
    fixTexCue;
    fixRectCue;
    winRectCue;
  end
  
  methods (Access = public)
    function o = pointcue(winPtr,varargin) % marmoview's initCmd?
      o.winPtr = winPtr;
      o.fixTexCue = [];
      o.fixRectCue = [];
      o.winRectCue = [];
      
      if nargin == 1,
        return
      end

      % initialise input parser
      args = varargin;
      p = inputParser;
      p.StructExpand = true;
      
      p.addParameter('position',o.FixN,@isfloat);
      p.addParameter('position',o.pixPerDeg,@isfloat);
      p.addParameter('position',o.bkgd,@isfloat);
      p.addParameter('position',o.sigma1,@isfloat);
      p.addParameter('position',o.width1,@isfloat);
      p.addParameter('position',o.cue_contrast,@isfloat);
      p.addParameter('position',o.centerPix,@isfloat);
      
      try
        p.parse(args{:});
      catch
        warning('Failed to parse name-value arguments.');
        return;
      end
      
      args = p.Results;
    
      o.FixN = args.FixN;            
      o.pixPerDeg = args.pixPerDeg;  
      o.bkgd = args.bkgd; 
      o.sigma1 = args.sigma1; 
      o.width1 = args.width1; 
      o.cue_contrast = args.cue_contrast; 
      o.centerPix = args.centerPix;
      
    end
        
    function beforeTrial(o)
    end
    
    function beforeFrame(o,step)
      o.drawPointCue(step);
    end
        
    function afterFrame(o)
    end
    
    function CloseUp(o),
       %****** if not empty, clear old point
       if (~isempty(o.fixTexCue))
           for k = 1:length(o.fixTexCue)
               Screen('Close',o.fixTexCue(k));  % close screens
           end
           o.fixTexCue = [];
       end
    end
    
    function UpdateTextures(o,xx,yy)   
       % Create the fix spot texture
       
       %****** if not empty, clear old screens
       o.CloseUp();
       
       %****** build new set of screens
       for k = 1:o.FixN
           % solid line cue, but of varying contrast intensity
           val = ((k-1)/(o.FixN-1))^2;
           cuecolor = o.bkgd + floor( o.cue_contrast * ((255-o.bkgd) * val));
           %**********
           fixIm = MakeFixSpot_FOR_GazeDelayCue(o.pixPerDeg,o.bkgd,o.sigma1,...
                                                o.width1,cuecolor,xx,yy);
           fixTex = Screen('MakeTexture',o.winPtr,fixIm);
           %**********
           % Determine the loation to place the fixation spot
           cx = o.centerPix(1);
           cy = o.centerPix(2); % INVERT FOR SCREEN COMMANDS
           dpix = size(fixIm,1);
           rpix = (dpix-1)/2;
           %***********
           fixRect = [0 0 dpix dpix];
           winRect = [cx-rpix cy-rpix cx+rpix cy+rpix];
           %***********
           o.fixTexCue(k) = fixTex;
           o.fixRectCue{k} = fixRect;
           o.winRectCue{k} = winRect;
       end
    end
  end % methods
    
  methods (Access = public)        
    function drawPointCue(o,step)
       if (~isempty(o.fixTexCue(step)))
         Screen('DrawTexture',o.winPtr,o.fixTexCue(step),o.fixRectCue{step},o.winRectCue{step});
       end
    end
    
  end % methods
  
end % classdef


function fixIm = MakeFixSpot_FOR_GazeDelayCue(SpixPerDeg,Pbkgd,Psigma1,...
                                              Pwidth1,Pcuecolor,xx,yy)
       % Make a fixation point texture
       % Find radius of spot in pixels
       irado = sqrt(xx^2 + yy^2);
       outfixr2 = irado * SpixPerDeg;
       % Make a texture that will fit this radius
       texRad = round(outfixr2)+2;   % Texture is slightly larger than specified radius so
                                     % the point can be rapidly, smoothly, blended, into the
                                     % background color, this allows sub-pixel precision
                                     % when specifying fix point size, and a nicer, less
                                     % pixelated point                 
       % Get a meshgrid for the texture
       [x,y] = meshgrid(-texRad:texRad);
       r = sqrt(x.^2 + y.^2);
       mu1 = 1;  % it seems this might be inner fix radius (not used anymore)
       
       %************
       fixIm = zeros(size(r)) + Pbkgd;
       %***********
       Kx = size(fixIm,1);
       Ky = size(fixIm,2);
       cx = texRad + 1;  % center
       cy = texRad + 1;
       rado = sqrt( xx^2 + yy^2);
       nx = xx/rado;
       ny = yy/rado;
       %********** determine which aperture is the right one
       leno = Psigma1 * SpixPerDeg;  % line length
       wido = Pwidth1 * SpixPerDeg;  % width, 0.1 vis degrees
       %************
       for i = 1:Kx
         for j = 1:Ky
           dx = i-cx;
           dy = -(j-cy);   %invert the vertical axis
           dist = sqrt( dx^2 + dy^2 );
           if (dist < leno)
              dx = dx/dist;
              dy = dy/dist;
              dotprod = (dx * nx) + (dy * ny);
              if (dotprod > 0.50)
                 theta = acos(dotprod); 
                 d1 = cos(theta) * dist;
                 d2 = sin(theta) * dist;
                 if ( (d1 > mu1) & (d1 < leno) && (d2 < wido) )
                    fixIm(j,i, :) = floor( (Pcuecolor-Pbkgd)*((1-(d1/leno))^2) + Pbkgd); 
                 end
              end
           end
         end
       end

       % Ensure the image is in display ready format
       fixIm = uint8(fixIm);

       %********* Append transparency column
       %******************************
       faceT = 255 * (r < texRad);
       fixIm = uint8(cat(3,fixIm,faceT));   % return this to make texture
       %*************************
end
