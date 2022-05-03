classdef gaussimages < stimuli.stimulus % inherit stimulus to have tracking / random number generator
  % Matlab class for drawing an image (typically a face) in a Gauss window
  %
  % The class constructor can be called with file name that is a .mat of images
  %  and what is the background gray scale (for Gauss windowing of image)
  %
  %   bkgd  - background gray
  %   gray  - true if gray only, else full color
  %
  % 26-08-2018 - Jude Mitchell
  
  properties (Access = public)
    tex
    texDim
    imagenum double = 0   %if set zeros, picks at random which to show
    position double = [0.0, 0.0] % [x,y] (pixels)
    radius double = 1  % size in pixels, must be set
    bkgd double = 127
    gray logical = true
    transparency double = 0.5
  end
        
  properties (Access = public)
    winPtr % ptb window
  end
  
  methods (Access = public)
    function o = gaussimages(winPtr,varargin) % marmoview's initCmd?
      o.winPtr = winPtr;
      o.tex = [];
      o.texDim = [];
      
      if nargin == 1
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
       if o.winPtr==0
           o.tex = cell(n,1);
       else
           o.tex = nan(n,1);
       end
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
          if o.winPtr ~= 0
            o.tex(i) = Screen('MakeTexture',o.winPtr,rim);
          else
            o.tex{i} = rim;
          end
          
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
        o.setRandomSeed(); % set the random seed
    end
    
    function beforeFrame(o)
      if (o.imagenum)
          o.drawGaussImage(o.imagenum);
      else
          rd = randi(o.rng, length(o.tex));  
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
        

        
        I = o.tex{o.imagenum};
        I = double(I);
        alpha = squeeze(I(:,:,4))./255;
        I(:,:,4) = [];
        for i = 1:3
            I(:,:,i) = I(:,:,i).*alpha + 127.*(1-alpha);
        end
        
        texrect = kron([1,1],o.position) + kron(o.radius,[-1, -1, +1, +1]);
        I = imresize(I, [texrect(4)-texrect(2) texrect(3)-texrect(1)]);
        alpha = imresize(alpha, [texrect(4)-texrect(2) texrect(3)-texrect(1)]);
        
        % -- try to be a little quicker
        Iscreen = o.bkgd * ones(1080,1920); % bad that screensize is hardcoded
        Iscreen(texrect(2):texrect(4)-1, texrect(1):texrect(3)-1) = mean(I(:,:,1:3),3);
        Ascreen = zeros(1080,1920);
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
