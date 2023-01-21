classdef grating < stimuli.stimulus
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
    transparent double = 0.5;  % from 0 to 1, how transparent
    pixperdeg double = 0;  % set non-zero to use for CPD computation
    screenRect = [];   % if radius Inf, then fill whole area
  end
        
  properties (Access = private)
    winPtr; % ptb window
    tex;
    texRect;
    goRect;  % default, define same scale as texture
  end
  
  methods (Access = public)
    function o = grating(winPtr,varargin) % marmoview's initCmd?
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
      
      p.addParameter('position',o.position, isfloat); % [x,y] (pixels)
      p.addParameter('radius',o.radius, isfloat);
      p.addParameter('orientation',o.orientation, isfloat);
      p.addParameter('cpd',o.cpd, isfloat);
      p.addParameter('cpd2',o.cpd2, isfloat);
      p.addParameter('phase',o.phase, isfloat);
      p.addParameter('square',o.square, islogical);
      p.addParameter('ring',o.square, islogical);
      p.addParameter('gauss',o.gauss, islogical);
      p.addParameter('bkgd',o.bkgd, isfloat);
      p.addParameter('range',o.range, isfloat);
      p.addParameter('pixperdeg',o.pixperdeg, isdouble);
                  
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
      o.ring = args.ring;
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
       o.CloseUp(); 
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
           maxRadians = 2 * pi * o.cpd /o.pixperdeg;
       else
           maxRadians = 2 * pi * o.cpd / 20;
       end   
       % Create the sinusoid (s1)
       pha = o.phase * pi/180;
       s1 = cos( cos(o.orientation*pi/180) * (maxRadians*Y) + ...
                 sin(o.orientation*pi/180) * (maxRadians*X) + pha);
       %********** composite grating with two CPD
       if ~isnan(o.cpd2)
           if (o.pixperdeg > 0)
               maxRadians2 = 2 * pi * o.cpd2 /o.pixperdeg;
           else
               maxRadians2 = 2 * pi * o.cpd2 / 20;
           end   
           s2 = cos( cos(o.orientation*pi/180) * (maxRadians2*Y) + ...
                     sin(o.orientation*pi/180) * (maxRadians2*X) + pha);
           s1 = s1 + s2;
       end   
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
          %Create the gabor (g1)
          if (o.transparent < 0)
             t1 = (255 * abs(o.transparent)) * e1; 
          else
             t1 = (o.transparent * 255) * (e1 > 0.01);
          end
          %***** Gauss window
          if (o.gauss)
             g1 = s1.*e1;
          else
             g1 = s1 .* (e1 > 0.01);
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
       if o.winPtr ~=0
           o.tex = Screen('MakeTexture',o.winPtr,rim);
       else
           o.tex = rim;
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
             if ~isempty(o.goRect)
                 rect = kron([1,1],o.position) + o.goRect;  % fast if identical size to texture?
             else
                 rect = kron([1,1],o.position) + kron(o.radius,[-1, -1, +1, +1]);
             end
         end
         Screen('DrawTexture',o.winPtr,o.tex,o.texRect,rect);
       end
    end
    
    function varargout = getImage(o, rect, binsize)
        
        if o.winPtr~=0
            warning('gaussimages: getImage: only works if you constructed the object with winPtr=0')
        end
        
        if nargin < 3
            binsize = 1;
        end
        
        if nargin < 2
            rect = o.position([1 2 1 2]) + [-1 -1 1 1].*o.radius/2;
        end
        
        
        I = double(o.tex);
        alpha = double(squeeze(I(:,:,4)))./127;
        I(:,:,4) = [];
        
        texrect = kron([1,1],o.position) + kron(o.radius,[-1, -1, +1, +1]);
        I = imresize(I, [texrect(4)-texrect(2) texrect(3)-texrect(1)]);
        alpha = imresize(alpha, [texrect(4)-texrect(2) texrect(3)-texrect(1)]);
        
        % -- try to be a little quicker
        if isempty(o.screenRect)
            o.screenRect = [0 0 1920 1080]; % default resolution
        end
        Iscreen = zeros(o.screenRect(4),o.screenRect(3));
        Iscreen(texrect(2):texrect(4)-1, texrect(1):texrect(3)-1) = (mean(I,3) - o.bkgd).*alpha;
        Ascreen = zeros(o.screenRect(4),o.screenRect(3));
        Ascreen(texrect(2):texrect(4)-1, texrect(1):texrect(3)-1) = alpha;
        
        tmprect = rect;
        tmprect(3) = rect(3)-rect(1)-1;
        tmprect(4) = rect(4)-rect(2)-1;
        
        im = imcrop(Iscreen, tmprect); % requires the imaging processing toolbox
        alpha = imcrop(Ascreen, tmprect);
        
        if binsize~=1
            im = im(1:binsize:end,1:binsize:end);
            alpha = alpha(1:binsize:end,1:binsize:end);
        end
        
        
        
        
        %         % -- works, but you have to draw
        %         texax = texrect(1):binsize:texrect(3);
        %         texay = texrect(2):binsize:texrect(4);
        %
        %
        %         figure(9999); clf
        %         if binsize ~=1
        %             I = imresize(I, 1./binsize);
        %         end
        %         imagesc(texax, texay, I)
        %         xlim([rect(1) rect(3)])
        %         ylim([rect(2) rect(4)])
        %
        %         frame = getframe(gca);
        %         im = frame.cdata;
        %         %
        
        if nargout > 0
            varargout{1} = im;
        end
        
        if nargout > 1
            varargout{2} = alpha;
        end
        
    end
  end % methods
  
end % classdef
