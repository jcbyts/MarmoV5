classdef (Abstract) dotsbase < handle
  % Abstract class for drawing a circular patch of moving dots.
  %
  % The class constructor can be called with a number of arguments:
  %
  %   size       - dot size (pixels)
  %   speed      - dot speed (pixels/frame),
  %   direction  - degrees
  %   numDots    - number of dots
  %   lifetime   - limit of dot lifetime (frames)
  %   minRadius  - minimum radius of aperture (pixels; not implemented yet)
  %   maxRadius  - maximum radius of aperture (pixels)
  %   position   - aperture position (x,y; pixels)
  %   colour     - dot colour (RGB)
  %   visible    - flag to toggle dot visibility (default: true)
    
  % 2017-06-04 - Shaun L. Cloherty <s.cloherty@ieee.org>
  
  properties (Access = public)
    size double; % pixels
    speed double; % pixels/s
    direction double; % deg.
    numDots double;
    lifetime double; % dot lifetime (frames)
%     minRadius double; % minimum radius (pixels)
    maxRadius double; % maximum radius (pixels)
    position double; % aperture position (x,y; pixels)
    colour double;
    visible logical = true; % are the dots visible
  end
    
  properties (GetAccess = public, SetAccess = protected)
    % cartessian coordinates (relative to center of aperture?)
    x; % x coords (pixels)
    y; % y coords (pixels)
    
    % cartesian displacements
    dx; % pixels per frame?
    dy; % pixels per frame?
    
    % frames remaining
    frameCnt;
  end
    
  properties (Access = private)
    winPtr; % ptb window
  end
  
  methods (Access = public)
    function o = dotsbase(winPtr,varargin)
      o.winPtr = winPtr;
      
      if nargin == 1
        return
      end

      % initialise input parser
      args = varargin;
      p = inputParser;
%       p.KeepUnmatched = true;
      p.StructExpand = true;
      p.addParameter('size',10.0,@double); % pixels?
      p.addParameter('speed',0.2,@double); % deg./s
      p.addParameter('direction',0.0,@(x) isscalar(x) && isreal(x)); % deg.
      p.addParameter('numDots',50,@(x) ceil(x));
      p.addParameter('lifetime',Inf,@double);
      
%       p.addParamValue('minRadius',0.0,@double); % deg.
      p.addParameter('maxRadius',10.0,@double); % deg.

      p.addParameter('position',[0.0,0.0],@(x) isvector(x) && isreal(x)); % [x,y] (pixels)
      
      p.addParameter('colour',[1,0,0],@double);
      p.addParameter('visible',true,@islogical)
      
      try
        p.parse(args{:});
      catch
        warning('Failed to parse name-value arguments.');
        return;
      end
      
      args = p.Results;
    
      o.size = args.size;
      o.speed = args.speed;
      o.direction = args.direction;
      
      o.numDots = args.numDots;
      
      o.lifetime = args.lifetime;

%       o.minRadius = args.minRadius;
      o.maxRadius = args.maxRadius;
      
      o.position = args.position;
      
      o.colour = args.colour;
      o.visible = args.visible;
    end
        
    function beforeTrial(o)
      o.initDots(1:o.numDots); % <-- provided by the derived class
      
      % initialise frame counts for limited lifetime dots
      if o.lifetime ~= Inf
        o.frameCnt = randi(o.lifetime,o.numDots,1); % 1:numDots
      else
        o.frameCnt = inf(o.numDots,1);
      end
    end
    
    function beforeFrame(o)
      o.drawDots();
    end
        
    function afterFrame(o)
      % decrement frame counters
      o.frameCnt = o.frameCnt - 1;
      
      o.moveDots(); % provided by the derived class? maybe not...
    end
    
    function moveDots(o)
      % calculate future position
      o.x = o.x + o.dx;
      o.y = o.y + o.dy;
      
      r = sqrt(o.x.^2 + o.y.^2);
      idx = find(r > o.maxRadius); % dots that have exited the aperture
               
      if ~isempty(idx)
        % (re-)place the dots on the other side of the aperture
        [th,~] = cart2pol(o.dx(idx),o.dy(idx));
        [xx, yy] = o.rotate(o.x(idx),o.y(idx),-1*th);
        chordLength = 2*sqrt(o.maxRadius^2 - yy.^2);
        xx = xx - chordLength;
        [o.x(idx), o.y(idx)] = o.rotate(xx,yy,th);
      end
      
      idx = find(o.frameCnt == 0); % dots that have exceeded their lifetime
      
      if ~isempty(idx)
%         fprintf(1,'%i dots expired\n',length(idx));
        % (re-)place dots randomly within the aperture
        o.initDots(idx);
      end
    end
    
    function drawDots(o)
      if ~o.visible
        return
      end
            
      % dotType:
      %
      %   0 - square dots (default)
      %   1 - round, anit-aliased dots (favour performance)
      %   2 - round, anti-aliased dots (favour quality)
      %   3 - round, anti-aliased dots (built-in shader)
      %   4 - square dots (built-in shader)
      dotType = 1;
      
      Screen('DrawDots',o.winPtr,[o.x(:), -1*o.y(:)]', o.size, o.colour, o.position, dotType);
    end
    
    % initialize position (x,y) and frame displacement (dx,dy) for each dot
    initDots(o,idx); % abstract method
  end % methods
  
  methods (Static)
    function [xx, yy] = rotate(x,y,th)
      % rotate (x,y) by angle th

      n = length(th);
      
      xx = zeros([n,1]);
      yy = zeros([n,1]);
      
      for ii = 1:n
        % calculate rotation matrix
        R = [cos(th(ii)) -sin(th(ii)); ...
             sin(th(ii))  cos(th(ii))];

        tmp = R * [x(ii), y(ii)]';
        xx(ii) = tmp(1,:);
        yy(ii) = tmp(2,:);
      end
    end
  end % methods
end % classdef
