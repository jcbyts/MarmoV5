
%% Parameters of my arduino
s = struct('port', '/dev/cu.usbmodem1412401');
s.BaudRate = 115200; %9600;

numFrames = 10e3; % how many frames to use when evaluating latency

%% Use arduino toolbox
channelA = 'D3';
channelB = 'D2';

handle = arduino(s.port, 'Uno', 'Libraries', 'rotaryEncoder');
encoder = rotaryEncoder(handle, channelA, channelB);

% Calculate time per call
timeA = zeros(numFrames,1);
for i = 1:numFrames
tic
cnt = readCount(encoder); % this is the main call
timeA(i) = toc;
end

figure(1); clf
set(gcf, 'Color', 'w')
histogram(timeA*1e3)
xlabel('Time per call (ms)')

mci = bootci(1e3, @median, timeA*1e3);
md = median(timeA*1e3);

fprintf('Median Duration Arduino Toolbox = %02.2f [%02.2f, %02.2f] ms\n', md, mci)

% close up the arduino
clear handle

%% Approach 2

% Open arduino
config=sprintf('BaudRate=%d ReceiveTimeout=.1', s.BaudRate);
[handle, errMsg] = IOPort('OpenSerialPort', s.port, config);

%% Calculate time per call
timeB = zeros(numFrames,1);
timestamps = nan(numFrames,1);
counts = nan(numFrames,1);

for i = 1:numFrames
tic
% read call
msg = IOPort('Read', handle); % read from buffer

% parse message
a = regexp(char(msg), 'time:(?<time>\d+)|count:(?<count>\d+)', 'names');
if ~isempty(a)
    % take last sample
    tim = arrayfun(@(x) str2double(x.time), a);
    cou = arrayfun(@(x) str2double(x.count), a);
    
    counts(i) = nanmean(tim);
    timestamps(i) = nanmean(cou);
    fprintf('%d success\n', i)
else
    fprintf('%d empty message\n', i)
end
timeB(i) = toc; % time elapsed
WaitSecs(0.002); % other stuff happening in frame loop (necessary for buffer to fill up)
end

figure(1); clf
set(gcf, 'Color', 'w')
histogram(timeB*1e3)
xlabel('Time per call (ms)')

mci = bootci(1e3, @median, timeB*1e3);
md = median(timeB*1e3);

fprintf('Median Duration IOPort = %02.2f [%02.2f, %02.2f] ms\n', md, mci)

%% Close
IOPort('Close', handle)

%%



%%
tread = marmoview.treadmill_arduino('port', s.port, 'baud', s.BaudRate);

tread.reset(); % reset counter

%% tun trial
tread.reset() % reset counter

timeB = zeros(numFrames,1);

for i = 1:numFrames
    tic
    % main frame loop call
    rewstate = tread.afterFrame(i, 0);
    timeB(i) = toc;
%     fprintf('frame: %d [%2.2fms]\n', tread.frameCounter, t*1e3)
end

figure(1); clf, 
plot(tread.locationSpace(1:tread.frameCounter,:), '-o')
legend({'frame', 'arduino clock', 'raw counter', 'scaled counter', 'reward state'})

%% close
tread.close()


%%

