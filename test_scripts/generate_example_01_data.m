% This script should only be run once per test-example-set to generate example files. If
% the data set exists, please do not run again. It is only valid as long as
% the Msection*.mat objects are valid that it depends on. They become invalid as soon as the
% Renderer collection changes. The Msection*.mat objects used here have
% been created by first running the script test_montage_01.m which
% calculates a montage solution and ingests montage collections into the Renderer database.
%
% This script generates a Renderer-database/file path independent test data set (images and layout files) from Msection
% objects L (loaded from the example set produced as above) for acquire and montage.
% 
% Warning: only run this script from within the test_scripts folder
%          layout files will have relative paths to images. Therefore,
%          Msection and tile objects will only be valid if run within
%          test_scripts folder. To circumvent this (not recommended), change "dir_test_data"
%          variable to produce fully qualified unix paths.
% 
% Author: Khaled Khairy. Janelia Research Campus.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dir_test_data = '../test_data';


%% load variables for both montage and acquire sections
z = 300;
load([dir_test_data '/Msection_objects/Msection_region_FAFBv12_section_300_montage.mat']);
L_montage = L;
load([dir_test_data '/Msection_objects/Msection_region_FAFBv12_section_300_acquire.mat']);
L_acquire_full = L;
 
 %% L_montage tiles constitute a subset of L_acquire_full. Find linear indices into L_acquire_full for that subset
 indx_vec = zeros(numel(L_montage.tiles),1);
 for tix = 1:numel(L_montage.tiles)
     rid = L_montage.tiles(tix).renderer_id;
     indx_vec(tix) = L_acquire_full.map_renderer_id(rid);
 end
 L_acquire = Msection(L_acquire_full.tiles(indx_vec));
 
%% configure 
dir_example    = [dir_test_data '/example_01_' num2str(numel(L_montage.tiles)) '_z_' num2str(z)]; 
dir_image_data = [dir_example '/images_LC']; % make sure to make these directories befor running the script
acquire_layout = [dir_example '/layout_acquire.txt']; % includes stage coordinates only, i.e. only points to LC image files (local)
montage_layout = [dir_example '/layout_montage.txt']; % includes the solved transformations

if ~exist(dir_example, 'dir'), mkdir(dir_example);end
if ~exist(dir_image_data, 'dir'), mkdir(dir_image_data);end
%%
% [1] generate image files at the stage after LC and before montage solution and save them in dir_image_data folder
% [2] generate Msection object with tiles that have stage coordinate transformations and point to the new LC images
% [3] generate Msection object with tiles that have montage solution and point to the new LC images


tile_vec_acquire = tile;
tile_vec_acquire(numel(L_acquire.tiles)) = tile;

tile_vec_montage = tile;
tile_vec_montage(numel(L_montage.tiles)) = tile;


parfor tix = 1:numel(L_acquire.tiles)
    t = L_acquire.tiles(tix);
    t.fetch_local = 0;  % make sure that we are using a local client
    
    % [1]     
    im = get_image(t, 'true', 1.0);   % 
    new_path = [dir_image_data '/image_' t.renderer_id '.jpg'];
    imwrite(im, new_path);
    
    % [2] 
    t.path = new_path;
    t.mask = '';
    t.fetch_local = 1;
    tile_vec_acquire(tix) = t;
    
    % [3]
    t = L_montage.tiles(tix);
    t.path = new_path;
    t.mask = '';
    t.fetch_local = 1;
    tile_vec_montage(tix) = t;
end

%% generate a new Msection object with acquire tiles and save that object
L = Msection(tile_vec_acquire);
L = mosaic_gen(L);
save([dir_example '/Msection_acquire_with_mosaic.mat'], 'L');
export_layout_txt(L, acquire_layout, 0, 1);%% export to layout.txt file


%% generate a new Msection object with montage tiles and save that object
L = Msection(tile_vec_montage);
L = mosaic_gen(L);
save([dir_example '/Msection_montage_with_mosaic.mat'], 'L');
export_layout_txt(L, montage_layout, 0, 1);%% export to layout.txt file

%% test re-ingestion
clear L2;
L2 = Msection;
L2 = import_from_layout_txt(L2, montage_layout, z);









