
%% 


M = load('Output/FaceCal_test_030919_17z.mat');
D = ddpiReadFile('Output/FaceCal_test_030919_17.ddpi');

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

