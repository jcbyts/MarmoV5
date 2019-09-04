function Output = ddpiReadFile(fname)
% Output = ddpiReadFile(fname)
fid = fopen(fname);
fseek(fid, 0, 'eof');
filesize = ftell(fid);
fseek(fid, 0, 'bof');


buffersize = [13 filesize/8/13];
Output = fread(fid, buffersize, '*double');

%     double signalType;
%         double time;
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
%     };