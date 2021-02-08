classdef dotspatialnoise < stimuli.dotsbase
    %DOTSPATIALNOISE uses the dots class for spatiotemporal reverse
    %correlation
    %   Detailed explanation goes here
    
    properties
        updateEveryNFrames % if the update should only run every 
        frameUpdate
        contrast
        sigma
    end
    
    methods
        function obj = dotspatialnoise(winPtr, varargin)
            
            obj = obj@stimuli.dotsbase(winPtr, varargin{:});
            
            ip = inputParser();
            ip.KeepUnmatched = true;
            ip.addParameter('contrast', .5)
            ip.addParameter('updateEveryNFrames', 3)
            ip.addParameter('frameUpdate', 0)
            ip.addParameter('sigma', inf)
            ip.addParameter('speed', 0)
            ip.parse(varargin{:});
            obj.lifetime = inf;
             
            obj.contrast = ip.Results.contrast;
            obj.updateEveryNFrames = ip.Results.updateEveryNFrames;
            obj.frameUpdate = ip.Results.frameUpdate;
            obj.sigma = ip.Results.sigma;
            obj.maxRadius = inf;
            obj.position = obj.winCtr;
            obj.dotType = 2;
            obj.speed = ip.Results.speed;
        end
        
        function beforeTrial(obj)
            
            % frameUpdate needs to be 0 for init to work
            obj.frameUpdate = 0;
            
            % call parent function (calls initDots)
            beforeTrial@stimuli.dotsbase(obj)
            
            % set the frame update counter
            obj.frameUpdate = 0;
            
        end
        
        function afterFrame(obj)
            
            if obj.frameUpdate==0
                obj.initDots(1:obj.numDots);
            end
            obj.moveDots()
            
            obj.frameUpdate = mod(obj.frameUpdate +1, obj.updateEveryNFrames);
            
        end
        
        function initDots(obj, idx)
            %INITDOTS randomly positions the dots
            n = numel(idx);
            if ~isinf(obj.sigma)
                obj.x(idx) = randn(obj.rng, 1, n) * obj.sigma;
                obj.y(idx) = randn(obj.rng, 1, n) * obj.sigma;
            else
                obj.x(idx) = rand(obj.rng, 1, n) * obj.winRect(3) + -obj.winRect(3)/2;
                obj.y(idx) = rand(obj.rng, 1, n) * obj.winRect(4) + -obj.winRect(4)/2;
            end
            obj.dx(idx) = randn(obj.rng, 1, n) * obj.speed;
            obj.dy(idx) = randn(obj.rng, 1, n) * obj.speed;
            
            if n == obj.numDots
                obj.color = 127 + round(obj.contrast*127*[1; 1; 1]*sign( (rand(obj.rng, 1, n)<.5)-.5));
            else
                obj.color(idx) = 127 + round(obj.contrast*127*[1; 1; 1]*sign( (rand(obj.rng, 1, n)<.5)-.5));
            end
        end
        
        function I = getImage(obj, rect, dx)
            if nargin < 3
                dx = 1;
            end
            
            if nargin < 2
                rect = obj.position([1 2 1 2]) + [-1 -1 1 1].*[obj.position obj.position];
            end
            
            xax = rect(1):dx:(rect(3)-dx);
            yax = rect(2):dx:(rect(4)-dx);
            
            [xx, yy] = meshgrid(xax,yax);
            
            x = xax([1 end])' - obj.x - obj.position(1);
            y = yax([1 end])' + (obj.y - obj.position(2));
            
            ix = x(1,:) < 0 & x(2,:) > 0;
            ix = ix & (y(1,:) < 0 & y(2,:) > 0);
%             figure(1); clf; 
%             plot(x(1,:), y(1,:), '.'); hold on
%             plot(x(1,ix), y(1,ix), '.'); hold on
%             plot(x(2,:), y(2,:), '.'); hold on
%             plot(xax, yax, 'r')
%             
%             bad = (x > rect(3) | x < rect(1)) | (y > rect(4) | y < rect(2));
%             ix = ~bad;
            if ~any(ix)
                I = zeros(size(xx));
                return
            end
            posx = xx(:) - obj.x(ix) - obj.position(1);
            posy = yy(:) + (obj.y(ix) - obj.position(2));
            
            I = double(sqrt(posx.^2 + posy.^2) < obj.size/2);
            c = (obj.color(ix)) - 127;
            I = I.*c;
            
%             I = fliplr(I);
            
            Iind = cumsum(abs(I),2);
%             
            occlusions = Iind(:,end) > max(c); % means more than one dot was shown in this location
            finalValue = Iind(occlusions,:)==max(Iind(occlusions,:), [], 2);
%             occluders = [zeros(sum(occlusions), 1) diff(finalValue, [], 2)]==1;
            
            
            
            
            img = sum(I,2);
            img(occlusions) = sum((I(occlusions,:).*finalValue),2);
            
            I = reshape(img, size(xx));
            
            
        end
        
        function CloseUp(obj) % empty
            
        end
    end
end

