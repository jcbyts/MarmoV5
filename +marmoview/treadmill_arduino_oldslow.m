% wrapper class for treadmill
% 4/28/2021 - Jake Yates
classdef treadmill_arduino_oldslow < matlab.mixin.Copyable
    %******* basically is just a wrapper for a bunch of calls to the
    % arduino toolbox. based on code snippet from huklabBasics
    %     https://github.com/HukLab/huklabBasics/blob/584b5d277ba120b2e33e4f05c0657cacde67e1fa/%2Btreadmill/pmTread.m
    
    properties (SetAccess = public, GetAccess = public)
        arduinoUno
        encoder
        timeOpened double
        timeLastSample double
        scaleFactor double
        rewardMode char
        locationSpace double
        maxFrames double
        rewardDist
    end
    
    properties (SetAccess = private, GetAccess = public)
        port
        board char
        name char
        value char
        channelA char
        channelB char
        nextReward
        frameCounter double 
    end
    
    methods
        function self = treadmill_arduino_oldslow(varargin) % h is the handle for the marmoview gui
            
            % initialise input parser
            ip = inputParser;
            ip.addParameter('port',[]);
            ip.addParameter('board', 'Uno')
            ip.addParameter('name', 'Libraries')
            ip.addParameter('value', 'rotaryEncoder')
            ip.addParameter('channelA', 'D3')
            ip.addParameter('channelB', 'D2')
            ip.addParameter('scaleFactor', 1)
            ip.addParameter('rewardMode', 'dist')
            ip.addParameter('maxFrames', 5e3)
            ip.addParameter('rewardDist', inf)
            ip.parse(varargin{:});
            
            args = ip.Results;
            fields = fieldnames(args);
            for i = 1:numel(fields)
                self.(fields{i}) = args.(fields{i});
            end

            self.arduinoUno = arduino(self.port, self.board, self.name, self.value);
            self.encoder = rotaryEncoder(self.arduinoUno, self.channelA, self.channelB);
            self.timeOpened = GetSecs();
            self.timeLastSample = self.timeOpened;
            
            self.frameCounter = 1;
            self.locationSpace = nan(self.maxFrames, 4); % time, loc, locScale, rewardState
            
            self.nextReward = self.rewardDist;
        end
        
        
    end % methods
    
    methods (Access = private)
        
        function out = afterFrame(self, currentTime, rewardState)
            
            self.locationSpace(self.frameCounter,1) = currentTime;
            self.locationSpace(self.frameCounter,4) = rewardState;
            % collect position data
            if mod(self.frameCounter,2) == 0 % is even frame
                
                self.locationSpace(self.frameCounter,2:3) = readCount(self.encoder) * [1 self.scaleFactor];
                
            elseif self.frameCounter == 1
                
                self.reset();
                
                self.locationSpace(self.frameCounter,2:3) = [0 0];
                
            else
                % same as previous frame
                self.locationSpace(self.frameCounter,2:3) = self.locationSpace(self.frameCounter-1,2:3);
            end
            
            % reward
            switch self.rewardMode
                
                case 'dist'
                    if self.locationSpace(self.frameCounter, 3) > self.nextReward && self.locationSpace(self.frameCounter-1, 3) < self.nextReward   
                        self.locationSpace(self.frameCounter,4) = self.locationSpace(self.frameCounter,4) + 1; % add one drop
                        self.nextReward = self.nextReward + self.rewardDist;
                    end  
                case 'time'
                    warning('treadmill_arduino: time reward not implemented')
            end
            
            out = self.locationSpace(self.frameCounter,4);
            self.frameCounter = self.frameCounter + 1;
        end 
        
        function reset(self)
            resetCount(self.encoder); 
            self.frameCounter = 1;
            self.locationSpace(:) = nan;
        end
        
    end % private methods
    
    methods (Static)
       
        
    end
    
end % classdef
