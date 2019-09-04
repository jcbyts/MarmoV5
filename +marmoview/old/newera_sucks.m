% wrapper class for New Era syringe pumps
% Morphed version of NewEra pump including classdef from Shaun, but
% using the IOPort interface developed from PLDAPS

classdef newera < marmoview.liquid
  % Wrapper class for New Era syringe pumps (see http://syringepump.com/).
  %
  % The class constructor can be called with a range of arguments:
  %
  %   port     - serial interface (e.g., COM1)
  %   diameter - syringe diameter (mm)
  %   volume   - dispensing volume (ml)
  %   rate     - dispensing rate (ml per minute)
  
  properties (SetAccess = private, GetAccess = public)
    h = []; %dev@serial; % the serial port object - PRIVATE?
    port; % port for serial communications ('COM1','COM2', etc.)
    commandSeparator;
  end % properties

  % dependent properties, calculated on the fly...
  properties (Dependent, SetAccess = public, GetAccess = public)
    diameter@double; % diameter of the syringe (mm)
    volume@double;   % dispensing volume (mL)
    rate@double;     % dispensing rate (mL per minute)
  end

  methods % set/get dependent properties
    % dependent property set methods
    function o = set.diameter(o,value),
        o.setdia(value);
    end

    function o = set.volume(o,value),
        if o.diameter <= 14.0,
          value = value*1e3; % microliters
        end
        o.setvol(value);
    end

    function o = set.rate(o,value),
        o.setrate(value);
    end

    % dependent property get methods
    function value = get.diameter(o),
        value = 0;
%         [err,status,msg,~] = IOPort('Write', o.h, ['DIA' o.commandSeparator],0); %0.05
%         assert(err == 0);
%         value = str2num(msg);
    end

    function value = get.volume(o),
        value = 0;
%       [err,status,msg,~] = IOPort('Write', o.h, ['VOL' o.commandSeparator],0); 
%       assert(err == 0);
% 
%       pat = '(?<value>[\d\.]{5})\s*(?<units>[A-Z]{2})';
%       tokens = regexp(msg,pat,'names');
%         
%       value = str2num(tokens.value);        
% 
%       % note: value should be returned in ml, however, if diameter <= 14.0mm,
%       %       the pump returns the volume in microliters (unless the default
%       %       units have been over-riden).
%       switch upper(tokens.units),
%         case 'ML', % milliliters
%           value = value;
%         case 'UL', % microliters
%           value = value/1e3; % milliliters
%         otherwise,
%           warning('MARMOVIEW:NEWERA','Unknown volume units ''%s''.', tokens.units);
%       end
    end

    function value = get.rate(o),
        value = 0;
%       [err,status,msg,~] = IOPort('Write', o.h, ['RAT' o.commandSeparator],0); 
%       assert(err == 0);
% 
%       pat = '(?<value>[\d\.]{5})\s*(?<units>[A-Z]{2})';
%       tokens = regexp(msg,pat,'names');
%         
%       value = str2num(tokens.value);
%       
%       switch upper(tokens.units),
%         case 'MM', % milliliters per minute
%           value = value;
%         case 'MH', % millimeters per hour
%           value = value/60.0; % milliliters per minute
%         case 'UM', % microliters per minute
%           value = value/1e3; % milliliters per minute
%         case 'UH', % microliters per hour
%           value = value/(60*1e3); % milliliters per minute
%         otherwise,
%           warning('MARMOVIEW:NEWERA','Unknown rate units ''%s''.', tokens.units);
%       end       
     end
    
  end

  methods
    function o = newera(h,varargin), % h is the handle for the marmoview gui
%       fprintf(1,'marmoview.newera()\n');

      o = o@marmoview.liquid(h,varargin{:}); % call parent constructor

      % initialise input parser
      args = varargin;
      p = inputParser;
      p.KeepUnmatched = true;
      p.StructExpand = true;
      p.addParamValue('port','COM1',@ischar); % default to COM1?
      
      p.addParamValue('diameter',20.0,@isreal); % mm
      p.addParamValue('volume',0.010,@isreal); % ml
      p.addParamValue('rate',10.0,@isreal); % ml per minute

      p.parse(varargin{:});

      args = p.Results;

      o.port = args.port;
      o.diameter = args.diameter;
      o.volume = args.volume;
      o.rate = args.rate;

      % now try and connect to the New Era syringe pump...
      %
      %   data frame: 8N1 (8 data bits, no parity, 1 stop bit)
      %   terminator: CR (0x0D)
      
      config='BaudRate=19200 DTR=1 RTS=1 ReceiveTimeout=1'; % orig
      o.port = 5
      [o.h, errmsg]=IOPort('OpenSerialPort', o.port, config);
      WaitSecs(0.1);
      if ~isempty(errmsg)
        error('newEraSyringePump:setup',['Failed to open serial Port with message ' char(10) errmsg]);
      end
      
      %% Configure pump
      % serial com line terminator
      o.commandSeparator = [char(13) repmat(char(10),1,20)];
    
      % flush serial command pipeline (no command)
      IOPort('Write', o.h, [o.commandSeparator],0);
      % set syringe diameter (...but don't yet, because value is empty here. Why??? --TBC)
      IOPort('Write', o.h, ['DIA' o.commandSeparator],0); %0.05
      % set pumping direction to INFuse   (INF==infuse, WDR==withdraw, REV==reverse current dir)
      IOPort('Write', o.h, ['DIR INF'  o.commandSeparator],0);
      % enable/disable low-noise mode (logical, attempts to reduce high-freq noise from slow pump rates...unk. effect/utility in typical ephys enviro. --TBC)
      IOPort('Write', o.h, ['LN ' num2str(0) o.commandSeparator],0); %low noise mode, try
      % enable/disable audible alarm state (0==off, 1==on/use)
      IOPort('Write', o.h, ['AL ' num2str(0) o.commandSeparator],0); %low noise mode, try
      % set TTL trigger mode ('T2'=="Rising edge starts pumping program";  see NE-500 user manual for other options & descriptions)
      IOPort('Write', o.h, ['TRG ' 'T2'  o.commandSeparator],0);
    
      %
      WaitSecs(0.1);
      
      % Read out current syringe diameter before applying any changes
      %       why?...dia. changes will zero out machine 'volume dispensed' &
      %       would erase record between Pldaps files in a session
      a=char(IOPort('Read',o.h,1,14));
      currentDiameter=str2double(a(10:end));
      % Warn if different
      while currentDiameter ~= o.diameter
            IOPort('Write', o.h, ['DIA ' num2str(o.diameter) o.commandSeparator],0);
            % Refresh currentDiameter reported by pump
            WaitSecs(0.1);
            IOPort('Write', o.h, ['DIA' o.commandSeparator],0);
            WaitSecs(0.1);
            a=char(IOPort('Read',o.h,1,14));
            currentDiameter=str2double(a(10:end));
      end
      % set pumping rate & units (def: 2900, 'MH')        ['MH'==mL/hour]
      IOPort('Write', o.h, ['RAT ' num2str(o.rate) ' MH ' o.commandSeparator],0);%2900
      % set reward volume & units (def: 0.05, 'ML')
      IOPort('Write', o.h, ['VOL ' num2str(o.volume) ' ' 'ML' o.commandSeparator],0);%0.05
  
    end

    function [err,status] = open(o),
      % query the pump
      [err,status,~] = IOPort('Write', o.h, ['' o.commandSeparator],0);
      assert(err == 0);
      
      % beep once so we know the pump is alive...
      err = o.beep(1);
      assert(err == 0);
    end
    
    function close(o),
      IOPort('close',o.h)
    end
    
    function delete(o),
      try,
        o.close(); % fails if o.dev is invalid or is already closed
      catch
      end
      delete(o.h);
    end
   
    function err = deliver(o,varargin),
        err = 0;
        err = IOPort('Write', o.h, ['RUN' o.commandSeparator],0);  
    end

    function r = report(o),
       r.totalVolume = o.qryvol();
    end
  end % methods

  methods (Access = private)
    function err = setdia(o,d), % set syringe diameter
        err = 0;
      %  IOPort('Write', o.h, ['DIA ' num2str(o.diameter) o.commandSeparator],0);
    end

    function err = setvol(o,d), % set dispensing volume
      % set reward volume & units (def: 0.05, 'ML')
%       o.volume = d;
      err = 0;
     % IOPort('Write', o.h, ['VOL ' num2str(o.volume) ' ' 'ML' o.commandSeparator],0);%0.05
    end

    function err = setrate(o,d), % set dispensing rate
%        o.rate = d; 
       err = 0;
     %  IOPort('Write', o.h, ['RAT ' num2str(o.rate) ' MH ' o.commandSeparator],0);%2900
    end
    
    function err = run(o), % start the pump
       err = 0;
       IOPort('Write', o.h, ['RUN' o.commandSeparator],0);
    end
    
    function err = stop(o), % stop the pump
       err = 0;
    %   IOPort('Write', o.h, ['STP' o.commandSeparator],0);
    end   
    
    function err = clrvol(o,d), % clear dispensed/withdrawn volume
       err = 0;
%        switch d,
%         case 0, % clear infused volume
%           err = IOPort('Write', o.h, ['CLD INF' o.commandSeparator],0);
%         case 1, % clear withdrawn volume
%           err = IOPort('Write', o.h, ['CLD WDR' o.commandSeparator],0);
%         otherwise,
%           warning('MARMOVIEW:NEWERA','Invalid pump direction %i.', d);
%        end
    end
    
    function [infu,wdrn] = qryvol(o), % query dispensed/withdrawn volume
        infu = 0;
        wdrn = 0;
        
        IOPort('Read',o.h); %clear buffer
        IOPort('Write', o.h, ['DIS' o.commandSeparator],0);
        IOPort('Flush',o.h);
        a=[];
        timeout=0.1;
        starttime=GetSecs;
%         tic;
        while isempty(strfind(a,'ML'))&&isempty(strfind(a,'UL'))
            if GetSecs > starttime+timeout
                warning('newEraSyringePump:getVolume','Timed out getting Volume');
                infu = NaN;
                wdrn = NaN;
                return
            end
            WaitSecs(0.001);
            anew=char(IOPort('Read',o.h));
            if ~isempty(anew)
                a=[a anew]; %#ok<AGROW>
                starttime=GetSecs;
            end
        end

        res=regexp(a,'00[SI][I](?<given>\d+.\d+)W(?<withdrawn>\d+.\d+)', 'names');
        if isempty(res)
            res=regexp(a,'00[SI][I](?<given>\d+.)W(?<withdrawn>\d+.\d+)', 'names');
        end
        infu = res.given;
        wdrn = res.withdrawn;
    end
    
    function err = beep(o,n), % sound the buzzer
          err = 0;
          if nargin < 2,
            n = 1;
          end
          cmd = sprintf('BUZ 1 %i',n);
          IOPort('Write', o.h, [cmd o.commandSeparator],0);
    end
    
    function flushin(o),
          IOPort('Flush',o.h);
    end
     
  end % private emethods

end % classdef
