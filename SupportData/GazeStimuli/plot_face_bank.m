function plot_face_bank(imobase)
%**** plots the entire face bank into one figure
figure();
REPS = 8;
DIRS = 9;
for k = 1:REPS
  for i = 1:DIRS
    subplot(REPS, DIRS, (DIRS*(k-1)+i));
    imagesc(imobase{k,i});
    axis off;
  end
end
%***************************
% for i = 1:9
% figure(1)
% subplot(5, 9, i);
% imagesc(imobase{1,i});
% axis off
% end 
% for i = 1:9
% figure(1)
% subplot(5, 9, 9+i);
% imagesc(imobase{2,i});
% axis off
% end 
% for i = 1:9
% figure(1)
% subplot(5, 9, 18+i);
% imagesc(imobase{3,i});
% axis off
% end 
% for i = 1:9
% figure(1)
% subplot(5, 9, 27+i);
% imagesc(imobase{4,i});
% axis off
% end 
% for i = 1:9
% figure(1)
% subplot(5, 9, 36+i);
% imagesc(imobase{5,i});
% axis off
% end 
end


