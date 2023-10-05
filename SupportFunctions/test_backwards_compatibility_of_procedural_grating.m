
%% Open Marmoview screen with parameters from Forage protocol
sca % clear any open windows

[S,P] = Forage2();
A = marmoview.openScreen(S, struct());

winPtr = A.window;
%% Update 
P.snoisediam = inf; % diameter of noise
P.range = 127;

% create two versions of the same grating
gratpro = stimuli.grating_procedural(winPtr);
grat = stimuli.grating(winPtr);

% set paramters
cpd = 1;
ori = 0;
phi = 180;
gauss = true;

%%
P.snoisediam = inf;
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

grat.position = [400 260];
gratpro.position = [400 360];
%%
% grat.orientation = 0;
% grat.drawGrating()
gratpro.transparent = .05;
gratpro.orientation = 90;
gratpro.phase = gratpro.phase - 30;
gratpro.drawGrating();

% 

rect = CenterRectOnPointd([0 0 gratpro.pixperdeg gratpro.pixperdeg]*P.snoisediam, gratpro.position(1), gratpro.position(2));
% rect([2 4]) = rect([2 4]) + gratpro.pixperdeg*3;
% Screen('FillRect', winPtr, 0, rect);
% 
Screen('Flip', winPtr, 0);


%% test gratpro fast
t0 = GetSecs;
while GetSecs < t0 +5
    if rand < .25
        Screen('FillRect', winPtr, 127);
        gratpro.orientation = rand*360;
        
    end
    
    gratpro.drawGrating();
    
    %
    rect = CenterRectOnPointd([0 0 gratpro.pixperdeg gratpro.pixperdeg]*P.snoisediam, gratpro.position(1), gratpro.position(2));
    rect([2 4]) = rect([2 4]) + gratpro.pixperdeg*3;
    Screen('FillRect', winPtr, 0, rect);
    
    Screen('Flip', winPtr, 0, 2);
    Screen('FillRect', winPtr, 127);
%     Screen('Flip', winPtr, 127);
end

%% test grat pro reconstruction
gratpro.position = [500 504];
gratpro.phase = 180;
gratpro.gauss = false;
gratpro.orientation = gratpro.orientation + 1;
gratpro.drawGrating();
Screen('Flip', winPtr);
rect = [0 0 1270 720];
% rect = CenterRectOnPointd([0 0 gratpro.pixperdeg gratpro.pixperdeg]*P.snoisediam, gratpro.position(1), gratpro.position(2));
% rect = round(rect);
%
% gratpro.phase = 186+3;
I = gratpro.getImage(rect, 1);

I1 = Screen('GetImage', winPtr, rect);
I1 = mean(I1, 3);
figure(1); clf;
subplot(1,3,1)
imagesc(I)
subplot(1,3,2)
imagesc(I1)
subplot(1,3,3)
imagesc(I1 - I, [-10 10])




%% close textures
grat.CloseUp
gratpro.CloseUp

%% close screen if done
sca

