function Lout = update_transformation_from_json(L, fn)
% update canvas transformations in L with values present in fn ( a json
% file as produced from the cpp solver program)
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if exist(fn,'file')
data = loadjson(fn);
del_set = ones(numel(L.tiles),1);

for ix = 1:numel(data)
    cis = L.map_renderer_id(data{ix}.tileId);
    T = str2double(strsplit(data{ix}.transform.dataString, ' '));
    T = T([1 2 5 3 4 6]);
    T(9) = 1;
    L.tiles(cis).tform.T = reshape(T,3,3);
    del_set(cis) = 0;
end
Lout = L;
Lout.tiles(del_set==1) = [];
else
    Lout = [];
    warning('Input file invalid or missing');
end