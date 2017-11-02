function [ fft2_results ] =filter_empty_tiles_from_collection(rcs, zu, opts )
%% Removes blank tiles from rc over the range zu, or replaces blank tiles in the middle
% If rcs is an array of rcs then the first one is copied to the name of the
% second one, which is then used for filtering

% opts has fields
% cutoff_value (1E4):             The cutoff used to determine if the tile is blank
% save_removed_tile_images (0):   To save the images of removed tiles, saved with the tile id prefixed with the blank tile metric
% output_directory (pwd):         The directory where the images and files containing a list of the removed or replaced tiles will be placed
% remove_copied_tiles (false):    Whether to also delete tiles that have been replaced by adjacent tiles
% Returns fft2_results struct


if numel(rcs)>1
   rcin = rcs(1);
   rc = rcs(2);
   str = sprintf('/groups/flyTEM/flyTEM/render/bin/copy-stack.sh --sparkNodes 1 --sparkBillTo flyem --sparkRunInBackground n --sparkDir /groups/flyem/data/render/spark_output --baseDataUrl http://tem-services:8080/render-ws/v1 --owner %s --project %s --stack %s --targetStack %s',...
       rcin.owner, rcin.project, rcin.stack, rc.stack);
   if stack_exists(rc)
       warning('Not creating output stack %s, it already exists', rc.stack);
   else
       fprintf('Making output stack:');
       system(str);
       set_renderer_stack_state_complete(rc);
   end
else
    rc = rcs; 
end
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

if ~isfield(opts, 'cutoff_value'), opts.cutoff_value = 1E4; end
if ~isfield(opts, 'save_removed_tile_images'), opts.save_removed_tile_images = 0;  end
if ~isfield(opts, 'output_directory'), opts.output_directory = pwd;
if ~isfield(opts, 'remove_copied_tiles'), opts.remove_copied_tiles = false; end
fft2_results  = find_blank_tiles( rc, zu, opts );
all_tile_ids = [fft2_results(:).tile_ids];
all_tile_metrics = [fft2_results(:).blank_metric];
all_tile_is_in_middle = [fft2_results(:).is_in_middle];
all_tile_zs = [fft2_results(:).tile_zs];
tile_indices_below_cutoff = find(all_tile_metrics<opts.cutoff_value);
tile_ids_below_cutoff= all_tile_ids(tile_indices_below_cutoff);
tile_will_be_replaced_or_removed = cell(size(tile_ids_below_cutoff)); % one replaced, two removed
tile_ids_to_replace_or_remove = cell(size(tile_ids_below_cutoff));
tile_command_string = cell(size(tile_ids_below_cutoff));
tile_file_string = cell(size(tile_ids_below_cutoff));
% replace middle tiles with neighboring ones
parfor i=1:numel(tile_indices_below_cutoff)
    %try previous section first
    index_within_all = tile_indices_below_cutoff(i);
    bad_tile_z = all_tile_zs(index_within_all);
    L_bad = Msection(rc, bad_tile_z);
    bad_tile_index = find(ismember({L_bad.tiles.renderer_id}, all_tile_ids(index_within_all)));
    bad_tile_column = L_bad.tiles(bad_tile_index).col;
    found_a_good_tile = 0;
    count = 1;
    while ~found_a_good_tile && count<=2
        good_tile_z = bad_tile_z - (-1)^count * ceil(count/2); %will search +/- 1 section, 2 sections, 3...
        if good_tile_z>=min(all_tile_zs) && good_tile_z <=max(all_tile_zs)
            L_good = Msection(rc, good_tile_z);
            good_tile_index = find(ismember([L_good.tiles.col],bad_tile_column));
            if ~isempty(good_tile_index) && sum(ismember(tile_ids_below_cutoff, L_good.tiles(good_tile_index).renderer_id))==0 %then the good tile is indeed a good tile
                found_a_good_tile = 1;
            end
        end
        count = count+1;
    end
    tile_ids_to_replace_or_remove{i} = L_bad.tiles(bad_tile_index).renderer_id;
    if found_a_good_tile
        %replace
        path = L_bad.tiles(bad_tile_index).path;
        [pathstr, name, ext] = fileparts(path);
        %     if exist([pathstr '/badImages/' name ext])
        %         warning(sprintf('File %s has already been replaced', [pathstr '/badImages/' name ext]));
        %     end
        tile_command_string{i} = ...
        {['mkdir -p ' pathstr '/badImages/'];...
        ['mv ' pathstr '/' name ext ' ' pathstr '/badImages/ '];...
        ['ln -s ' L_good.tiles(good_tile_index).path ' ' L_bad.tiles(bad_tile_index).path]};
        tile_file_string{i} = sprintf('%s -> %s %d %s -> %s', all_tile_ids{index_within_all}, L_good.tiles(good_tile_index).renderer_id, all_tile_is_in_middle(index_within_all), L_bad.tiles(bad_tile_index).path, L_good.tiles(good_tile_index).path);
        tile_will_be_replaced_or_removed{i} = 'replaced';
        %fprintf(fid_replace, '%s %d %s -> %s \n', all_tile_ids{index_within_all}, all_tile_is_in_middle(index_within_all), L_bad.tiles(bad_tile_index).path, L_good.tiles(good_tile_index).path);
    else
        tile_will_be_replaced_or_removed{i} = 'removed';
        tile_file_string{i} = sprintf('%s %d', all_tile_ids{index_within_all},all_tile_is_in_middle(index_within_all));
     %   fprintf(fid_remove, '%s %d\n', all_tile_ids{index_within_all},all_tile_is_in_middle(index_within_all));
    end
end


fid_replace = fopen([opts.output_directory '/replaced_tiles.txt'],'wt');
fid_remove = fopen([opts.output_directory '/removed_tiles.txt'],'wt');
tile_ids_to_remove={};
for i=1:numel(tile_file_string)
    if strcmp(tile_will_be_replaced_or_removed{i}, 'replaced')
        fprintf(fid_replace,sprintf('%s\n',tile_file_string{i}));
        system(tile_command_string{i}{1});
        system(tile_command_string{i}{2});
        system(tile_command_string{i}{3});
    else
        tile_ids_to_remove = [tile_ids_to_remove, tile_ids_to_replace_or_remove{i}];
        fprintf(fid_remove,sprintf('%s\n',tile_file_string{i}));
    end
end
fclose(fid_replace);
fclose(fid_remove);

% fid_remove = fopen([opts.output_directory '/removed_tiles.txt'],'wt');
% for i=1:numel(tile_ids_to_remove)
%    fprintf(fid_remove, '%s %d\n', tile_ids_to_remove{i},tile_to_remove_is_in_middle(i));
% end
% remove edge blank tiles
if opts.remove_copied_tiles == true
    delete_renderer_tile(rc,tile_ids_to_replace_or_remove);
else
    delete_renderer_tile(rc,tile_ids_to_remove);
end
end
end

