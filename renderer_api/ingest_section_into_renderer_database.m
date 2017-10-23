function resp_append = ingest_section_into_renderer_database(mL,rc_target,...
    rc_base, dir_work, translate_to_positive_space, complete, disableValidation)
% This is a high-level function that:
% Ingests the data into an existing collection, creates one if the collection doesn't already exist
% sets the state to LOADING  if it is in COMPLETE state and
% Completes the collection in the end
%
% Since collections are based off of other collections. In this case the base
% collection is specified in the rc_base struct
%
% Author: Khaled Khairy. Janelia Research Campus.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin<6, complete = 1;end
if nargin<5, translate_to_positive_space = 1;end
if nargin<7, disableValidation = 0;end
if ~stack_exists(rc_base), error('base collection not found');end

if ~stack_exists(rc_target)
    disp('Target collection not found, creating new collection in state: ''Loading''');
    resp = create_renderer_stack(rc_target);
end
if stack_complete(rc_target)
    %disp('Cannot append COMPLETE stack: setting state to LOADING');
    resp = set_renderer_stack_state_loading(rc_target);
end
%% translate to origin to be Renderer friendly

try
    if translate_to_positive_space
        disp('Translating to +ve space');
        %disp('translating to set in +ve space');
        mL = translate_to_origin(mL);
    end
catch err
    disp('Failed to translate to +ve space');
end
%% export to MET (in preparation to be ingested into the Renderer database
fn = [dir_work '/X_A_' num2str(randi(100000000)) '.txt'];
%disp('Exporting temporary MET file');
if strcmp(class(mL.tiles(1).tform), 'images.geotrans.PolynomialTransformation2D')
    export_montage_MET_poly(mL, fn);
    v = 'v3';
else
    export_MET(mL, fn, 2, 2, 0);
    v = 'v1';
end

%% append tiles to existing collection
%disp('Ingesting data (append)');
resp_append = append_renderer_stack(rc_target, rc_base, fn, v, disableValidation);

%% cleanup
try
    delete(fn);
catch err_delete,
    kk_disp_err(err_delete);
end

%% complete stack
if complete
resp = set_renderer_stack_state_complete(rc_target);
end
