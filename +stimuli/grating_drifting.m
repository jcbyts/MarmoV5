classdef grating_drifting < stimuli.stimulus
    %GRATING_DRIFTING draws drifting gratings and updates when they're on
    % and off
    %  Can run full-field or apertured
    % Sample code:
    % Paste in this code snippet to see how to use, and demonstrate the
    % seed reconstruction
    % o = stimuli.gratingFFnoise(A.window, 'pixPerDeg', S.pixPerDeg, ...
    %   'numDirections', 16, ...
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
        numDirections double % number of orientations
        contrasts double % list of contrast
        
        % Note: these three parameters (above) can be overridden to produce
        % any combo of orientations and spatial frequencies using the
        % parameters below
        
        directions double       % list of directions
        speeds double
        speed=0
        spatialFrequencies double % list of spatial frequencies
        randomizePhase logical
        durationOn double  % duration a grating is on (frames)
        durationOff double % inter-stimulus interval (frames)
        isiJitter double % amount of jitter to add to the isi (frames)
        position double
        diameter double
        
        % --- internally used paramters
        tex         % the texture object
        texRect     % texture object rect
        screenRect
        frameRate
        pixPerDeg double
        orientation=0 % orientation of current grating
        cpd=0 % cycles per degree of current grating
        contrast=0 % contrast of current grating
        frameUpdate % counter for updating the frame
        phase=0 % phase of the current grating
        dphase=0 % current phase step
        
    end
    
    methods
        function obj = grating_drifting(winPtr, varargin)
            % The constructor
            % build the object with required properties
            
            obj = obj@stimuli.stimulus();
            obj.winPtr = winPtr;
            
            ip = inputParser();
            ip.addParameter('minSF', 1)
            ip.addParameter('numOctaves', 5)
            ip.addParameter('numDirections', 16)
            ip.addParameter('speeds', 5) % phase shift per frame
            ip.addParameter('pixPerDeg', [])
            ip.addParameter('frameRate', [])
            ip.addParameter('position', [500 500])
            ip.addParameter('diameter', inf) % inf = fullfield
            ip.addParameter('durationOn', 10)
            ip.addParameter('durationOff', 10)
            ip.addParameter('isiJitter', 5)
            ip.addParameter('screenRect', [])
            ip.addParameter('contrasts', 0.5)
            ip.addParameter('randomizePhase', false)
            
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
            
            if isempty(obj.frameRate)
                warning('gabornoise: I need the frameRate to be accurate')
                obj.frameRate = 60;
            end
            
            obj.frameUpdate = 0;
            
            % initialize direction and spatial frequency space
            obj.directions = 0:(360/obj.numDirections):(360-(360/obj.numDirections));
            obj.spatialFrequencies = obj.minSF * 2.^(0:obj.numOctaves-1);
            obj.phase = 0;
        end
        
        function beforeTrial(obj)
            obj.setRandomSeed();
            obj.frameUpdate = 0;
            obj.stimValue=0;
        end
        
        function beforeFrame(obj)
            obj.tex.beforeFrame();
        end
        
        function afterFrame(obj)
            
            % frameUpdate can be 0, < 0 or > 0
            % frameUpdate = 0, select a new grating
            % frameUpdate > 0, draw grating and count down to 0
            % frameUpdate < 0, draw no grating and count up to 0
            if obj.frameUpdate==0
                
                % if grating was just "on" enter "off" mode
                if obj.stimValue==1 % grating is on, turn it off
                    
%                     obj.cpd = 0; % grating is blank (CPD = 0)
                    jitter = round(rand(obj.rng)*obj.isiJitter);
                    obj.frameUpdate = -(obj.durationOff + jitter); % new frame update is a negative number to indicate time off
                    obj.stimValue = 0; % turn stimulus off
                    
                    obj.contrast = 0;
                    
                elseif obj.stimValue==0 % stimulus was just off
                    
                    obj.stimValue = 1; % turn stimulus off
                    
                    % spatial frequency
                    obj.cpd = randsample(obj.rng, obj.spatialFrequencies, 1);
                    
                    % orientation
                    obj.orientation = randsample(obj.rng, obj.directions, 1)+90; % orientation is 90° from direction
                    
%                     if numel(obj.speeds)==1
%                         obj.dphase = obj.speeds*obj.cpd*360;
%                     else
                    obj.speed = randsample(obj.rng, obj.speeds, 1);
                    obj.dphase = obj.speed/obj.frameRate*obj.cpd*360;
%                     end
                    
                    % phase
                    if obj.randomizePhase % randomize initial phase of grating
                        obj.phase = rand(obj.rng,1)*180; % phase
                    end
                    
                    obj.frameUpdate = obj.durationOn;
                    

                    obj.contrast = randsample(obj.rng, obj.contrasts, 1);

                end
                
                obj.tex.cpd = obj.cpd;
                obj.tex.orientation = obj.orientation;
                
                
                obj.tex.transparent = obj.contrast;
            end
            
            obj.phase = obj.phase - obj.dphase;
            obj.tex.phase = obj.phase;
            
            if obj.frameUpdate < 0
                obj.frameUpdate = obj.frameUpdate + 1;
            else
                obj.frameUpdate = obj.frameUpdate - 1;
            end
            
        end
        
        function updateTextures(obj, varargin)
            % update grating texture
            obj.tex = stimuli.grating_procedural(obj.winPtr);
            
            % match the two gratings
            obj.tex.screenRect = obj.screenRect;
            obj.tex.radius = round((obj.diameter/2)*obj.pixPerDeg);
            
            obj.tex.phase = 0; % black
            obj.tex.orientation = 0; % cpd will be zero => all one color
            obj.tex.cpd = 0; % when cpd is zero, you get a Gauss
            
            obj.tex.position = obj.position;
            obj.tex.range = 127; % bit depth shouldn't be hard coded
            obj.tex.square = false;
            obj.tex.gauss = true;
            obj.tex.bkgd = 127;
            obj.tex.transparent = obj.contrast;
            obj.tex.pixperdeg = obj.pixPerDeg;
            
            obj.tex.updateTextures();
        end
        
        
          
        function CloseUp(obj)
            if ~isempty(obj.tex)
%                 Screen('Close',obj.tex);
                obj.tex = [];
            end
        end
        
        
        function I = getImage(obj, rect, binSize)
            % GETIMAGE returns the image that was shown without calling PTB
            % I = getImage(obj, rect)
            if nargin < 3
                binSize = 1;
            end
            
            I = obj.tex.getImage(rect, binSize);
            
        end
        
        
    end
end

