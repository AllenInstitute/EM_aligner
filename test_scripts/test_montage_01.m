%% This is a test script for generation of the montage of one section
% The steps are:
% [0] configuration of renderer database collection (source and output montage)
% [1] generate the Msection object and register (generate montage)
% [2] ingest the montaged section into the Renderer database as a new collection
% [3] quick inspection of results
% 
% Note: you need to connect to a working Renderer service. Configure
% accordingly.
% Please run from a direcory in which you have write permission
%
% Author: Khaled Khairy. Janelia Research Campus -- 2016.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% [0] configure collections
clc
section_z = 4.0; % this is the section z-coordinate value to be montaged


% source collection
rcsource.owner                  = 'flyTEM';
rcsource.project                = 'FAFB00';
rcsource.stack                  = 'v12_acquire_merged';
rcsource.service_host           = '10.37.5.60:8080';    % use of ip adress is preferred (no DNS lookup)--Note: 10.37.5.60 is a VM, 10.40.3.162 is tem-services
rcsource.baseURL                = ['http://' rcsource.service_host '/render-ws/v1']; 
rcsource.verbose                = 1;

% target collection
rctarget_montage.owner          = 'flyTEM';
rctarget_montage.project        = 'test';
rctarget_montage.stack          = ['Test_' rcsource.stack '_montage_' num2str(section_z)];
rctarget_montage.service_host   = '10.37.5.60:8080';    % use of ip adress is preferred (no DNS lookup)-- Note: 10.37.5.60 is a VM, 10.40.3.162 is tem-services
rctarget_montage.baseURL        = ['http://' rctarget_montage.service_host '/render-ws/v1']; 
rctarget_montage.verbose        = 1;


%% [1] generate montage registration
L                = Msection(rcsource, section_z);   % instantiate Msection object using the Renderer service to read tiles
L.dthresh_factor = 1.7;                             % factor x tile diagonal = search radius. increase this paramter to cover a wider radius of tile-tile comparisons
[L2, ~]          = register(L);                    % perform the actual registration

%% [2] ingest montaged section into the database (optional) so that we can look at it using dynamic rendering
ingest_section_into_renderer_database_overwrite(L2, rctarget_montage, rcsource, pwd);

%% [3] look at tile outlines in Matlab
figure; show_map(L);title('Tile outlines before registration');
figure; show_map(L2);title('Tile outlines after registration');


