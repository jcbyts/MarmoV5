function plot_face_bank(imobase)
%**** plots the entire face bank into one figure
figure;
REPS = 2;
DIRS = 9;
for k = 2:DIRS
  imagesc(imobase{1,1});
  axis off;
  input(sprintf('hit key, direction %d',k));
  imagesc(imobase{1,1});
  axis off;
  input('hit key');
  hold off;
  imagesc(imobase{1,k});
  axis off;
  input('hit key');
  imagesc(imobase{2,k});
  axis off;
  input('hit key');
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


