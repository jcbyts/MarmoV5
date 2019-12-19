classdef circles < handle
  % Matlab class for drawing circles using the psych. toolbox.
  %
  % The class constructor can be called with a range of arguments:
  %
  %   size     - diameter (pixels)
  %   weight   - line weight (pixels)
  %   colour   - line colour (clut index or [r,g,b])
  %   position - center of aperture (x,y; pixels)
  
  % 14-06-2016 - Shaun L. Cloherty <s.cloherty@ieee.org>
  
  properties (Access = public),
    size double = 0; % pixels
    weight double = 2; % pixels
    colour double = ones([1,3]); % clut index or [r,g,b]
    position double = [0.0, 0.0]; % [x,y] (pixels)
  end
        
  properties (Access = private)
    winPtr; % ptb window
  end
  
  methods (Access = public)
    function o = circles(winPtr,varargin), % marmoview's initCmd?
      o.winPtr = winPtr;
      
      if nargin == 1,
        return
      end

      % initialise input parser
      args = varargin;
      p = inputParser;
%       p.KeepUnmatched = true;
      p.StructExpand = true;
      p.addParameter('size',o.size,@isfloat); % pixels
      p.addParameter('weight',o.weight,@isfloat); % pixels
      p.addParameter('colour',o.colour,@isfloat); % clut index or [r,g,b]
      p.addParameter('position',o.position,@isfloat); % [x,y] (pixels)
                  
      try
        p.parse(args{:});
      catch
        warning('Failed to parse name-value arguments.');
        return;
      end
      
      args = p.Results;
    
      o.size = args.size;
      o.weight = args.weight;
      o.colour = args.colour;
      o.position = args.position;
    end
        
    function beforeTrial(o) % marmoview's nextCmd?
    end
    
    function beforeFrame(o) % Run?
      o.drawCircles();
    end
        
    function afterFrame(o) % Run?
    end
    
    function updateTextures(o)  % no textures for this stimulus
    end
    
    function CloseUp(o)
    end
  end % methods
    
  methods (Access = public)        
    function drawCircles(o)
      r = floor(o.size./2); % radius in pixels
      
      rect = kron([1,1],o.position) + kron(r(:),[-1, -1, +1, +1]);
      if o.weight > 0
        Screen('FrameOval',o.winPtr,o.colour,rect',o.weight);
      else
        Screen('FillOval',o.winPtr,o.colour,rect');
      end
      
    end
  end % methods
  
end % classdef
