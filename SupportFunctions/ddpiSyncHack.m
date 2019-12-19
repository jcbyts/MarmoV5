
%% 
fname = 'Acuity_Logan_300919_00';
% fname = 'BackImage_Artificial_240919_05';
M = load(fullfile('Output', [fname 'z.mat']));
D = ddpiReadFile(fullfile('Output', [fname '.ddpi']));

messageIx = D(1,:) ==1;
ddpiWords = D(end,messageIx);
ddpiTimestamps = D(2,messageIx);

nTrials = numel(M.D);
marmoTimestamps = [];
marmoWords = [];

for iTrial = 1:nTrials
    
    startTime = M.D{iTrial}.STARTCLOCKTIME;
    stopTime = M.D{iTrial}.ENDCLOCKTIME;
    
    startWord = str2double(sprintf('%02d', M.D{iTrial}.STARTCLOCK));
    stopWord = str2double(sprintf('%02d', M.D{iTrial}.ENDCLOCK));
    
    marmoTimestamps = [marmoTimestamps; startTime; stopTime];
    marmoWords = [marmoWords; startWord; stopWord];
end

latencies = D(end,D(1,:)==2);

%%

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

d2m = [ddpiTs(:) ones(sum(goodIndex),1)]\marmTs(:);
ddpi2marmo = @(x) x*d2m(1) + d2m(2);

%%
figure(1); clf
plot(ddpiTs, marmTs, '.'); hold on
plot(ddpiTs, ddpi2marmo(ddpiTs))

figure(2); clf
plot( marmTs - ddpi2marmo(ddpiTs'), '.')

%%

validix = D(1,:)==0;
D = D(:,validix);
dstruct.time = ddpi2marmo(D(2,:)');
dstruct.p1x = D(3,:)';
dstruct.p1y = D(4,:)';
dstruct.p4x = D(7,:)';
dstruct.p4y = D(8,:)';
dstruct.gazex = dstruct.p4x - dstruct.p1x;
dstruct.gazey = dstruct.p4y - dstruct.p1y;
% for iTrial = 1:numel(M.D)
%     trialIndex = dstruct.time(:) > M.D{iTrial}.eyeData(1,1) & dstruct.time < M.D{iTrial}.eyeData(end-1,1);
%     dstruct.gazex(trialIndex) = (dstruct.gazex(trialIndex) - M.D{iTrial}.c(1)) * M.D{iTrial}.dx;
%     dstruct.gazey(trialIndex) = (dstruct.gazey(trialIndex) - M.D{iTrial}.c(2)) * M.D{iTrial}.dy;
% end



% 
mstruct.time = cell2mat(cellfun(@(x) x.eyeData(:,1), M.D, 'uni', 0));
mstruct.gazex = cell2mat(cellfun(@(x) x.eyeData(:,2), M.D, 'uni', 0));
mstruct.gazey = cell2mat(cellfun(@(x) x.eyeData(:,3), M.D, 'uni', 0));

mstruct.time = (mstruct.time - dstruct.time(1))*1e3;
dstruct.time = (dstruct.time - dstruct.time(1))*1e3;


figure(1); clf
plot(dstruct.time, dstruct.gazex, '.')
hold on
plot(mstruct.time, mstruct.gazex, 'o')

%%
nTimestamps = numel(mstruct.time);
latency = nan(nTimestamps, 1);
for i = 1:nTimestamps
    [~, id] = min(abs(dstruct.time - mstruct.time(i)));
    inds = id + (-20:1);
    inds(inds < 1) = [];
    thisSample = inds(dstruct.gazex(inds) == mstruct.gazex(i));
    if isempty(thisSample)
        continue
    end
    latency(i) = mstruct.time(i) - dstruct.time(thisSample(end));
end

figure(2); clf
histogram(latency)
xlabel('ddpi latency (ms)')


%%

dstruct.time = ddpi2marmo(D(2,:)');
dstruct.p1x = D(3,:)';
dstruct.p1y = D(4,:)';
dstruct.p4x = D(7,:)';
dstruct.p4y = D(8,:)';
dstruct.gazex = dstruct.p4x- dstruct.p1x;
dstruct.gazey = -(dstruct.p4y - dstruct.p1y);

cx = cellfun(@(x) x.c(1), M.D);
cy = cellfun(@(x) x.c(2), M.D);
dx = cellfun(@(x) x.dx, M.D);
dy = cellfun(@(x) x.dy, M.D);

iTrial = 0
%%
figure(1); clf
iTrial = 1; %iTrial + 1;

ppd = M.S.pixPerDeg;
tdx = median(dx);
tdy = median(dy);
tcx = median(cx);
tcy = median(cy);



t0 = M.D{iTrial}.STARTCLOCKTIME;
t1 = M.D{iTrial}.ENDCLOCKTIME;
idx = dstruct.time > t0 & dstruct.time < t1;

gazex = (dstruct.gazex(idx)-tcx)./(tdx*ppd);
gazey = (dstruct.gazey(idx)-tcy)./(tdy*ppd);
gazex = sgolayfilt(gazex, 1, 5);
hold off
plot(dstruct.time(idx) - t0, gazex, '-'); hold on
plot(dstruct.time(idx) - t0, gazey, '-')
ylim([-1 1])
ylabel('degrees')
xlabel('time (sec)')

%%
figure(1); clf
t = dstruct.time(idx) - t0;
iix = t > .3 & t < .4;
plot3(t(iix), gazex(iix), gazey(iix), '-o')

%%
gazex = (dstruct.gazex-tcx)./(tdx*ppd);
gazey = (dstruct.gazey-tcy)./(tdy*ppd);

clf
% plot(sqrt(gazex.^2 + gazey.^2))

idx = 1:numel(gazex);
% idx = 4e3:10e3;
t = dstruct.time(idx) - t0;

% x = (gazex(idx)-mean(gazex(idx)))*(60/0.74);
x = ( (gazex(idx)-nanmean(gazex(idx)))*60);
y = ( (gazey(idx)-nanmean(gazey(idx)))*60);
rms(x)
toff = 0;
plot(t*1e3 - toff, x); hold on
plot(t*1e3 - toff, y)
ylabel('arcmin')
xlabel('ms')

% plot(xcorr(x, 100, 'unbiased'))

% save('artificial_eye_1deg_09242019.mat', 'dstruct', 'gazex', 'gazey')
%%
% M.D{1}
%  double time;
%         double p1x;
%         double p1y;
%         double p1r;
%         double p1I;
%         double p4x;
%         double p4y;
%         double p4r;
%         double p4I;
%         double p4score;
%         double tag;
%         double message;

