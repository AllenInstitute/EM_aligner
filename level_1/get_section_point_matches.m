function L = get_section_point_matches(rcsource, z, dir_scratch, opts, pm)
%%%% load all available point-matches for this section
[zu, sID, sectionId, z, ns] = get_section_ids(rcsource,...
    z, z);
[T, map_id, tIds, z_val, r, c] = load_all_transformations(rcsource,...
    zu, dir_scratch);

[M, adj, W, np] = system_solve_helper_load_point_matches(...
    zu, opts, pm, map_id,  sID, size(T,1), r, c);

%%% generate a subset of tiles that have point-matches
t_ix = unique(adj); % valid tiles are only the ones connected by point-matches
ntiles = numel(t_ix);
disp('----- Removing number of orphan tiles based on point-matches ----');
disp(size(T,1)-ntiles);
disp('------------------------------------------');
tiles = tile;tiles(ntiles) = tile; % start a tile array
a = [];
for tix = 1:ntiles    %%%% construct a tile array based on valid tiles
    t = T(t_ix(tix),:);
    tiles(tix) = tile(z_val(t_ix(tix)), tix,...
        t(1), t(2), t(3), t(4), t(5), t(6),...
        -999, -999, -999, '', -999, -999, tIds{t_ix(tix)});
    counter_id{tix} = {tix};
    tiles(tix).id = tix;
    id_vec{tix} = tiles(tix).renderer_id;
    tiles(tix).server = rcsource.baseURL;
    tiles(tix).owner = rcsource.owner;
    tiles(tix).project = rcsource.project;
    tiles(tix).stack = rcsource.stack;
    tiles(tix) = set_info(tiles(tix));
end
map_id_new = containers.Map(id_vec, counter_id);  %%% map renderer ids to indices of valid array

%%% generate correct indexing: map old indices to new indices using renderer_id
for aix = 1:size(adj,1)
    rid_old1 = map_id_new(tIds{adj(aix,1)}); % get index of same renderer_id but in new set
    rid_old2 = map_id_new(tIds{adj(aix,2)});
    a(aix,:) = [rid_old1{1} rid_old2{1}];
end
adj = a;



PM.M = M;
PM.adj = adj;
PM.W = W;
PM.np = np;
L = Msection(tiles);
L.pm = PM;