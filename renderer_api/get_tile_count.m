function tile_count = get_tile_count( rc,z )
% Gets the tile count for a renderer collection rc at zs z
if nargin<2, z = get_section_ids(rc); end
tile_count = zeros(size(z));
parfor i=1:numel(z)
    uz = get_section_ids(rc, z(i),z(i));
    if isempty(uz)
        tile_count(i) = 0;
    else
        [T,~, ~, ~] = load_all_transformations(rc, z(i));
        tile_count(i) = size(T,1);
    end
end
end

