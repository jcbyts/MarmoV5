classdef stimulus < matlab.mixin.Copyable % a copyable handle class
    % STIMULUS is a class that logs how its own property changes
    %   The property <strong>stimvalue</strong> will be tracked and any time
    %   it is changed, the time of change will be logged and saved in the
    %   property <strong>log</strong> along with the value at that change.
    %  
    % It is unlikely that you will ever instantiate a stimulus on its own.
    % For use, see <strong>stimuli.fixation</strong>, or 
    % <strong>stimuli.target</strong>
    %
    % STIMULUS should be the core class for any stimulus implemented in
    % pds-stimuli protocols. A stimulus doesn't really do anything except
    % track when its property <strong>stimvalue</strong> is changed and
    % manage a RandStream number generator.
    % 
    % PROPERTIES
    %   stimValue   a scalar (double, logical) that has some meaning for 
    %               the stimulus. For example 0 (false) means the stimulus
    %               isn't shown. 1 (true) means the stimulus is shown. 2
    %               (or any real number can indicate some other feature of
    %               the stimulus).
    %               Importantly, any time stimValue changes, the time of
    %               change is logged using GetSecs -- thus, the PTB clock
    %               value is stored whenever this value changes.
    %               
    %   log         a [2 x m] log of all changes to stimValue. Since
    %               stimValue initializes to true, <strong>log</strong> will
    %               always start with a [2 x 1] entry storing the time the
    %               <strong>stimulus</strong> was constructed.
    %
    %   rng         a RandStream object. This is instantiated automatically
    %               when the stimulus is constructed. It defaults to the
    %               mt199937ar random number generator with a seed of 0. To
    %               set rng, you can either pass in a RandStream object, or
    %               pass in a seed.
    %
    %   tracked     logical, flags whether the stimValue property logs
    %               itself
    %               
    %  Example Calls:
    %               s = stimuli.stimulus(); % create stimulus object
    %                                       % automatically sets up rng
    %               >> s.rng.Seed           % calling Seed returns the
    %                                       % current seed
    %               s.setRandomSeed();      % randomly assign seed
    %               
    %               or
    %               
    %               s.setRandomSeed(1234)   % sets the seed to 1234
    %               
    %               or
    % 
    %               s.setRandomSeed(RandStream('twister', 'Seed', 1235))
    % 
    %               s.stimValue = 2; 
    %               check the log to see when stimValue was set to 2
    

    
    properties (Access = public)
        stimValue
        rng RandStream = RandStream('mt19937ar')
        tracked logical = false % default is not to track object
    end
    
    properties (SetAccess = ?stimuli.objects.stimulus, GetAccess = public)
        log
        locked logical = false
    end
    
    methods
        % --- class constructor
        function obj = stimulus(varargin)
%             obj.stimValue = true; % the stimulus defaults to a value of true
            
            rngArg  = find(cellfun(@(x) strcmp(x, 'rng'), varargin));
            seedArg = find(cellfun(@(x) strcmp(x, 'seed'), varargin));
            
            if ~isempty(rngArg)
                obj.rng = varargin{rngArg+1};
            end
            
            if ~isempty(seedArg)
                obj.rng = RandStream(obj.rng.Type, 'Seed', varargin{seedArg+1});
            end
            
        end
        
        function initLog(obj)
            if isempty(obj.stimValue)
                obj.stimValue = 0;
            end
            
            obj.log = [obj.stimValue; GetSecs]; % clear log up to this point
%             obj.log = [];
%             obj.stimValue = false; % don't reset stim value anymore
        end
        
        % --- set function logs the value when it is change
        function set.stimValue(obj, val)
            if obj.locked
                warning('you cannot modify a locked object')
                return
            end
            
            if obj.stimValue==val
                return
            end
            obj.stimValue = val;
            if obj.tracked
                obj.log(:,end+1) = [obj.stimValue; GetSecs];
            end
        end
        
        % --- Manage the random number generator
        function setRandomSeed(obj, arg)
            % can pass in a RandStream object
            % a seed
            % or nothing
            
            if nargin < 2
                seed = randi(10^7);
            else
                seed = arg;
            end
            
            if isa(seed, 'RandStream')
                obj.rng = seed;
            else
                obj.rng = RandStream(obj.rng.Type, 'Seed', seed);
            end
            
        end
        
        function cleanup(obj)
            obj.locked = true;
        end
            
    end
    
end