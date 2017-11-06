function  tIds_removed  = system_solve_helper_tile_filter( rcin, rcout, zs, opts, pm )
%% Filter out disconnected tile from rcin in new collection rcout
%   Function takes input collection rcin, ouptut collection, zs, opts and
%   pm. It will then filter rcin tiles over the z values zs and remove 
%   disconnected tiles (unless they are part of sections containing 1 or 2 tiles.
%   ingesting the filtered collection into rcout.

% Get section information
if isempty(zs)
    [zu, sID, sectionId, z, ns] = get_section_ids(rcin);
else
    [zu, sID, sectionId, z, ns] = get_section_ids(rcin, zs(1), zs(end));
end

% load transformations and find tiles that are in sections containing
% 1 or 2 tiles. These will be included in the final collection regardless
% of whether they are connected via pm
[T, map_id, tIds, z_val] = load_all_transformations(rcin, zu, opts.dir_scratch);
[tile_count_per_section, section_zs] = hist(z_val,unique(z_val));
small_section_zs = section_zs(tile_count_per_section <=2); % this will be the small section zs
tile_indices_in_small_sections = find(ismember(z_val,small_section_zs));

% Load point matches
opts.nbrs = 0; % so will be removed if it is isolated
opts.outside_group = 0; % make sure loading is fast for montages
[M, adj, W, np, discard] = system_solve_helper_load_point_matches(zu, opts, pm, map_id, sID, size(T,1));

% The final tiles that will be included in rcout are those which are
% connected via pm (unique(adj)) or which are part of single- or two-tile
% sections (tile_indices_in_small_sections)
valid_indices = unique([unique(adj);tile_indices_in_small_sections]);
indices_removed = ~ismember(1:numel(tIds),valid_indices);
% these are the removed tiles:
tIds_removed = tIds(indices_removed);

% Ingest valid tiles into rcout
system_solve_helper_ingest_into_renderer_database(rcin, rcout, T(valid_indices,:), tIds(valid_indices), z_val(valid_indices), opts, unique(z_val(valid_indices)));

end

