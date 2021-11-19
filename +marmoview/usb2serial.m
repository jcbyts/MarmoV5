classdef usb2serial
    %USB2SERIAL is a class for sending 

    properties
        portid char
        handle
        baud

    end

    methods
        function obj = usb2serial(varargin)
            %Usb2Serial Construct an instance of this class
            %   
            ip = inputParser();
            ip.addParameter('portid', '/dev/ttyUSB0')
            ip.addParameter('baudrate', 110)
            ip.parse(varargin{:});

            obj.portid = ip.Results.portid;
            obj.baud = ip.Results.baudrate;
            
            if ~isempty(obj.portid)
                obj.open()
            end
        end
        
        function open(obj)

            config = sprintf('BaudRate=%d DTR=0 RTS=0', obj.baud);
            [obj.handle,errmsg] = IOPort('OpenSerialPort', obj.portid, config);
            if ~isempty(errmsg)
                disp(errmsg)
                error("Usb2Serial: Could not open port. Try IOPort('CloseAll'), then run again.")
            end
        end

        function timestamp = sendTTL_DTR(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            IOPort('ConfigureSerialPort', obj.handle, sprintf('DTR=%i',1));
            timestamp = GetSecs();
            IOPort('ConfigureSerialPort', obj.handle, sprintf('DTR=%i',0));
        end

        function timestamp = sendTTL_RTS(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            IOPort('ConfigureSerialPort', obj.handle, sprintf('RTS=%i',1));
            timestamp = GetSecs();
            IOPort('ConfigureSerialPort', obj.handle, sprintf('RTS=%i',0));
        end

        function timestamp = strobe_word(obj, word)
            n = numel(word);
            timestamp = zeros(n,1);
            
            for i = 1:n
                IOPort('ConfigureSerialPort', obj.handle, sprintf('DTR=%i',1));
                [~, timestamp(i)] = IOPort('Write', obj.handle, uint8(word(i)));
                IOPort('ConfigureSerialPort', obj.handle, sprintf('DTR=%i',0));
            end

        end

    end
end