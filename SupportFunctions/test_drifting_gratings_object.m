
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
    'minSF', .5, ...
    'numOctaves', 5, ...
    'pixPerDeg', S.pixPerDeg, ...
    'speeds', 30, ...
    'position', [500 250], ...
    'screenRect', S.screenRect, ...
    'diameter', 50, ...
    'durationOn', 20, ...
    'durationOff', 40, ...
    'isiJitter', 10, ...
    'contrasts', 0.25, ...
    'randomizePhase', true);


%%
grat.beforeTrial()
grat.updateTextures()
%%
t0 = GetSecs;
while GetSecs < t0 +5
grat.afterFrame()
grat.beforeFrame()
% 
Screen('Flip', winPtr, 0);
end



%% close screen if done
sca

