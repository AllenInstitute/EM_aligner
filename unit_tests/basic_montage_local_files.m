function [n_tiles, L_montage] = basic_montage_local_files()
% test: run inside directory ~/EM_aligner/test_scripts
%
%
% Generate Msection from layout file and generate a montage for a 37-tile section
% assumes that example_02 data has been generated
%
%
% Author: Khaled Khairy. Janelia Research Campus. 2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fn_layout_acquire = '../test_data/example_02_37_z_4/layout_acquire.txt';
fn_layout_montage = '../test_data/example_02_37_z_4/layout_montage.txt';

% generate Msection objects
L = Msection(fn_layout_acquire, 4);
mL = Msection(fn_layout_montage, 4);

% generate montaged Msection object
L_montage = register(L);
n_tiles = numel(L_montage.tiles);