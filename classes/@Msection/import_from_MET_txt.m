function obj = import_from_MET_txt(obj, fn, z)
%% fn is the full path to a MET file.
%%% z is t
try
fid=fopen(fn,'rt');
if fid==-1
    error('Invalid file');
end

count = 0;
z_curr = obj.z;
count_vec = {};
id_vec = {};
X = [];
Y = [];
Xo = 0;
Yo = 0;
while ~feof(fid)
    count = count + 1;
    l=fgetl(fid); % get a line
    C = strsplit(l,'\t');
    % we need Xo and Yo to translate all of the tiles relative to the first tile
%     if count==1,
%         Xo = str2double(C{5});
%         Yo = str2double(C{8});
%     end


% Note: tile instantiation looks like this:
%     tile(z, id, t1, t2, t3, t4, t5, t6, col, row, cam, path, temca_conf, rotation)
                
if numel(C)==14,        % then use the new style
    t(count) = tile(str2double(C{1}), str2double(C{2}), str2double(C{4}), str2double(C{5}), ...
        str2double(C{6})-Xo, str2double(C{7}), str2double(C{8}), str2double(C{9})-Yo, str2double(C{10}), ...
        str2double(C{11}), str2double(C{12}), C{13}, 0);
    
else        % use the old style
    t(count) = tile(z_curr, str2double(C{1}), str2double(C{3}), str2double(C{4}), ...
        str2double(C{5})-Xo, str2double(C{6}), str2double(C{7}), str2double(C{8})-Yo, str2double(C{9}), ...
        str2double(C{10}), str2double(C{11}), C{12}, -999, 0);
 end   
    
 id_vec{count} = str2double(C{2});
 count_vec{count} = count;
 X(count) = str2double(C{5});
 Y(count) = str2double(C{8});
 
 
 
end
fclose(fid);


if  count>2
    obj.tiles = t;
    obj.X = X;
    obj.Y = Y;
    obj.z = z;
    obj.original_layout_file = fn;
    obj.map_id = containers.Map(id_vec, count_vec);     % generate a hash table with id's as the keys
    %%% calculate distance matrix
    
    %%% assuming all tiles of equal size
    obj.tiles(1) = set_info(obj.tiles(1));
    H = obj.tiles(1).H;
    W = obj.tiles(1).W;
    
    obj.X = obj.X + W/2;
    obj.Y = obj.Y + H/2;
    
    a = [X(:)+W/2 Y(:)+H/2];
    d = pdist2(a,a);
    dthresh = sqrt(H^2 + W^2) * obj.dthresh_factor;   % diagonal of the tile
    obj.A = sparse(triu(d<dthresh,1));
else
    error('No tiles found in file');
end
catch met_import_err
    disp(met_import_err);
end













