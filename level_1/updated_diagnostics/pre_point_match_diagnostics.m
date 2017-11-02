function fft2_results = pre_point_match_diagnostics( rc, zu, options)
if isempty(zu), zu = get_section_ids(rc); end
if nargin<3, options = []; end
if ~isfield(options, 'min_radius'), options.min_radius = 110; end
if ~isfield(options, 'max_radius'), options.max_radius = 130; end
if ~isfield(options, 'scale'), options.scale = 0.25; end
if ~isfield(options, 'angle_to_skip'), options.angle_to_skip = 15; end
if ~isfield(options, 'plot_results'), options.plot_results = true; end

fft2_results = calculate_all_fft2_and_profile(rc, zu, options);
if options.plot_results
    plot_fft2_results(fft2_results);
end

end
%%
function fft2_results =calculate_all_fft2_and_profile(rc, zs, options)
fprintf(['\n' repmat('.',1,numel(zs)) '\n\n']);
fft2_results = struct('tile_id', {}, 'radial_profile',{},'blank_metric',[], 'is_in_middle', [], 'z',[]);
parfor i=1:numel(zs)
    L = Msection(rc, zs(i));
    cols = [L.tiles.col];
    num_tiles = numel(L.tiles);
    fft2_results(i).is_in_middle = (cols~= min(cols) & cols~=max(cols));
    for tile_index = 1:num_tiles
        img = imresize(imread(L.tiles(tile_index).path),options.scale);
        fft2_results(i).tile_ids{tile_index} = L.tiles(tile_index).renderer_id;
        [~, fft2_results(i).blank_metric(tile_index)] = radial_average_of_fft2(img, options);
        % Get average
    end
    fprintf('\b|\n');
    fft2_results(i).z = zs(i);
end
end

%%
function [radial_profile, blank_metric] = radial_average_of_fft2(img, options)
fft2_magnitude = abs(fftshift(fft2(img)));
[rows, columns] = size(fft2_magnitude);
midRow = rows/2+1;
midCol = columns/2+1;
angle_to_skip = options.angle_to_skip;
minRadius = options.min_radius;
maxRadius = options.max_radius;
radial_profile = zeros((maxRadius-minRadius)+1, 1);
count = zeros((maxRadius-minRadius)+1, 1);
for col = floor(midCol-maxRadius):ceil(midCol+maxRadius)
    for row = floor(midRow-maxRadius):ceil(midRow+maxRadius)
        radius = sqrt((row - midRow) ^ 2 + (col - midCol) ^ 2);
        if radius>=minRadius && radius<=maxRadius
            current_angle_from_center = atand((row-midRow)/(col-midCol));
            if current_angle_from_center > angle_to_skip && current_angle_from_center < 90-angle_to_skip
                thisIndex = ceil(radius)-minRadius+1 ;
                radial_profile(thisIndex) = radial_profile(thisIndex) + fft2_magnitude(row, col);
                count(thisIndex) = count(thisIndex) + 1;
            end
        end
    end
end
radial_profile = radial_profile ./ count;
blank_metric = nanmean(radial_profile);
end

function plot_fft2_results(fft2_results)
all_tile_ids = [fft2_results(:).tile_ids];
all_tile_metrics = [fft2_results(:).blank_metric];
tile_indices = 1:numel(all_tile_metrics);
is_in_middle = [fft2_results(:).is_in_middle];
[sorted_metrics,sorted_indices] = sort(all_tile_metrics);
sorted_ids = all_tile_ids(sorted_indices);
sorted_is_in_middle = is_in_middle(sorted_indices);
figure(); hold on;
plot(tile_indices(sorted_is_in_middle), sorted_metrics(sorted_is_in_middle),'ro')
plot(tile_indices(~sorted_is_in_middle), sorted_metrics(~sorted_is_in_middle),'b.')
sorted_ids_in_middle = sorted_ids(sorted_is_in_middle);
sorted_metrics_in_middle = sorted_metrics(sorted_is_in_middle);
xlabel('Sorted Tile Number');
ylabel('Blank Tile Metric');
hline = refline(0,1.5E4);
hline.Color = 'black';
end

