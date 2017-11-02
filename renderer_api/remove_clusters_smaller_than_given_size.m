function [ did_replace_sections ] = remove_clusters_smaller_than_given_size( rc_target, rc_section_source, rc_base, pm, input_zs, min_tiles, dir_scratch, verbose)
% Removes clusters smaller than given size from rc_section_source, placing
% the resulting section in rc_target. If rc_target and rc_section_source
% are the same then the clusters are removed from the given collection.
% inputs: 
%       rc_target: target collection
%       rc_section_source: source collection for the sections
%       rc_base: base collection
%       pm: point match collection
%       input_zs: z values to remove clusters from
%       min_tles: all clusters less than or equal to min_tiles size are removed
%       dir_scratch: scratch directory
%       verbose: whether to print out progress
% output:
%       did_replace_sections: boolean vector displaying whether or not
%                             sections were changed

% Ensure collections exist
if ~stack_exists(rc_target), error('Target collection does not exist'); end
if ~stack_exists(rc_section_source), error('Source collection does not exist'); end
if ~stack_exists(rc_base), error('Base collection does not exist'); end

if nargin<8, verbose = false; end

% Initialize output vector and make sure target is in loading state
did_replace_sections = zeros(numel(input_zs),2);
did_replace_sections(:,1) = input_zs;
if stack_complete(rc_target)
    set_renderer_stack_state_loading(rc_target);
    was_complete = true;
else
    was_complete = false;
end

if verbose
    fprintf('Removing Clusters Progress:');
    fprintf(['\n' repmat('.',1,numel(input_zs)) '\n\n']);
end

parfor i=1:numel(input_zs)
    % Split up section into clusters and determine which to remove
    L = load_point_matches(input_zs(i), input_zs(i), rc_section_source, pm, 0, 3, 1, inf);
    [L_vec,a] = reduce_to_connected_components(L, min_tiles);
    if any(a<=min_tiles)
        % If any clusters need to be deleted, group the remaining clusters
        % together. Delete the target section and ingest the new section.
        large_cluster_tiles = [L_vec(a>min_tiles).tiles];
        L_to_ingest = Msection(large_cluster_tiles);
        try_to_delete_section(rc_target, input_zs(i));
        resp = ingest_section_into_renderer_database(L_to_ingest, rc_target, rc_base, dir_scratch, 0, 0);
        did_replace_sections(i,2) = sum(a(a<=min_tiles));
    elseif ~isequal(rc_target, rc_section_source) % If they are equal, don't need to do anything
        % If no clusters need to be removed, simply copy the source section
        % to the target collection.
        try_to_delete_section(rc_target, input_zs(i));
        resp = ingest_section_into_renderer_database(L, rc_target, rc_base, dir_scratch, 0, 0);
    end
    if verbose, fprintf('\b|\n'); end
end

% Complete the collection
if was_complete
    fprintf('Complete stack\n');
    set_renderer_stack_state_complete(rc_target);
end

end

