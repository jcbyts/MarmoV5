function ima = myrotate(imo,angle)

ima = imrotate(imo,angle,'bilinear');
z = find(ima == 0);
ima(z) = 127;

figure(2);
imagesc(ima);

return;