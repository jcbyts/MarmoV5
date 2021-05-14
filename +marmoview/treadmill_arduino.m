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
<<<<<<< HEAD
            ip.addParameter('port','/dev/ttyACM0');
            ip.addParameter('board', 'Uno')
            ip.addParameter('name', 'Libraries')
            ip.addParameter('value', 'rotaryEncoder')
            ip.addParameter('channelA', 'D3')
            ip.addParameter('channelB', 'D2')
            ip.addParameter('scaleFactor', 2)
=======
            ip.addParameter('port',[]);
            ip.addParameter('baud', 115200)
            ip.addParameter('scaleFactor', 1)
>>>>>>> 755eeaf22be48b5af162b3bfe61114b7c41cb709
            ip.addParameter('rewardMode', 'dist')
            ip.addParameter('maxFrames', 5e3)
            ip.addParameter('rewardDist', inf)
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
        
<<<<<<< HEAD
        function reset(self)
            resetCount(self.encoder);
            self.frameCounter = 1;
            self.locationSpace(:) = nan;
        end            
=======
        
    end % methods
    
    methods (Access = public)
>>>>>>> 755eeaf22be48b5af162b3bfe61114b7c41cb709
        
        function out = afterFrame(self, currentTime, rewardState)
            
            self.locationSpace(self.frameCounter,1) = currentTime;
            self.locationSpace(self.frameCounter,5) = rewardState;
            % collect position data
            [count, timestamp] = self.readCount();
            
            self.locationSpace(self.frameCounter, 2) = timestamp;
            if ~isnan(count)
                self.locationSpace(self.frameCounter,3:4) = count * [1 self.scaleFactor];
            else % bad count, use previous sample
                self.locationSpace(self.frameCounter,3:4) = self.locationSpace(self.frameCounter-1,3:4);
            end
            
            % reward
            switch self.rewardMode
                
                case 'dist'
                    if self.locationSpace(self.frameCounter, 4) > self.nextReward && self.locationSpace(self.frameCounter-1, 4) < self.nextReward   
                        self.locationSpace(self.frameCounter,5) = self.locationSpace(self.frameCounter,5) + 1; % add one drop
                        self.nextReward = self.nextReward + self.rewardDist;
                    end  
                case 'time'
                    warning('treadmill_arduino: time reward not implemented')
            end
            
            out = self.locationSpace(self.frameCounter,5);
            self.frameCounter = self.frameCounter + 1;
<<<<<<< HEAD
        end        
        
    end % end methods
=======
        end 
        
        function [count, timestamp] = readCount(self)
            % read from buffer, take last sample
            msg = IOPort('Read', self.arduinoUno);
            a = regexp(char(msg), 'time:(?<time>\d+),count:(?<count>\d+),', 'names');
            if isempty(a)
                disp('message was empty')
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
>>>>>>> 755eeaf22be48b5af162b3bfe61114b7c41cb709
    
    methods (Static)
       
        
    end
    
end % classdef