function L_vec_ = split_z(obj)
%%% returns a vector of Msection objects, one for every z value detected within the tiles in obj
unqt = unique([obj.tiles(:).z]);
tiles = obj.tiles;

%parfor_progress(numel(unqt));
% was parfor .... fails on large slabs?
parfor lix = 1:numel(unqt)
    z = unqt(lix);
    indx = find([tiles(:).z]==z);
    t = tiles(indx);
    L_vec_(lix) = Msection(t);
 %   parfor_progress;
end
%parfor_progress(0);