function [L, map_id, tIds] = load_all_tiles(rc, zu)
% for collection rc, loads all tiles specified by vector zu of z-values
% and returns and Msection object.
options = weboptions;
options.Timeout = 20;
clear t;
tilecount = [];
parfor ix = 1:numel(zu)
    urlChar = sprintf('%s/owner/%s/project/%s/stack/%s/z/%d/tile-specs', ...
        rc.baseURL, rc.owner, rc.project, rc.stack, zu(ix));
    j = webread(urlChar, options);
    jt = tile;
    tilecount(ix) = numel(j);
    for jix = 1:numel(j)
        jt(jix) = tile(j(jix));
        jt(jix).z = zu(ix);
        
    end
    t(ix).jt = jt;
end
ntiles = sum(tilecount);
% concatenate all tile ids
tIds = cell(ntiles,1);
tiles(ntiles) = tile;
cnt = 1;
for ix = 1:numel(zu)
    tIds(cnt:cnt+tilecount(ix)-1) = {t(ix).jt.renderer_id};
    tiles(cnt:cnt+tilecount(ix)-1) = t(ix).jt;
    cnt = cnt + tilecount(ix);
    %     tIds = [tIds {t(ix).jt.renderer_id}];
    %     tiles = [tiles t(ix).jt];
end
clear t;
% loop over tiles to set tile id
for ix = 1:numel(tiles)
    tiles(ix).id = ix;
    tiles(ix).owner = rc.owner;
    tiles(ix).project = rc.project;
    tiles(ix).stack = rc.stack;
end
L = Msection(tiles);
clear tiles;

% map renderer ids to their index position in L
clear count_vec ;
clear id_vec ;

parfor ix = 1:numel(tIds)
    count_vec(ix)= {ix};
    id_vec(ix) = tIds(ix);%tIds{ix};
end
map_id = containers.Map(id_vec, count_vec);