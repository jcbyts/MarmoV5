classdef gratingFFnoise < stimuli.stimulus
    %GRATINGFFNOISE draws Full-field grating reverse correlation procedurally
    %   Run full-field procedural grating noise
    % Sample code:
    % Paste in this code snippet to see how to use, and demonstrate the
    % seed reconstruction
    % o = stimuli.gratingFFnoise(A.window, 'pixPerDeg', S.pixPerDeg, ...
    %   'numOrientations', 10, ...
    %   'minSF', 0.5, ...
    %   'numOctaves', 5, ...
    %   'randomizePhase', true, ...
    %   'probBlank', 0.5);
    % o.updateTextures();
    % o.updateEveryNFrames = 3; % only update every N frames
    %
    % o.afterFrame();
    % o.beforeFrame();
    % Screen('Flip', A.window);
    
    properties
        winPtr % PTB window pointer
        
        % properties of the stimulus generation process
        minSF double % minimum spatial frequency
        numOctaves double % number of spatial frequency octaves
        numOrientations double % number of orientations
        % Note: these three parameters (above) can be overridden to produce
        % any combo of orientations and spatial frequencies using the
        % parameters below
        
        orientations double       % list of orientations
        spatialFrequencies double % list of spatial frequencies
        randomizePhase logical
        updateEveryNFrames % if the update should only run every N frames
        probBlank % probability of a blank frame
        
        % internally used paramters
        tex         % the texture object
        texRect     % texture object rect
        pixPerDeg double
        orientation % orientation of current grating
        cpd % cycles per degree of current grating
        contrast % contrast of current grating
        frameUpdate % counter for updating the frame
        phase % phase of the current grating
        
        disableNormalization
        modulateColor
        contrastPreMultiplicator
        
    end
    
    methods
        function obj = gratingFFnoise(winPtr, varargin)
            % GRATINGFFNOISE is the constructor
            % build the object with required properties
            
            obj = obj@stimuli.stimulus();
            obj.winPtr = winPtr;
            
            ip = inputParser();
            ip.addParameter('minSF', 1)
            ip.addParameter('numOctaves', 5)
            ip.addParameter('numOrientations', 10)
            ip.addParameter('pixPerDeg', [])
            ip.addParameter('probBlank', 0.5)
            ip.addParameter('contrast', 0.5)
            ip.addParameter('randomizePhase', false)
            ip.addParameter('updateEveryNFrames', 2)
            
            ip.parse(varargin{:});
            
            args = ip.Results;
            props = fieldnames(args);
            for iField = 1:numel(props)
                obj.(props{iField}) = args.(props{iField});
            end
            
            if isempty(obj.pixPerDeg)
                warning('gabornoise: I need the pixPerDeg to be accurate')
                obj.pixPerDeg = 37.5048;
            end
            
            obj.disableNormalization = 1; % don't normalize the gabor by the gaussian sigma
            obj.modulateColor = [0 0 0 0]; %  zeros means don't offset the background (depends on blend function)
            obj.contrastPreMultiplicator = 0.5; % 0.5 scales max response to contrast is interpretable
            obj.updateEveryNFrames = max(obj.updateEveryNFrames, 1); % must be at least 1.0 (every frame)
            obj.frameUpdate = 0;
            
            % initialize orientation and spatial frequency space
            obj.orientations = 0:(360/obj.numOrientations):(360-(360/obj.numOrientations));
            obj.spatialFrequencies = obj.minSF * 2.^(0:obj.numOctaves-1);
            obj.phase = 0;
        end
        
        function beforeTrial(obj)
            obj.setRandomSeed();
            obj.frameUpdate = 0;
        end
        
        function beforeFrame(obj)
            obj.drawGrating();
        end
        
        function afterFrame(obj)
            
            if obj.frameUpdate==0
                
                % orientation
                obj.orientation = randsample(obj.rng, obj.orientations, 1);
                
                % phase
                if obj.randomizePhase
                    obj.phase = rand(obj.rng,1)*180; % phase
                end
                
                % frequency (convert to pixels/cycle)
                if rand(obj.rng, 1) < obj.probBlank
                    obj.cpd = 0; % blank frame
                else
                    obj.cpd = randsample(obj.rng, obj.spatialFrequencies, 1);
                end
                
            end
            
            obj.frameUpdate = mod(obj.frameUpdate +1, obj.updateEveryNFrames);
            
        end
        
        function updateTextures(obj, varargin)
            
            % Size of support in pixels, derived from si:
            res = 2*1e3+1;
            
            % Build a procedural gabor texture for a gabor with a support of tw x th
            % pixels and the 'nonsymetric' flag set to 1 == Gabor shall allow runtime
            % change of aspect-ratio:
            [obj.tex,obj.texRect] = CreateProceduralGabor(obj.winPtr, res, res, [], obj.modulateColor, obj.disableNormalization,obj.contrastPreMultiplicator);
        end
        
        
          
        function CloseUp(obj)
            if ~isempty(obj.tex)
                Screen('Close',obj.tex);
                obj.tex = [];
            end
        end
        
        function drawGrating(obj)
            if (~isempty(obj.tex))
                
                [sourceFactorOld, destinationFactorOld] = Screen('BlendFunction', obj.winPtr, GL_ONE, GL_ONE);
                
                freq = obj.cpd/obj.pixPerDeg;
                sigma = inf; % drawing a gabor with an infinite sigma
                
                Screen('DrawTexture', obj.winPtr, obj.tex, obj.texRect, [obj.texRect], 90+obj.orientation, [], [], [], [], kPsychDontDoRotation, [-obj.phase+90, freq, sigma, obj.contrast, 1, 0, 0, 0]);
                Screen('BlendFunction', obj.winPtr, sourceFactorOld, destinationFactorOld);
                
            end
        end
        
        function I = getImage(obj, rect, binSize)
            % GETIMAGE returns the image that was shown without calling PTB
            % I = getImage(obj, rect)
            if nargin < 3
                binSize = 1;
            end
            
            % build support
            xx = rect(1):binSize:(rect(3)-binSize);
            yy = rect(2):binSize:(rect(4)-binSize);
            
            % compute image without PTB running ... follow exact steps
            if obj.cpd==0
                nx = numel(xx);
                ny = numel(yy);
                I = zeros(ny, nx);
                return
            end
            
            % use values from our openGL shaders
            twopi = 2.0 * 3.141592654;
            deg2rad = 3.141592654 / 180.0;
            
            
            
            [X,Y] = meshgrid(xx,yy);
            
            % offset the texture center
            X = X - obj.texRect(3)/2;
            Y = Y - obj.texRect(4)/2;
           
            % scale by cpd
            maxRadians = twopi * obj.cpd / obj.pixPerDeg;
            
            % Create the sinusoid
            pha = (obj.phase - 0) * deg2rad;
            ori = (90 - obj.orientation)*deg2rad;
            
            gx = cos(ori) * (maxRadians*X) + sin(ori) * (maxRadians*Y) + pha;
            
            I = cos( gx );
            I = round(I * obj.contrast * obj.contrastPreMultiplicator * 255);
            
        end
        
        
    end
end

