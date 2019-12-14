
%% Open Marmoview screen with parameters from Forage protocol
sca % clear any open windows

[S,P] = Forage2();
A = marmoview.openScreen(S, struct());


%% Update 
P.snoisediam = inf; % diameter of noise
P.range = 127;

% create two versions of the same grating
gratpro = stimuli.grating_procedural(winPtr);
grat = stimuli.grating(winPtr);

% set paramters
cpd = 5;
ori = 30;
phi = 180;
gauss = true;


% match the two gratings
grat.screenRect = S.screenRect;
gratpro.screenRect = S.screenRect;
gratpro.radius = round((P.snoisediam/2)*S.pixPerDeg);
grat.radius = round((P.snoisediam/2)*S.pixPerDeg);


gratpro.phase = phi; % black
grat.phase = phi;  % black
grat.orientation = ori; % cpd will be zero => all one color
gratpro.orientation = ori; % cpd will be zero => all one color
grat.cpd = cpd; % when cpd is zero, you get a Gauss
gratpro.cpd = cpd; % when cpd is zero, you get a Gauss

grat.range = P.range;
grat.square = false; % true;  % if you want circle
grat.gauss = gauss;
grat.bkgd = P.bkgd;
grat.transparent = 0.5;
grat.pixperdeg = S.pixPerDeg;


gratpro.range = P.range;
gratpro.square = false; % true;  % if you want circle
gratpro.gauss = gauss;
gratpro.bkgd = P.bkgd;
gratpro.transparent = .5;
gratpro.pixperdeg = S.pixPerDeg;


grat.updateTextures();
gratpro.updateTextures();

grat.position = [700 360];
gratpro.position = [700 460];

grat.drawGrating()
gratpro.drawGrating();
% 
rect = CenterRectOnPointd([0 0 gratpro.pixperdeg gratpro.pixperdeg]*P.snoisediam, gratpro.position(1), gratpro.position(2));
rect([2 4]) = rect([2 4]) + gratpro.pixperdeg*3;
Screen('FillRect', winPtr, 0, rect);

Screen('Flip', winPtr, 0);


%% test gratpro fast
t0 = GetSecs;
while GetSecs < t0 +5
    if rand < .5
        Screen('FillRect', winPtr, 127);
    gratpro.orientation = rand*360;
    gratpro.drawGrating();
    end
    
    
    %
    rect = CenterRectOnPointd([0 0 gratpro.pixperdeg gratpro.pixperdeg]*P.snoisediam, gratpro.position(1), gratpro.position(2));
    rect([2 4]) = rect([2 4]) + gratpro.pixperdeg*3;
    Screen('FillRect', winPtr, 0, rect);
    
    Screen('Flip', winPtr, 0, 2);
    Screen('FillRect', winPtr, 127);
%     Screen('Flip', winPtr, 127);
end
%% close textures
grat.CloseUp
gratpro.CloseUp

%% close screen if done
sca

