function [ S, G, tIds, clusters] = calculate_connectivity_for_collection( zs, rc, point_matches, options)

if isempty(zs)
    [zu, sID, ~, ~, ~, ~] = get_section_ids(rc);
else
    [zu, sID, ~, ~, ~, ~] = get_section_ids(rc,zs(1),zs(end));
end

[T, map_id, tIds, ~] = load_all_transformations(rc, zu, options.dir_scratch);

if ~isfield('point_matches', 'adj')
    [PM.M, PM.adj, ~, PM.np] = system_solve_helper_load_point_matches(zu, options,point_matches, map_id, sID, size(T,1));
else
    PM = point_matches;
end
  
[ S, G, clusters] = calculate_connectivity_from_pm_stuct( PM, numel(tIds));
%for i=1:numel(small_clusters)
%    fprintf('%s\n',tIds{clusters==small_clusters(i)});
%end
end

