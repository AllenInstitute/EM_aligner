function obj = import_from_X_A_TXT_txt(obj, fn, z)
%% fn is the full path to a X_A_TXT file.

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

while  ~feof(fid)
    
    l=fgetl(fid); % get a line
    C = strsplit(l,'\t');
    z_curr = str2double(C{1});

        count = count + 1;

        t(count) = tile(z, str2double(C{1}), str2double(C{3}), str2double(C{4}), ...
            str2double(C{5}), str2double(C{6}), str2double(C{7}), str2double(C{8}),...
            -999, -999, -999,'---',-999,0,-999);
        id_vec{count} = str2double(C{2});
        count_vec{count} = count;
        X(count) = str2double(C{5});
        Y(count) = str2double(C{8});
end
fclose(fid);
if  count<2
    error('No tiles found in file');
else
    obj.tiles = t;
end













