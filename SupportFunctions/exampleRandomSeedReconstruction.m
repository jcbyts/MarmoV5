%% create one stimulus object. reconstruct seed
s = stimuli.stimulus;

s.setRandomSeed();

n = 1e3;
r1 = zeros(n,1);
for i = 1:n
    r1(i) = rand(s.rng);
end
    

s.rng.reset();
r2 = zeros(n,1);
for i = 1:n
    r2(i) = rand(s.rng);
end

figure(1); clf
plot(r1, r2, '.')
if all(r2==r1)
    title('All points perfectly reconstructed')
end

%% create one stimulus object, copy it, reconstruct from copy while continuing with stim


s = stimuli.stimulus;

D = {}; % store trials
nTrials = 3;

for iTrial = 1:nTrials
    
    s.setRandomSeed();

    n = 1e3;
    r1 = zeros(n,1);
    for i = 1:n
        r1(i) = rand(s.rng);
    end
    % copy this instance to store it
    PR.stim = copy(s);
    PR.r = r1;
    
    D{iTrial} = PR;
end


%%
    
iTrial = 3;
s = D{iTrial}.stim;
r1 = D{iTrial}.r;
s.rng.reset();
r2 = zeros(n,1);
for i = 1:n
    r2(i) = rand(s.rng);
end

figure(1); clf
plot(r1, r2, '.')
if all(r2==r1)
    title('All points perfectly reconstructed')
end
