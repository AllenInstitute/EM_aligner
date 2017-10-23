function [append_resp] = ingest_section_into_LOADING_collection(...
    mL,rc_target, rc_base, dir_work, translate_to_positive_space, disableValidation)
% This is a high-level function that:
%* Ingests the data into an existing collection,
%* creates one if the collection doesn't already exist
%* assumes LOADING, sets to LOADING if it is in COMPLETE state,
%* does not set state to COMPLETE
%
% Since collections are based off of other collections. In this case the base
% collection is specified in the rc_base struct
%
% Author: Khaled Khairy. Janelia Research Campus.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin<6, disableValidation = 0;end
if nargin<5, translate_to_positive_space = 1;end

if ~stack_exists(rc_base), error('base collection not found');end

if ~stack_exists(rc_target)
    %disp('Target collection not found, creating new collection in state: ''Loading''');
    resp = create_renderer_stack(rc_target);
end
if stack_complete(rc_target)
    resp = set_renderer_stack_state_loading(rc_target);
end
%% translate to origin to be Renderer friendly
try
    if translate_to_positive_space
        %disp('translating to set in +ve space');
        mL = translate_to_origin(mL);
    end
catch err
    %disp('Failed to translate to +ve space');
end
%% export to MET (in preparation to be ingested into the Renderer database
fn = [dir_work '/X_A_' num2str(randi(1000000)) '.txt'];
if strcmp(class(mL.tiles(1).tform), 'images.geotrans.PolynomialTransformation2D')
    export_montage_MET_poly(mL, fn);
    v = 'v3';
else
    export_MET(mL, fn, 2, 2, 0);
    v = 'v1';
end

%% append tiles to existing collection
append_resp = append_renderer_stack(rc_target, rc_base, fn, v, disableValidation);

%% cleanup
try
    delete(fn);
catch err_delete,
    kk_disp_err(err_delete);
end

