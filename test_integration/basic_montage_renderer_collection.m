function n_tiles = basic_montage_renderer_collection(rcsource, rctarget_montage, section_z)
%% This is a test for generation of the montage of one section
% 
% Note: you need to connect to a working Renderer service. Configure
% accordingly.
% run from ~/EM_aligner/unit_tests
%
% Author: Khaled Khairy. Janelia Research Campus -- 2016.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

L                = Msection(rcsource, section_z);   % instantiate Msection object using the Renderer service to read tiles
L.dthresh_factor = 1.7;                             % factor x tile diagonal = search radius. increase this paramter to cover a wider radius of tile-tile comparisons
[L, ~]          = register(L);                      % perform the actual registration
n_tiles = numel(L.tiles);
