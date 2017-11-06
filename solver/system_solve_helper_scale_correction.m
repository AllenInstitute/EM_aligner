function [err,R, Tout, D_affine, all_scales, z_val_translation, tIds] = system_solve_helper_scale_correction(rctranslation, rcfine, pm, opts, nfirst, nlast)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
diary on;
clc

%% configure Affine fine alignment
  
if ~isfield(opts, 'transfac'), opts.transfac = 1.0;end
if ~isfield(opts, 'nchunks_ingest'), opts.nchunks_ingest = 32;end
if ~isfield(opts, 'disableValidation'), opts.disableValidation = 1;end
if ~isfield(opts, 'transfac'), opts.transfac = 1;end
if ~isfield(opts, 'filter_point_matches'), opts.filter_point_matches = 1;end
if ~isfield(opts, 'use_peg'), opts.use_peg = 0;end
if ~isfield(opts, 'nbrs_step'), opts.nbrs_step = 1;end


rcfine.versionNotes = gen_versionNotes(opts);
[err,R, Tout, D_affine] = system_solve_affine_with_constraint(nfirst, nlast, rctranslation, pm, opts, rcfine);disp(err);
[T, ~, tIds, ~,~] = load_all_transformations(rcfine, (nfirst:nlast), '/scratch/ackermand/');
[T_translation, ~, tIds_translation, z_val_translation,~] = load_all_transformations(rctranslation, (nfirst:nlast), '/scratch/ackermand/');
all_scales = zeros(length(T),2);
num_tiles = size(T,1);
%get correct tile ordering
[is_in, appropriate_indices] = ismember(tIds_translation, tIds);
if any(is_in==0), error('Tiles not found\n'); end
parfor i=1:num_tiles
    [~,S,~] = svd([T(i,1),T(i,4);T(i,2), T(i,5)]);
    all_scales(i,:) = [S(1,1),S(2,2)];
end

[zu, ~, ~, ~, ~] = get_section_ids(rctranslation, nfirst, nlast);
T_translation_scaled = T_translation;
T_translation_scaled(:,1) = all_scales(appropriate_indices,1); %replace scales
T_translation_scaled(:,5) = all_scales(appropriate_indices,2);

rctranslation_scaled = rctranslation;
rctranslation_scaled.stack = [rctranslation_scaled.stack '_scaled'];


system_solve_helper_ingest_into_renderer_database(rctranslation, rctranslation_scaled, ...
    T_translation_scaled, tIds_translation, z_val_translation, opts, zu);
end
