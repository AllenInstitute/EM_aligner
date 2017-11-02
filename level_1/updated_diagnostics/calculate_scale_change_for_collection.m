function [ T, map_id, tIds, z_val, r, c, average_scale_information] = calculate_scale_change_for_collection( rc, zs, dir_scratch )
if nargin<2
    zs = get_section_ids(rc);
end
if nargin <3
    dir_scratch = ['/scratch/' char(java.lang.System.getProperty('user.name'))];
end
[T, map_id, tIds, z_val, r, c] = load_all_transformations(rc, zs, dir_scratch);
num_tiles = size(T,1);
all_scales = zeros(num_tiles,2);
parfor i=1:num_tiles
    [~,S,~] = svd([T(i,1),T(i,4);T(i,2), T(i,5)]);
    all_scales(i,:) = [S(1,1),S(2,2)];
end
for i = 0:max(r)
    j=i+1;
    average_scale_information(j).z = z_val(r==i);
    average_scale_information(j).average_scale = mean(all_scales(r==i,:),2);
    if numel(average_scale_information(j).average_scale)>=2
        average_scale_information(j).average_scale_difference = average_scale_information(j).average_scale(2:end)-average_scale_information(j).average_scale(1:end-1);
    end
end
end

