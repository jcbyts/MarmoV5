
%% find all files from a particular session
subject = 'test';
date = '271219';
dataDir = '/home/marmorig/Documents/MATLAB/MarmoV5/Output';

% find all files for subject and date
sf = dir(fullfile(dataDir, ['*', subject '*.ddpi']));
df = dir(fullfile(dataDir, ['*_' date '_*.ddpi']));
sfname = arrayfun(@(x) x.name, sf, 'uni', 0);
dfname = arrayfun(@(x) x.name, df, 'uni', 0);

% find the intersection (both correct date and correct subject)
ddpiFiles = intersect(sfname, dfname);

nFilePairs = numel(ddpiFiles);

% initialize variables
marmoWords = [];
marmoTimestamps = [];
ddpiWords = [];
ddpiTimestamps = [];
latencies = [];

dstruct = struct('time', [], ...
    'p1x', [], ...
    'p1y', [], ...
    'p4x', [], ...
    'p4y', [], ...
    'gazex', [], ...
    'gazey', []);

mstruct = struct('time', [], ...
    'gazex', [], ...
    'gazey', []);

% loop over files and extract times / data
for iFile = 1:nFilePairs
   ddpiFile = fullfile(dataDir, ddpiFiles{iFile});
   mvFile = fullfile(dataDir, strrep(ddpiFiles{iFile}, '.ddpi', 'z.mat'));
   
   D = ddpiReadFile(ddpiFile); % ddpi file read
   M = load(mvFile); % marmoview file
   
   messageIx = D(1,:) ==1;
   ddpiWords = [ddpiWords; D(end,messageIx)'];
   ddpiTimestamps = [ddpiTimestamps; D(2,messageIx)'];
   
   % loop over marmoview trials and extract the timestamps
   nTrials = numel(M.D);

   for iTrial = 1:nTrials
       
       startTime = M.D{iTrial}.STARTCLOCKTIME;
       stopTime = M.D{iTrial}.ENDCLOCKTIME;
       
       startWord = str2double(sprintf('%02d', M.D{iTrial}.STARTCLOCK));
       stopWord = str2double(sprintf('%02d', M.D{iTrial}.ENDCLOCK));
       
       marmoTimestamps = [marmoTimestamps; startTime; stopTime]; %#ok<*AGROW>
       marmoWords = [marmoWords; startWord; stopWord];
   end
   
   latencies = [latencies; D(end,D(1,:)==2)']; 
   
   % save D
   validix = D(1,:)==0;
   D = D(:,validix);
   dstruct.time = [dstruct.time; D(2,:)'];
   dstruct.p1x = [dstruct.p1x; D(3,:)'];
   dstruct.p1y = [dstruct.p1y; D(4,:)'];
   dstruct.p4x = [dstruct.p4x; D(7,:)'];
   dstruct.p4y = [dstruct.p4y; D(8,:)'];
   dstruct.gazex = dstruct.p4x - dstruct.p1x;
   dstruct.gazey = dstruct.p4y - dstruct.p1y;
   
   % save marmoview data
   mstruct.time = [mstruct.time; cell2mat(cellfun(@(x) x.eyeData(:,1), M.D, 'uni', 0))];
   mstruct.gazex = [mstruct.gazex; cell2mat(cellfun(@(x) x.eyeData(:,2), M.D, 'uni', 0))];
   mstruct.gazey = [mstruct.gazey; cell2mat(cellfun(@(x) x.eyeData(:,3), M.D, 'uni', 0))];
   
end

ddpiTimestamps = ddpiTimestamps/1e3; % convert to seconds (double check this)
dstruct.time = dstruct.time / 1e3;

% synchronize clocks by matching words and regressing timestamps


fprintf('Found %d ddpiWords and %d marmoview words\n', numel(ddpiWords), numel(marmoWords))

[~, hind] = ismember(ddpiWords, marmoWords);
if any(hind==0)
    warning('syncDdpiClock: some words were missed')
end

goodIndex = hind~=0;
hind(hind==0) = [];
ddpiTs = ddpiTimestamps(hind);
ddpiW = ddpiWords(hind);
marmTs = marmoTimestamps(goodIndex);

% 1) assume a slope of one and fit the best offset.
b = mean(marmTs - ddpiTs);

% 2) throw out outliers and fit slope
outliers = abs(zscore(marmTs - (ddpiTs + b))) > 3;
fprintf('removing %d outliers\n', sum(outliers))

ddpiTs(outliers) = [];
marmTs(outliers) = [];

d2m = [ddpiTs(:) ones(numel(marmTs),1)]\marmTs(:);
ddpi2marmo = @(x) x*d2m(1) + d2m(2);

% 3) throw out outliers and fit slope again
outliers = abs(zscore(marmTs - ddpi2marmo(ddpiTs))) > 3;
fprintf('removing %d outliers\n', sum(outliers))

ddpiTs(outliers) = [];
marmTs(outliers) = [];

d2m = [ddpiTs(:) ones(numel(marmTs),1)]\marmTs(:);
ddpi2marmo = @(x) x*d2m(1) + d2m(2);

figure(1); clf
subplot(1,3,1)
histogram(latencies, 'EdgeColor', 'none', 'FaceColor', .2*[1 1 1])
xlabel('ms')
ylabel('count')
title('DDPI latency')

subplot(1,3,2)
plot(ddpiTs, marmTs, '.')
hold on
plot(ddpiTs, ddpi2marmo(ddpiTs))
xlabel('DDPI time (sec)')
ylabel('MarmoView time (sec)')

subplot(1,3,3)
plot(marmTs - ddpi2marmo(ddpiTs), '.')

averr = mean(abs(marmTs - ddpi2marmo(ddpiTs)));
fprintf('Average error: %f\n', averr)

dstruct.time = ddpi2marmo(dstruct.time);

% figure(1); clf
% histor

%% plot outcome

figure(1); clf
plot(dstruct.time, dstruct.gazex, '.-'); hold on
plot(mstruct.time, mstruct.gazex, '.-')

% %% check actual latency (including any overhead from marmoview)
% nTimestamps = numel(mstruct.time);
% totallatency = nan(nTimestamps, 1);
% % loop over all timestamps in marmoview
% for i = 1:nTimestamps
%     
%     if isnan(mstruct.time(i))
%         continue
%     end
%     
%     % find the corresponding sample in the ddpi
%     tdiff = dstruct.time - mstruct.time(i);
%     id = find(tdiff <= 0, 1, 'last'); % find the last sample less than zero
%     
%     inds = id + (-20:0);
%     inds(inds < 1) = [];
%     thisSample = inds(dstruct.gazex(inds) == mstruct.gazex(i));
%     if isempty(thisSample)
%         continue
%     end
%     totallatency(i) = mstruct.time(i) - dstruct.time(thisSample(end));
% end
% 
% figure(2); clf
% histogram(totallatency*1e3)
% xlabel('ddpi latency (ms)')
% title('Total Latency (including MarmoView)')
% ylabel('Count')

%%

figure(1); clf

cx = cellfun(@(x) x.c(1), M.D);
cy = cellfun(@(x) x.c(2), M.D);
dx = cellfun(@(x) x.dx, M.D);
dy = cellfun(@(x) x.dy, M.D);

ppd = M.S.pixPerDeg;
tdx = median(dx);
tdy = median(dy);
tcx = median(cx);
tcy = median(cy);

t0 = dstruct.time(1);
gazex = (dstruct.gazex-tcx)./(tdx*ppd);
gazey = (dstruct.gazey-tcy)./(tdy*ppd);

gazex = gazex - nanmedian(gazex);
gazey = gazey - nanmedian(gazey);
% % % scale
gazex = gazex * (60);
gazey = gazey * (60);
gazex = sgolayfilt(gazex, 3, 7);
gazey = sgolayfilt(gazey, 3, 7);
idx = 1:numel(gazex);
t = dstruct.time - t0;
plot(gazex, '-', 'MarkerSize', 2); hold on
% plot(t, gazey)
xlabel('Time (sec)')
ylabel('Arcmin')
% 

%%
win = [101.2 101.8];
ix = t > win(1) & t < win(2);
figure(1); clf
plot(gazex(ix) - mean(gazex(ix)))
% spectrogram(gazex(ix) - mean(gazex(ix)), [], [], [], 540)
% return
%%
clf
% idx = 1:10e3;
t = dstruct.time(idx) - t0;


x0 = nanmean(gazex(idx));
y0 = nanmean(gazey(idx));
% x0 = 0;
% y0=0;
% x = (gazex(idx)-mean(gazex(idx)))*(60/0.74);
x = ( (gazex(idx)-x0)*60);
y = ( (gazey(idx)-y0)*60);
z = hypot(x,y);
fprintf('RMS error x: %02.5f\n', rms(x))
fprintf('RMS error y: %02.5f\n', rms(y))
fprintf('RMS error norm(xy): %02.5f\n', rms(z));
toff = 0;
plot(t*1e3 - toff, x); hold on
plot(t*1e3 - toff, y)
ylabel('arcmin')
xlabel('ms')
legend({'x', 'y'})

%%
p1x = dstruct.p1x;
p1xf = imgaussfilt(p1x, 10);
figure(1); clf
plot(p1x); hold on
plot(p1xf)