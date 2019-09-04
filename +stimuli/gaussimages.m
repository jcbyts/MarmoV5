classdef gaussimages < handle
  % Matlab class for drawing an image (typically a face) in a Gauss window
  %
  % The class constructor can be called with file name that is a .mat of images
  %  and what is the background gray scale (for Gauss windowing of image)
  %
  %   bkgd  - background gray
  %   gray  - true if gray only, else full color
  %
  % 26-08-2018 - Jude Mitchell
  
  properties (Access = public),
    tex;
    texDim;  
    imagenum@double = 0;   %if set zeros, picks at random which to show
    position@double = [0.0, 0.0]; % [x,y] (pixels)
    radius@double = 1;  % size in pixels, must be set
    bkgd@double = 127;
    gray@logical = true;
    transparency@double = 0.5;
  end
        
  properties (Access = private)
    winPtr; % ptb window
  end
  
  methods (Access = public)
    function o = gaussimages(winPtr,varargin) % marmoview's initCmd?
      o.winPtr = winPtr;
      o.tex = [];
      o.texDim = [];
      
      if nargin == 1,
        return
      end

      % initialise input parser
      args = varargin;
      p = inputParser;
      p.StructExpand = true;
      
      p.addParameter('position',o.position,@isfloat); % [x,y] (pixels)
      p.addParameter('radius',o.radius,@isfloat); % [x,y] (pixels)
      p.addParameter('gray',o.gray,@islogical);
      p.addParameter('bkgd',o.bkgd,@isfloat);
      p.addParameter('imagenum',o.imagenum,@isfloat);
      p.addParameter('transparency',o.transparency,@isfloat);
                  
      try
        p.parse(args{:});
      catch
        warning('Failed to parse name-value arguments.');
        return;
      end
      
      args = p.Results;
    
      o.position = args.position;
      o.radius = args.radius;
      o.gray = args.gray;
      o.bkgd = args.bkgd;
      o.transparency = args.bkgd;
     
    end
    
    function o = loadimages(o,filename)
        
       F = load(filename);
       images = fields(F);
       n = length(images);
       o.tex = nan(n,1);
       o.texDim = nan(n,1);
       for i = 1:n
          imo = F.(images{i});
          o.texDim(i) = length(imo);  
          [x,y] = meshgrid((1:o.texDim(i))-o.texDim(i)/2);
          g = exp(-(x.^2+y.^2)/(2*(o.texDim(i)/6)^2));
          g = repmat(g,[1 1 3]);
          im = uint8((g.*double(imo)) + o.bkgd*(1-g));  % Should be 127 if gamma, 186 if not
          if (o.gray)
             im = uint8(squeeze(mean(im,3)));  % go to grayscale 
          end
          % o.tex(i) = Screen('MakeTexture',o.winPtr,im);
          
          % then define transparency for g-blending
          if (o.transparency > 0)
             t1 = 255 * (squeeze(mean(g,3)) > 0.05); 
          else
             t1 = 255 * squeeze(mean(g,3)); 
          end
          rim = uint8( zeros(size(im,1),size(im,2),4) );
          rim(:,:,1) = im(:,:,1);
          rim(:,:,2) = im(:,:,2);
          rim(:,:,3) = im(:,:,3);
          %**** set transparency
          rim(:,:,4) = uint8(t1);
          % Create the gauss texture 
          o.tex(i) = Screen('MakeTexture',o.winPtr,rim);
          
          %**** initialize default radius based on last loaded image size
          o.radius = length(imo);
       end        
    end
    
    function CloseUp(o)
       if ~isempty(o.tex)
          for i = 1:size(o.tex,1) 
            Screen('Close',o.tex(i)); 
          end
          o.tex = [];
       end
    end
        
    function beforeTrial(o)
    end
    
    function beforeFrame(o)
      if (o.imagenum)
          o.drawGaussImage(o.imagenum);
      else
          rd = randi(length(o.tex));  
          o.drawGaussImage(rd);
      end
    end
        
    function afterFrame(o)
    end
    
    function drawGaussImage(o,imagenum)
       if ( (imagenum>0) && (imagenum <= size(o.tex,1)) ) 
         if (~isempty(o.tex(imagenum)))
           rect = kron([1,1],o.position) + kron(o.radius,[-1, -1, +1, +1]);
           texrect = [0 0 o.texDim(imagenum) o.texDim(imagenum)];
           Screen('DrawTexture',o.winPtr,o.tex(imagenum),texrect,rect,0);
         end
       end
    end
    
  end % methods
  
end % classdef
