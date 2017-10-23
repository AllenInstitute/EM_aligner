function resp_append = ...
    ingest_section_into_renderer_database_overwrite(mL,rc_target, rc_base, dir_work, translate_to_positive_space)
% This is a high-level function that:
% Deletes the rc_target collection if it already exists
% Creates a new collection (stack or section) for the specified tiles in mL
% Ingests the data
% Completes the collection
%
% Since collections are based off of other collections. In this case the base
% collection is specified in the rc_base struct
%
% Author: Khaled Khairy. Janelia Research Campus.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
diary on;
if nargin<5, translate_to_positive_space = 1;end
disp('Deleting obsolete renderer collection');
resp = delete_renderer_stack(rc_target);
disp('Creating new empty renderer collection');
resp = create_renderer_stack(rc_target);

%% distributed version
disp('Translate to origin');
diary off;
diary on;
mL = translate_to_origin(mL);
translate_to_positive_space = 0;
complete = 0;
disp('Splitting into sections to prepare for distributed ingestion');
diary off;diary on;
zmL = split_z(mL);
disp('Start distributed process to populate new renderer collection');diary off;diary on;

resp_append = {};

if numel(zmL)<=310
    parfor ix = 1:numel(zmL)
        resp_append{ix} = ingest_section_into_renderer_database(zmL(ix),...
            rc_target, rc_base, dir_work, translate_to_positive_space,...
            complete);
    end
    
else
    for ix = 1:numel(zmL)
        disp('--------------');
        disp('Ingesting section: ');
        disp(ix);
        disp('--------------');
        resp_append{ix} = ingest_section_into_renderer_database(zmL(ix),...
            rc_target, rc_base, dir_work, translate_to_positive_space,...
            complete);
    end
    
end

disp('Completing stack');diary off;diary on;

resp = set_renderer_stack_state_complete(rc_target);
disp('Done with ingestion');diary off;diary on;



%% non-distributed
complete = 1;
%resp_append = ingest_section_into_renderer_database(mL, rc, rc_base, dir_work, translate_to_positive_space);