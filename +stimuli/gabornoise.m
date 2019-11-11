classdef gabornoise < stimuli.stimulus
    %GABORNOISE draw garborium noise procedurally
    %   Detailed explanation goes here
    
    properties
        winPtr % PTB window pointer
        
        position % center (in pixels)
        radius % size of patch (in pixels)
        
        % properties of the stimulus generation process
        numGabors   % number of gabors
        scaleRange  % range of scales shown (in d.v.a)
        sfRange     % range of spatial frequencies (in cycles/deg)
        minScale    % smallest supported scale
        minSF       % smallest supported spatial frequency
        updateEveryNFrames % if the update should only run every 
        
        % internally used paramters
        tex         % the texture object
        pixPerDeg double
        texWidth double % support of individual textures is texWidth * 2 + 1
        mypars
        x
        y
        orientation
        contrast
        frameUpdate
        
        disableNormalization
        modulateColor
        contrastPreMultiplicator
        
    end
    
    methods
        function obj = gabornoise(winPtr, varargin)
            
            obj = obj@stimuli.stimulus();
            obj.winPtr = winPtr;
            
            ip = inputParser();
            ip.addParameter('texWidth', 32)
            ip.addParameter('minSF', 0)
            ip.addParameter('sfRange', 20)
            ip.addParameter('minScale', .1)
            ip.addParameter('scaleRange', 2)
            ip.addParameter('pixPerDeg', [])
            ip.addParameter('numGabors', 200)
            ip.addParameter('radius', 200) % radius is really the width of the stimulu patch
            ip.addParameter('position', [640 360])
            ip.addParameter('contrast', 0.5)
            ip.addParameter('updateEveryNFrames', 1)
            
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
        end
        
        function beforeTrial(obj)
            obj.setRandomSeed();
            obj.frameUpdate = 0;
        end
        
        function beforeFrame(obj)
            obj.drawGabors();
        end
        
        function afterFrame(obj)
            
            if obj.frameUpdate==0
                % random initialization for all parameters
                rnd = rand(obj.rng, 6, obj.numGabors);
                
                % orientation
                obj.orientation = rnd(1,:)*360;
                
                % phase
                obj.mypars(1,:) = rnd(2,:)*180; % phase
                
                % frequency (convert to pixels/cycle)
                obj.mypars(2,:) = (rnd(3,:)*obj.sfRange + obj.minSF)/obj.pixPerDeg/2; % frequency
                
                % scale
                obj.mypars(3,:) = rnd(4,:)*obj.scaleRange + obj.minScale;
                obj.mypars(3,:) = (2*obj.mypars(3,:).*obj.pixPerDeg+1)/4; % scale to pixels
                
                % contrast
                obj.mypars(4,:) = obj.contrast;
                
                % position
                offset = obj.radius/2;
                obj.x = rnd(5,:)*obj.radius + obj.position(1) - offset;
                obj.y = rnd(6,:)*obj.radius + obj.position(2) - offset;
            end
            
            obj.frameUpdate = mod(obj.frameUpdate +1, obj.updateEveryNFrames);
            
        end
        
        function updateTextures(obj, varargin)
            
            % Size of support in pixels, derived from si:
            res = 2*obj.texWidth+1;
            
            % Initialize matrix with spec for all 'ngabors' patches to start off
            % identically:
            
            % mypars is 8 x numGabors. The rows are:
            % Phase
            % Freq
            % Scale
            % Contrast
            % aspectratio (defaults to 1.0 in this object)
            % zeros for three rows because the shader needs inputs in
            % multiples of 4
           
            obj.mypars = zeros(8, obj.numGabors);
            
            obj.mypars(2,:) = obj.minSF/obj.pixPerDeg/2;
            obj.mypars(3,:) = (2*obj.minScale*obj.pixPerDeg+1)/4;
            obj.mypars(4,:) = obj.contrast;
            obj.mypars(5,:) = 1.0; % aspect ratio
            
            % Build a procedural gabor texture for a gabor with a support of tw x th
            % pixels and the 'nonsymetric' flag set to 1 == Gabor shall allow runtime
            % change of aspect-ratio:
            obj.tex = CreateProceduralGabor(obj.winPtr, res, res, [], obj.modulateColor, obj.disableNormalization,obj.contrastPreMultiplicator);
  
        end
        
        
          
        function CloseUp(obj)
            if ~isempty(obj.tex)
                Screen('Close',obj.tex);
                obj.tex = [];
            end
        end
        
        function drawGabors(obj)
            if (~isempty(obj.tex))
                
                dstRects = CenterRectOnPointd([0 0 obj.texWidth obj.texWidth]*2, obj.x', obj.y')';
                
                % Procedural gabor textures blend using shaders, so we want
                % them to sum, instead of doing complicated alpha-blending
                % switch to GL_ONE, GL_ONE and store the old blend function
                [sourceFactorOld, destinationFactorOld] = Screen('BlendFunction', obj.winPtr, GL_ONE, GL_ONE);
                Screen('DrawTextures', obj.winPtr, obj.tex, [], dstRects, 90+obj.orientation, [], [], [], [], kPsychDontDoRotation, obj.mypars);
                % reset old blend function
                Screen('BlendFunction', obj.winPtr, sourceFactorOld, destinationFactorOld);
                
            end
        end
        
        function getImage(obj, rect)
            
            
            
        end
        
        
    end
end

