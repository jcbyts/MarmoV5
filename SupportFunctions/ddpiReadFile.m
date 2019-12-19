function Output = ddpiReadFile(fname)
% Output = ddpiReadFile(fname)
% 1) signalType;
% 2) time;
% 3) p1x;
% 4) p1y;
% 5) p1r;
% 6) p1I;
% 7) p4x;
% 8) p4y;
% 9) p4r;
% 10) p4I;
% 11) p4score;
% 12) tag;
% 13) message;
fid = fopen(fname);
fseek(fid, 0, 'eof');
filesize = ftell(fid);
fseek(fid, 0, 'bof');


buffersize = [13 filesize/8/13];
Output = fread(fid, buffersize, '*double');

