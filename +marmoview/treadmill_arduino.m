% wrapper class for treadmill
% 4/28/2021 - Jake Yates
classdef treadmill_arduino < matlab.mixin.Copyable
    %******* basically is just a wrapper for a bunch of calls to the
    % arduino toolbox. based on code snippet from huklabBasics
    %     https://github.com/HukLab/huklabBasics/blob/584b5d277ba120b2e33e4f05c0657cacde67e1fa/%2Btreadmill/pmTread.m
    
    properties (SetAccess = public, GetAccess = public)
        arduinoUno % handle to the IOport 
        timeOpened double
        timeLastSample double
        scaleFactor double
        rewardMode char
        locationSpace double
        maxFrames double
        rewardDist
        rewardProb
    end
    
    properties (SetAccess = private, GetAccess = public)
        port
        baud
        nextReward
        frameCounter double 
    end
    
    methods
        function self = treadmill_arduino(varargin) % h is the handle for the marmoview gui
            
            % initialise input parser
            ip = inputParser;
            ip.addParameter('port',[]);
            ip.addParameter('baud', 115200)
            ip.addParameter('scaleFactor', [])
            ip.addParameter('rewardMode', 'dist')
            ip.addParameter('maxFrames', 5e3)
            ip.addParameter('rewardDist', 94.25)
            ip.addParameter('rewardProb', 1)
            ip.parse(varargin{:});
            
            args = ip.Results;
            fields = fieldnames(args);
            for i = 1:numel(fields)
                self.(fields{i}) = args.(fields{i});
            end

            config=sprintf('BaudRate=%d ReceiveTimeout=.1', self.baud); %DTR=1 RTS=1 
        
            [self.arduinoUno, ~] = IOPort('OpenSerialPort', self.port, config);
            self.timeOpened = GetSecs();
            self.timeLastSample = self.timeOpened;
            
            self.frameCounter = 1;
            self.locationSpace = nan(self.maxFrames, 5); % time, timestamp, loc, locScale, rewardState
            
            self.nextReward = self.rewardDist;
        end
        
        
    end % methods
    
    methods (Access = public)
        
        function out = afterFrame(self, currentTime, rewardState)
            
            self.locationSpace(self.frameCounter,1) = currentTime;
            self.locationSpace(self.frameCounter,5) = rewardState;
            % collect position data
            [count, timestamp] = self.readCount();
            
            self.locationSpace(self.frameCounter, 2) = timestamp;
            if ~isnan(count)
                self.locationSpace(self.frameCounter,3:4) = count * [1 self.scaleFactor];
            elseif isnan(count) && self.frameCounter == 1 % bad count on frame 1
                self.locationSpace(self.frameCounter,3:4) = 0;
            else % bad count not on frame 1, use previous sample
                self.locationSpace(self.frameCounter,3:4) = self.locationSpace(self.frameCounter-1,3:4);
            end
            
            % reward
            switch self.rewardMode
                
                case 'dist'
                    if self.locationSpace(self.frameCounter, 4) > self.nextReward   
%                         tmp = double(rand < self.rewardProb);
                        self.locationSpace(self.frameCounter,5) = self.locationSpace(self.frameCounter,5) + 1; % add one drop
                        self.nextReward = self.nextReward + self.rewardDist;
                    end  
                case 'distProb'
                    if self.locationSpace(self.frameCounter, 4) > self.nextReward
                        tmp = double(rand < self.rewardProb);
                        self.locationSpace(self.frameCounter,5) = self.locationSpace(self.frameCounter,5) + tmp; % add one drop
                        if tmp == 1
                            self.nextReward = self.nextReward + self.rewardDist;
                        end
                    end
            end
            
            out = self.locationSpace(self.frameCounter,5);
            self.frameCounter = self.frameCounter + 1;
        end 
        
        function [count, timestamp] = readCount(self)
            % read from buffer, take last sample
            msg = IOPort('Read', self.arduinoUno);
            a = regexp(char(msg), 'time:(?<time>\d+),count:(?<count>\d+),', 'names');
            if isempty(a)
%                 disp('message was empty')
                count = nan;
                timestamp = nan;
            else
%                 timestamp = arrayfun(@(x) str2double(x.time), a(end));
%                 count = arrayfun(@(x) str2double(x.count), a(end));
                count = str2double(a(end).count);
                timestamp = str2double(a(end).time);
            end
        end
        
        function reset(self)
            IOPort('Write', self.arduinoUno, 'reset');
            self.frameCounter = 1;
            self.locationSpace(:) = nan;
            IOPort('Flush', self.arduinoUno);
        end
        
        function close(self)
            if ~isempty(self.arduinoUno)
                IOPort('Close', self.arduinoUno)
                self.arduinoUno = [];
            end
        end
    end % private methods
    
    methods (Static)
       
        
    end
    
end % classdef
