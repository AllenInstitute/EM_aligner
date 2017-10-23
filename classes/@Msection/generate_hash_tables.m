function obj = generate_hash_tables(obj)
%%% generate the hash tables
count_vec = {};
id_vec = {};
for ix = 1:numel(obj.tiles)
    count_vec{ix} = ix;
    id_vec{ix} = obj.tiles(ix).id;
end
obj.map_id = containers.Map(id_vec, count_vec);

%%% generate the tileId hash tables
count_vec = {};
id_vec = {};
for ix = 1:numel(obj.tiles)
    count_vec{ix} = ix;
    id_vec{ix} = obj.tiles(ix).renderer_id;
end
obj.map_renderer_id = containers.Map(id_vec, count_vec);