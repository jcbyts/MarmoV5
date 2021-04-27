
%% Open Marmoview screen with parameters from Forage protocol
sca % clear any open windows

[S,P] = Forage2();
A = marmoview.openScreen(S, struct());

winPtr = A.window;
%% Update 
P.snoisediam = inf; % diameter of noise
P.range = 127;

        
grat = stimuli.grating_drifting(winPtr, ...
    'numDirections', 16, ...
    'minSF', 1, ...
    'numOctaves', 3, ...
    'pixPerDeg', S.pixPerDeg, ...
    'speeds', 1, ...
    'position', [500 250], ...
    'screenRect', S.screenRect, ...
    'diameter', 10, ...
    'durationOn', 50, ...
    'durationOff', 40, ...
    'isiJitter', 10, ...
    'contrasts', 0.25, ...
    'randomizePhase', true);


%%
grat.beforeTrial()
grat.updateTextures()
%% run 1
nFrames = 500;
phi = zeros(nFrames,1);
for ctr = 1:nFrames
    grat.afterFrame()
% grat.beforeFrame()
% Screen('Flip', winPtr, 0);
    phi(ctr) = grat.phase;
end
% 

%% run 2
grat.rng.reset();
grat.frameUpdate = 0;
grat.contrast = 0;
grat.phase = 0;

phi2 = zeros(nFrames,1);
for ctr = 1:nFrames
    grat.afterFrame()
    phi2(ctr) = grat.phase;
end

figure(1); clf
plot(phi); hold on
plot(phi2)

%%


t0 = GetSecs;
ctr = 1;
while GetSecs < t0 +5
grat.afterFrame()
grat.beforeFrame()
phi2(ctr) = grat.phase;
ctr = ctr + 1;
% 
Screen('Flip', winPtr, 0);
end
%%
% grat.cpd = 1;
grat.contrast = .5;
% grat.stimValue = 1;
grat.cpd = 1;
grat.phase = 0;
grat.beforeFrame();
Screen('Flip', winPtr, 0);
%% close screen if done
sca

