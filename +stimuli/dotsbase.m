classdef (Abstract) dotsbase < stimuli.stimulus
    % class for drawing a patch of moving dots.
    %
    % The class constructor can be called with a number of arguments:
    %
    %   size       - dot size (pixels)
    %   speed      - dot speed (pixels/frame),
    %   direction  - degrees
    %   numDots    - number of dots
    %   lifetime   - limit of dot lifetime (frames)
    %   maxRadius  - maximum radius of aperture (pixels)
    %   position   - aperture position (x,y; pixels)
    %   color     - dot colour (RGB)
    %   visible    - flag to toggle dot visibility (default: true)
    
    % 2017-06-04 - Shaun L. Cloherty <s.cloherty@ieee.org>
    properties (Access = public)
        size double % pixels
        speed double % pixels/s
        direction double % deg.
        numDots double
        lifetime double % dot lifetime (frames)
        maxRadius double % maximum radius (pixels)
        position double % aperture position (x,y; pixels)
        color double
    end
    
    properties (GetAccess = public, SetAccess = {?stimuli.stimulus})
        % cartessian coordinates (relative to center of aperture?)
        x % x coords (pixels)
        y % y coords (pixels)
        
        % cartesian displacements
        dx % pixels per frame?
        dy % pixels per frame?
        
        % frames remaining for each dot
        frameCnt
        
        % dotType:
        %
        %   0 - square dots (default)
        %   1 - round, anit-aliased dots (favour performance)
        %   2 - round, anti-aliased dots (favour quality)
        %   3 - round, anti-aliased dots (built-in shader)
        %   4 - square dots (built-in shader)
        dotType = 1
    end
    
    properties (Access = public) %{?stimuli.stimulus}
        winPtr % ptb window
        winRect % ptbwindow size
        winCtr % center of window
    end
    
    methods (Access = public)
        function obj = dotsbase(winPtr,varargin)
            
            obj = obj@stimuli.stimulus();
            obj.winPtr = winPtr;
            if winPtr > 0
                obj.winRect = Screen('Rect', obj.winPtr);
                obj.winCtr = obj.winRect(3:4)/2;
            end
            
            
            % initialise input parser
            ip = inputParser;
            ip.KeepUnmatched = true;
            ip.StructExpand = true;
            ip.addParameter('size',10.0, double); % pixels?
            ip.addParameter('speed',0.2, double); % deg./s
            ip.addParameter('direction',0.0,@(x) isscalar(x) && isreal(x)); % deg.
            ip.addParameter('numDots',50,@(x) ceil(x));
            ip.addParameter('lifetime',Inf, double);
            ip.addParameter('maxRadius',10.0, double); % deg.
            
            ip.addParameter('position',[0.0,0.0],@(x) isvector(x) && isreal(x)); % [x,y] (pixels)
            
            ip.addParameter('color',[0,0,0], double);
            ip.addParameter('visible',true,@islogical)
            
            try
                ip.parse(varargin{:});
            catch
                warning('Failed to parse name-value arguments.');
                return;
            end
            
            args = ip.Results;
            
            
            obj.size = args.size;
            obj.speed = args.speed;
            obj.direction = args.direction;
            
            obj.numDots = args.numDots;
            
            obj.lifetime = args.lifetime;
            
            obj.maxRadius = args.maxRadius;
            
            obj.position = args.position;
            
            obj.color = args.color;
            obj.stimValue = args.visible;
        end
        
        function beforeTrial(obj, seed)
            
            if nargin > 1
                obj.setRandomSeed(seed);
            else
                % important, set the random seed
                obj.setRandomSeed();
            end
            
            obj.initDots(1:obj.numDots); % <-- provided by the derived class
            
            % initialise frame counts for limited lifetime dots
            if obj.lifetime ~= Inf
                obj.frameCnt = randi(obj.rng, obj.lifetime,obj.numDots,1); % 1:numDots
            else
                obj.frameCnt = inf(obj.numDots,1);
            end
        end
        
        function beforeFrame(obj)
            obj.drawDots();
        end
        
        function afterFrame(obj)
            % increment frame counters
            obj.frameCnt = obj.frameCnt - 1;
            
            obj.moveDots(); % provided by the derived class? maybe not...
        end
        
        function moveDots(obj)
            % calculate future position
            obj.x = obj.x + obj.dx;
            obj.y = obj.y + obj.dy;
            
            if isinf(obj.maxRadius) % full-screen window
                win = obj.winRect(3:4)/2;
                obj.x(obj.x > win(1)) = -win(1);
                obj.x(obj.x < -win(1)) = win(1);
                obj.y(obj.y > win(2)) = -win(2);
                obj.y(obj.y < -win(2)) = win(2);
                
            else
                r = hypot(obj.x, obj.y);
                idx = find(r > obj.maxRadius); % dots that have exited the aperture
                
                if ~isempty(idx)
                    % (re-)place the dots on the other side of the aperture
                    [th,~] = cart2pol(obj.dx(idx),obj.dy(idx));
                    [xx, yy] = obj.rotate(obj.x(idx),obj.y(idx),-1*th);
                    chordLength = 2*sqrt(obj.maxRadius^2 - yy.^2);
                    xx = xx - chordLength;
                    [obj.x(idx), obj.y(idx)] = obj.rotate(xx,yy,th);
                end
                
            end
            idx = find(obj.frameCnt == 0); % dots that have exceeded their lifetime
            
            if ~isempty(idx)
                % (re-)place dots randomly within the aperture
                obj.initDots(idx);
            end
        end
        
        function updateTextures(~, varargin)
            % dummy for similarity to other modules 
        end
        
        function drawDots(obj)
            if ~obj.stimValue
                return
            end
            
            [sourceFactorOld, destinationFactorOld] = Screen('BlendFunction', obj.winPtr, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            Screen('DrawDots',obj.winPtr,[obj.x(:), -1*obj.y(:)]', obj.size, obj.color, obj.position, obj.dotType);
            Screen('BlendFunction', obj.winPtr, sourceFactorOld, destinationFactorOld);
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
