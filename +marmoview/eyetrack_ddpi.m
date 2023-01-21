% wrapper class for dDPI eye tracker
% 8/23/2018 - Jude Mitchell
% 7/31/2019 - Jake Yates
classdef eyetrack_ddpi < handle
    %******* basically is just a wrapper for a bunch of ddpiM calls
    % the mex toolbox written by Ruei-Jr Wu
    
    properties (SetAccess = public, GetAccess = public)
        EyeDump logical; % backwards compatibility with Arrington
        width
        height
        downsamplingRate
        frameRateD
        frameRateN
        p4intensity
        p4radius
        p1
        p4
        timeLastSample
    end
    
    methods
        function o = eyetrack_ddpi(~,varargin) % h is the handle for the marmoview gui
            
            % initialise input parser
            p = inputParser;
            p.addParameter('EyeDump',true,@islogical); % default 1, do EyeDump
            p.addParameter('width', 720)%640)
            p.addParameter('height', 540)%480)
            p.addParameter('downsamplingRate', .5)
            p.addParameter('frameRateD', 539)%601)
            p.addParameter('frameRateN', 1)%1)
            p.parse(varargin{:});
            
            args = p.Results;
            o.EyeDump = args.EyeDump;
            o.width = args.width;
            o.height = args.height;
            o.downsamplingRate = args.downsamplingRate;
            o.frameRateD = args.frameRateD;
            o.frameRateN = args.frameRateN;
            o.p4intensity = 200;
            o.p4radius = 2.1;
            
            ddpiM('setupTracker', [o.width o.height o.downsamplingRate]);
            ddpiM('setupStreamer', [o.width o.height o.frameRateD o.frameRateN]);
            ddpiM('enableDisplay', true);
            ddpiM('enableTrack', true);
            ddpiM('setP1Threshold', 250);
            ddpiM('setP1BoundingBoxSize', 64);
            ddpiM('setP4BoundingBoxSize', 32);
            ddpiM('setP4Template', [o.p4intensity, o.p4radius]);
%             ddpiM('setROI', [20, 20, 640, 450]); % exclude regions
%             ddpiM('setP1roi', [20, 20, 600, 450]); % exclude regions
            
            o.timeLastSample = GetSecs();
            ddpiM('start');


        end
        
        function startfile(o,handles)
            if o.EyeDump
                eyeFile = sprintf('%s_%s_%s_%s.ddpi', ...
                    handles.outputPrefix, ...
                    handles.outputSubject, ...
                    handles.outputDate, ...
                    handles.outputSuffix);
                
                fname = fullfile(handles.outputPath,eyeFile);
                ddpiM('saveTrial', string(fname));
                ddpiM('startTrial');
            end
        end
        
        
        function closefile(o)
            if o.EyeDump
                ddpiM('endTrial');
                ddpiM('saveTrial');
            end
        end
        
        function unpause(o)
            if o.EyeDump
%                 o.start()
            end
        end
        
        function pause(o)
            if o.EyeDump
%                 o.stop()
            end
        end
        
        function [x,y] = getgaze(o)
%             x = 0; y = 0;
            ret = ddpiM('capture');
            o.p1 = ret(1).x;
            o.p4 = ret(2);
%             [o.p1, o.p4] = o.capture;
            % only take the last sample TODO: need to store x,y,time
            % somehow
            x = (ret(2).x - ret(1).x); %o.p4.x(end) - o.p1.x(end);
            y = -(ret(2).y - ret(1).y);  % -(o.p4.y(end)-o.p1.y(end)); % NEED TO INVERT SO ++ IS UP
%             tnow = GetSecs();
% %             o.time = linspace(o.timeLastSample, tnow, numel(x));
%             o.timeLastSample = tnow;
            if isnan(x) || isnan(y)
                x = 0;
                y = 0;
            end
            x = double(x);
            y = double(y);
        end
        
        function r = getpupil(o)
            r = nan;
        end
        
        function endtrial(~)
            ddpiM('endTrial');
            ddpiM('saveTrial');
            ddpiM('startTrial');
        end
        
        function sendcommand(~,~, val)
            % fprintf('SNDCOMMAND: %f\n', val);
            % dump a float with timestamp to ddpi file
            ddpiM('message', val);
            
        end
        
    end % methods
    
    methods (Access = private)
        
    end % private emethods
    
    methods (Static)
        function [p1, p4] = capture()
            ret = ddpiM('capture');
            p1 = ret(1);
            p4 = ret(2);
        end
        
        function enableDisplay(tracking)
            ddpiM('enableDisplay', tracking);
        end
        
        function enableTrack(tracking)
            ddpiM('enableTrack', tracking);
        end
        
        function pos = getCurrentEyePosition()
            pos = ddpiM('getCurrentData');
        end
                
        function dim = getImageDimension()
            dim = ddpiM('getImageDimension');
        end
        
        function pos = getP1()
            pos = ddpiM('getP1');
        end
        
        function bbox = getP1BoundingBox()
            bbox = ddpiM('getP1BoundingBox');
        end
        
        function img = getP1Image()
            img = ddpiM('getP1Image');
        end
        
        function pos = getP4()
            pos = ddpiM('getP4');
        end
        
        function bbox = getP4BoundingBox()
            bbox = ddpiM('getP4BoundingBox');
        end
        
        function setP1BoundingBoxSize(size)
            ddpiM('setP1BoundingBoxSize', size);
        end
        
        function setP1roi(roi)
            ddpiM('setP1roi', [roi.x roi.y roi.width roi.height]);
        end
        
        function setP1Threshold(th)
            ddpiM('setP1Threshold', th);
        end
        
        function setP4BoundingBoxSize(size)
            ddpiM('setP4BoundingBoxSize', size);
        end
        
        function setP4roi(roi)
            ddpiM('setP4roi', [roi.x roi.y roi.width roi.height]);
        end
        
        function setP4Template(amp, radius)
            ddpiM('setP4Template', [amp radius]);
        end
        
        function setROI(x, y, width, height)
            ddpiM('setROI', [x y width height]);
        end
        
        
        function setup(width, height, downsamplingRate, filename)
            if (exist('filename', 'var'))
                ddpiM('setupTracker', [width height downsamplingRate]);
                ddpiM('setupStreamer', [width height downsamplingRate], filename);
            else
                ddpiM('setupTracker', [width height downsamplingRate]);
                ddpiM('setupStreamer', [width height downsamplingRate]);
            end
        end
        
        function shutdown()
            ddpiM('shutdown');
        end
        
        function start()
            ddpiM('start');
        end
        
        function stop()
            ddpiM('stop');
        end
        
        function track()
            ddpiM('track');
        end
        
        function upload(img)
            ddpiM('upload', img);
        end
        
    end
    
end % classdef
