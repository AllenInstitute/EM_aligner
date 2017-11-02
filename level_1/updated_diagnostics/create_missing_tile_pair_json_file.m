function [ number_of_pairs_to_redo, total_possible_pairs, tile_pairs_json_string ] = create_missing_tile_pair_json_file( rc, pm, output_directory, options )
if nargin<4, options = []; end
[zu, sID, ~, ~, ns, ~] = get_section_ids(rc);
num_z = numel(zu);
pairs_to_redo_strings = cell(num_z,1);
all_tiles_to_redo = cell(num_z,1);
pairs_to_redo_count = zeros(num_z,1);
fprintf(['\n' repmat('.',1,num_z) '\n\n']);
opening_json_string = sprintf('{\n "renderParametersUrlTemplate" : "{baseDataUrl}/owner/%s/project/%s/stack/%s/tile/{id}/render-parameters",\n "neighborPairs" : [\n',...
    rc.owner, rc.project, rc.stack);

if ~isfield(options, 'nbrs'), options.nbrs = 0; end
if ~isfield(options, 'min_points'), options.min_points = 3; end
if ~isfield(options, 'max_points'), options.max_points = inf; end
if ~isfield(options, 'filter_point_matches'), options.filter_point_matches = 1; end
if ~isfield(options, 'dir_scratch'), options.dir_scratch = '/scratch/ackermand'; end
if ~isfield(options, 'verbose'), options.verbose = 0; end
if ~isfield(options,'write_file'), options.write_file = true; end

% % configure point-match filter
if ~isfield(options, 'pmopts')
    options.pmopts.NumRandomSamplingsMethod = 'Desired confidence';
    options.pmopts.MaximumRandomSamples = 5000;
    options.pmopts.DesiredConfidence = 99.9;
    options.pmopts.PixelDistanceThreshold = .1;
end
number_of_possible_pairs = zeros(size(zu));
parfor i = 1:numel(zu)
    [T, map_id, tIds, z_val, r, c] = load_all_transformations(rc, zu(i), options.dir_scratch);
    %fprintf('%d \n',zu(i));
    num_tiles = numel(tIds);
    if num_tiles>1 % Make sure that there should be any connected tiles
        tiles_that_should_be_connected = [];
        for current_tile_index=1:num_tiles-1
            for pair_tile_index = current_tile_index+1:num_tiles
                if abs(r(pair_tile_index)-r(current_tile_index)) == 1 %then they should be connected
                    tiles_that_should_be_connected = [tiles_that_should_be_connected; current_tile_index pair_tile_index];
                end
            end
        end
        tiles_that_should_be_connected = sort(tiles_that_should_be_connected,2);
        number_of_possible_pairs(i) = size(tiles_that_should_be_connected,1);
        adj = [];
        if ~isempty(pm) %if pm is empty, then need a list of all tile pairs
            [M, adj, W, np] = system_solve_helper_load_point_matches(zu(i), options,pm, map_id, sID(i), size(T,1), r, c);
            adj = sort(adj,2);
        end
        if ~isempty(adj)
            tile_pairs_to_redo = ~ismember(tiles_that_should_be_connected, adj,'rows');
            adj_to_redo = tiles_that_should_be_connected(tile_pairs_to_redo, :);
        else
           adj_to_redo = tiles_that_should_be_connected; 
        end
        if ~isempty(adj_to_redo)
            section_string = [];
            pairs_to_redo_count(i) = size(adj_to_redo,1);
            count = 0;
            for current_pair = 1:size(adj_to_redo,1)
                neighbor_pairs = [];
                tile_1_index = adj_to_redo(current_pair,1);
                tile_2_index = adj_to_redo(current_pair,2);
                neighbor_pairs.p.groupId = sID{i}{1};
                neighbor_pairs.p.id = tIds{tile_1_index};
                neighbor_pairs.q.groupId = sID{i}{1};
                neighbor_pairs.q.id = tIds{tile_2_index};
                neighbor_pairs_string = [ jsonencode(neighbor_pairs) ',\n'];
                section_string = [section_string neighbor_pairs_string];
                all_tiles_to_redo{i}(count+1) = {neighbor_pairs.p.id};
                all_tiles_to_redo{i}(count+2) = {neighbor_pairs.q.id};
                count=count+2;
            end
            all_tiles_to_redo{i} = unique(all_tiles_to_redo{i});
            pairs_to_redo_strings{i} = section_string;
        end
    end
    fprintf('\b|\n');
end
tile_pairs_json_string = [pairs_to_redo_strings{:}];
tile_pairs_json_string = tile_pairs_json_string(1:end-3);%don't want to include last comma
closing_json_string = ']\n}';
json_string = [opening_json_string tile_pairs_json_string closing_json_string];
if options.write_file
    fid = fopen([output_directory '/tile_pairs_' rc.stack '_z_' sprintf('%6.6d',zu(1)) '_to_' sprintf('%6.6d',zu(end)) '_distance_0.json'],'w');
    fprintf(fid, json_string);
    fclose(fid);
end
number_of_pairs_to_redo = sum(pairs_to_redo_count);
total_possible_pairs = sum(number_of_possible_pairs);
end

