function obj = import_from_layout_txt(obj, fn, z)
% Populates an Msection object with tiles based on the classic layout file in fn
% fn: path to a layout file.
% z are layer indices
%
%
% Author: Khaled Khairy. FlyTEM team project. Copyright 2016 Janelia
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fid=fopen(fn,'rt');
if fid==-1
    error('Invalid file');
end

count = 0;
z_curr = 0;
count_vec = {};
id_vec = {};
X = [];
Y = [];
Xo = 0;
Yo = 0;
while z_curr<=z && ~feof(fid)
    
    l=fgetl(fid); % get a line
    C = strsplit(l,'\t');
    z_curr = str2double(C{1});
   
    if z_curr==z,
        
        count = count + 1;
        t(count) = tile(str2double(C{1}), str2double(C{2}), str2double(C{3}), str2double(C{4}), ...
            str2double(C{5})-Xo, str2double(C{6}), str2double(C{7}), str2double(C{8})-Yo, str2double(C{9}), ...
            str2double(C{10}), str2double(C{11}), C{12});
        t(count).fetch_local = 1;
        t(count).renderer_id = num2str(count);
        id_vec{count} = str2double(C{2});
        count_vec{count} = count;
        X(count) = str2double(C{5});
        Y(count) = str2double(C{8});
        
    end
end
fclose(fid);

%%%%%%%% 
if  count>2
    obj.tiles = t;
    obj.X = X;
    obj.Y = Y;
    obj.z = z;
    obj.original_layout_file = fn;
else
    error('No tiles found in file');
end













