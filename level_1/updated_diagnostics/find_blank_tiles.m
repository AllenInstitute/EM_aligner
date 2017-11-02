function fft2_results  = find_blank_tiles( rc, varargin )
%% Determines if a tile is blank based on its radially averaged fft2 and a cutoff.
% opts has fields
% scale (0.25):                 scale of image used for fft2
% angle_to_skip (15):           angle within x or y axis to skip during radial averaging
% min_radius (100):             minimum radius for radial averaging
% max_radius (200):             maximum radius for radial averaging
% cutoff (1E4):                 cutoff for blank tile metric for the tile to be considered blank
% save_removed_tile_images (0): whether to save images, though this doesn't work well in parfor
% output_directory (pwd):       output directory for saving images
% Returns fft2_results
if nargin==1
    zu = get_section_ids(rc);
    opts = [];
end
if nargin==2
    if isstruct(varargin{1})
        opts = varargin{1};
        zu = get_section_ids(rc);
    else
        opts = [];
        zu = varargin{1};
    end
end
if nargin==3
    zu = varargin{1};
    opts = varargin{2};
end
if ~isfield(opts, 'scale') opts.scale = 0.25; end
if ~isfield(opts, 'angle_to_skip') opts.angle_to_skip = 15; end
if ~isfield(opts, 'min_radius') opts.min_radius = 100; end
if ~isfield(opts, 'max_radius') opts.max_radius = 200; end
if ~isfield(opts, 'cutoff_value'), opts.cutoff_value = 1E4; end
if ~isfield(opts, 'save_removed_tile_images'), opts.save_removed_tile_images = 0;  end
if ~isfield(opts, 'output_directory'), opts.output_directory = pwd; end
    
fft2_results = calculate_all_fft2_and_profile(rc, zu, opts);%calculate_fft2_and_profile(rc, tile_ids, 0.25);
%%
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
legend('Middle Tiles','Edge Tiles');
end
%%
function fft2_results =calculate_all_fft2_and_profile(rc, zs, opts)
scale = opts.scale;
if(rc.verbose), fprintf(['\n' repmat('.',1,numel(zs)) '\n\n']); end
%fft2_results = struct('tile_ids', {},'blank_metric',[], 'is_in_middle', [], 'z',[], 'tile_zs', []);
fft2_results(numel(zs)).tile_ids = {};
fft2_results(numel(zs)).blank_metric = [];
fft2_results(numel(zs)).is_in_middle = [];
fft2_results(numel(zs)).z = [];
fft2_results(numel(zs)).tile_zs = [];
if opts.save_removed_tile_images
    system(['mkdir -p ' opts.output_directory '/edge']);
    system(['mkdir -p ' opts.output_directory '/middle']);
end
parfor i=1:numel(zs)
    L = Msection(rc, zs(i));
    cols = [L.tiles.col];
    num_tiles = numel(L.tiles);
    if num_tiles ==1
        fft2_results(i).is_in_middle = 1;
    else
        fft2_results(i).is_in_middle = (cols~= min(cols) & cols~=max(cols));
    end
    for tile_index = 1:num_tiles
        img = imresize(imread(L.tiles(tile_index).path),scale);
        fft2_results(i).tile_ids{tile_index} = L.tiles(tile_index).renderer_id;
        [~, fft2_results(i).blank_metric(tile_index)] = radial_average_of_fft2(img, opts);
        fft2_results(i).tile_zs(tile_index) = zs(i);
        if opts.save_removed_tile_images
            if fft2_results(i).blank_metric < opts.cutoff_value
                if fft2_results(i).is_in_middle
                    output_directory = [opts.output_directory '/middle/'];
                else
                    output_directory = [opts.output_directory '/edge/'];
                end               
                prefix = sprintf('%011.4f', round(fft2_results(i).blank_metric(tile_index)*10000)/10000);
                my_parfor_imwrite(imresize(img,0.15), [output_directory prefix '_' fft2_results(i).tile_ids{tile_index} '.tif']);
            end
        end
        % Get average
    end
    if(rc.verbose), fprintf('\b|\n'); end
    fft2_results(i).z = zs(i);
end
end

%%
function [radial_profile, blank_metric] = radial_average_of_fft2(img, opts)
angle_to_skip = opts.angle_to_skip;
min_radius = opts.min_radius;
max_radius = opts.max_radius;
fft2_magnitude = abs(fftshift(fft2(img)));
[rows, columns] = size(fft2_magnitude);
midRow = rows/2+1;
midCol = columns/2+1;
radial_profile = zeros((max_radius-min_radius)+1, 1);
count = zeros((max_radius-min_radius)+1, 1);
for col = floor(midCol-max_radius):ceil(midCol+max_radius)
    for row = floor(midRow-max_radius):ceil(midRow+max_radius)
        radius = sqrt((row - midRow) ^ 2 + (col - midCol) ^ 2);
        if radius>=min_radius && radius<=max_radius
            current_angle_from_center = atand((row-midRow)/(col-midCol));
            if current_angle_from_center > angle_to_skip && current_angle_from_center < 90-angle_to_skip
                thisIndex = ceil(radius)-min_radius+1 ;
                radial_profile(thisIndex) = radial_profile(thisIndex) + fft2_magnitude(row, col);
                count(thisIndex) = count(thisIndex) + 1;
            end
        end
    end
end
%figure();
%imshow(log(fft2_magnitude)/10.0)
%imagesc(log(fft2_magnitude));
% Get average
radial_profile = radial_profile ./ count;
blank_metric = nanmean(radial_profile(10:30));
end

function my_parfor_imwrite(img, file_name)
imwrite(img, file_name);

end

