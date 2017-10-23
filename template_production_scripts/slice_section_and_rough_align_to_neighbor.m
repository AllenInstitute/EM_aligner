%%% under development --------
%%% Purpose: - slice one section (from a montage collection) into one or more subsets of tiles
%%%            manually (at tile-resolution)  --- sosi (do subtile similar to TrackEM2)
%%%          - rough align pieces to one or more neighbors
%%%          - merge pieces into one section again
%%%          - replace section in source (montage collection)

%%%% select subset of tiles of a section
clear all;clc
%% configure

% source stack for all ingestions
rc.stack          = 'v12_acquire_merged';
rc.owner          ='flyTEM';
rc.project        = 'FAFB00';
rc.service_host   = '10.40.3.162:8080';
rc.baseURL        = ['http://' rc.service_host '/render-ws/v1'];


% montage stack for sections
rcmontage.stack          = 'Revised_slab_2635_2637_montage';
rcmontage.owner          ='flyTEM';
rcmontage.project        = 'FAFB00_beautification';
rcmontage.service_host   = '10.40.3.162:8080';
rcmontage.baseURL        = ['http://' rcmontage.service_host '/render-ws/v1'];


% output stack with only selected tiles
rcout_temp.stack          = 'temp_';
rcout_temp.owner          = 'flyTEM';
rcout_temp.project        = 'FAFB00_beautification';
rcout_temp.service_host   = '10.40.3.162:8080';
rcout_temp.baseURL        = ['http://' rcout_temp.service_host '/render-ws/v1'];


% final destination of newly montaged pieces [Revision slab montage collection]
rc_rev_montage_slab.stack          = 'Revised_slab_2630_2641_montage';
rc_rev_montage_slab.owner          ='flyTEM';
rc_rev_montage_slab.project        = 'FAFB00_beautification';
rc_rev_montage_slab.service_host   = '10.40.3.162:8080';
rc_rev_montage_slab.baseURL        = ['http://' rc_rev_montage_slab.service_host '/render-ws/v1'];

%  [Revised montage collection] --> where all revision montages are stored for tps later
rc_rev_montage.stack          = 'Revised_slab_2630_2641_montage';
rc_rev_montage.owner          ='flyTEM';
rc_rev_montage.project        = 'FAFB00_beautification';
rc_rev_montage.service_host   = '10.40.3.162:8080';
rc_rev_montage.baseURL        = ['http://' rc_rev_montage.service_host '/render-ws/v1'];


% where are the source image montage-scapes?
dir_source_images = '/nrs/flyTEM/khairy/FAFB00v13/montage_scape_pms/solver_2635_2637/layer_images';
dir_temp_ingest = '/scratch/khairyk';  % scratch directory used as temporary space for ingestion at the end

% define sections to redo and their rough_align counterparts
redo_lst = 2636; % sections to manually split
rgh_lst  = 2637; % roughly aline split parts to this section (this must be the z value)

% configure rough alignment
dir_rough_intermediate_store = '/nrs/flyTEM/khairy/FAFB00v13/montage_scape_pms';% intermediate storage of files
dir_store_rough_slab = '/nrs/flyTEM/khairy/FAFB00v13/matlab_slab_rough_aligned';
%scale  = 0.02;  

%% load sections and associated mosaic images
% generate list of images
fn = dir([dir_source_images '/*.png'] );
zid  = {};
for fix = 1:numel(fn)
    zid{fix} = fn(fix).name(1:end-4);
end
L(numel(fn)) = Msection;
z_num = str2double(zid);
% relate section z values with index in L.
indx_redo = [];
for ix = 1:numel(redo_lst)
    indx_redo(ix) = find(z_num==redo_lst(ix));
end
vec = indx_redo;
% Loads sections and associates mosaics with Msection objects:
for fix = vec
    L(fix) = Msection(rcmontage, str2double(zid{fix}));
    L(fix).mosaic = imread([dir_source_images '/' fn(fix).name]);
end

%% manual tile selection / slicing
% % select tiles manually: Figure opens and tile boxes appear. Make selection
% of tiles to keep, as soon as mouse is released the selected tiles will be ingested
% in case of mistake, ctrl-c, then record the value of fix, and set vec to start from
% current section to be repeated. then run only this current Matlab code section
% with the for loop below.
sm_agg = {};  % store section parts in an array of Msections
for fix = 1:numel(vec)
    % show the user tiles and montage-scape
    
    sm = Msection;
    continue_slicing = 1;
    count = 1;
    pl = [];
    clf;
    while(continue_slicing)
        show_map_with_mosaic(L(vec(fix)), scale);title([ num2str(vec(fix)) ' -- ' num2str(L(vec(fix)).z)]);
        try
            [pl,xs,ys] = selectdata('sel','lasso');  % the user can select tiles
        catch err_select_data
            disp('User selected empty region: terminating selection process');
            pl = [];
        end
        if isempty(pl)
            continue_slicing=0;
        else
            handles.x = vertcat(xs{:});
            handles.y = vertcat(ys{:});
            hold on;
            plot(handles.x, handles.y,'y*'); % plot to confirm selection to user
            drawnow;
            %% determine the selected tiles
            tix = zeros(numel(handles.x),1);
            for pix = 1:numel(handles.x)
                tix(pix) =get_tile_index(L(vec(fix)), handles.x(pix), handles.y(pix));
            end
            tix = unique(tix);
            sm(count) = Msection(L(vec(fix)).tiles(tix));
            disp(sm(count));
            count = count + 1;
        end
        disp(fix);
        sm_agg{fix} = sm;
    end
end

%% ingest slices into temporary collection
disableValidation = 0;
complete = 1;
translate_to_positive_space = 1;
z_base = 100000;

for fix = 1:numel(vec)
    sm = sm_agg{fix};
    
    rcout_temp.stack = ['temp_montage_' num2str(fix)];  % name of temporary collection
    
    % prepare and ingest ingest section that all pieces will be rough aligned to
    L_rough = Msection(rcmontage, rgh_lst(fix));
    L_rough.z = z_base + numel(sm) + 1;
    % ingest rough section
    resp_append = ingest_section_into_renderer_database(L_rough, rcout_temp, ...
        rc, dir_temp_ingest, translate_to_positive_space, complete, disableValidation);
    % change z value of rough section
    resp = set_section_z_by_section_id(rcout_temp, L_rough.sectionID, L_rough.z);
    
    % loop over pieces, prepare them, ingest and then change z
    for six = 1:numel(sm)
        disp(['Ingesting part ' num2str(six) ' of ' num2str(numel(sm)) '....']);
        sm_ingest = sm_agg{fix}(six);
        sm_ingest.z = z_base + six;
        %%% change z for all tiles in this piece
        for tix = 1:numel(sm_ingest.tiles)
            sm_ingest.tiles(tix).z = sm_ingest.z;
        end
        % ingest piece
        resp_append = ingest_section_into_renderer_database(sm_ingest, rcout_temp, ...
            rc, dir_temp_ingest, translate_to_positive_space, complete, disableValidation);
        
        % set new zvalue for those tiles
        disp(' ... adjusting z value');
        resp = set_tiles_z(rcout_temp, sm_ingest.tiles, sm_ingest.z);  % change z for tiles in this piece
    end
end

%% rough align and merge
%%% general configuration for rough alignment
rcmontage = rcout_temp;
rcrough = rcmontage;
scale = 0.03;
ms.fd_size                      = '10'; % '8'
ms.min_sift_scale               = '0.2';%'0.55';
ms.max_sift_scale               = '1.0';
ms.steps                        = '3';
ms.skip_similarity_matrix       = 'y';
ms.skip_aligned_image_generation= 'y';
ms.base_output_dir              = '/nrs/flyTEM/khairy/FAFB00v13/experiments/temp_rough_base_output';
ms.script                       = '/groups/flyTEM/home/khairyk/EM_aligner/renderer_api/generate_montage_scape_point_matches.sh';%'../unit_tests/generate_montage_scape_point_matches_stub.sh'; %
ms.number_of_spark_nodes        = '2.0';  % not currently used

for fix = 1:numel(vec)
    nfirst = z_base + 1;
    nlast = z_base + numel(sm_agg{fix}) + 1;
    
    rcmontage.stack= ['temp_montage_' num2str(fix)];  % name of temporary montage collection
    rcrough.stack =  ['temp_rough_' num2str(fix)];  % name of temporary rough collection
    % configure montage-scape point-match generation
    ms.service_host                 = rcmontage.service_host;
    ms.owner                        = rcmontage.owner;
    ms.project                      = rcmontage.project;
    ms.stack                        = rcmontage.stack;
    ms.similarity_range             = num2str(numel(sm_agg{fix})+1);
    ms.first                        = num2str(nfirst);
    ms.last                         = num2str(nlast);
    ms.scale                        = num2str(scale);
    ms.run_dir                      = ['Slab_' ms.first '_' ms.last '_scale_' ms.scale];
    ms.FAFB                         = 1;
    ms.rough_solve                  = 'rigid';
    runnow = 1;
    %%% submit rough alignment command
    [L2, needs_correction, pmfn, zsetd, zrange, t, dir_spark_work, cmd_str, fn_ids, ...
    target_solver_path, target_ids, target_matches, target_layer_images] =  ...
    ...
    solve_rough_slab(dir_store_rough_slab, rcmontage, ...
    rcmontage, rcrough, ms, nfirst,...
    nlast, dir_rough_intermediate_store, ...
    runnow);

    %% return the reference section to its original z value
    %resp = set_section_z_by_section_id(rcrough, L_rough.sectionID, rgh_lst(fix));
    %% merge the pieces
    resp = set_section_z_by_section_id(rcrough, L(vec(fix)).sectionID, L(vec(fix)).z);
    
    %%%% ingest the corrected section into the "Revision slab montage collection"
    % first we delete the section entirely
    resp = delete_renderer_section(rc_rev_montage_slab, redo_lst(fix));
    % second we ingest the assembled section into "Revision slab montage"
    L_sliced_section = Msection(rcrough, redo_lst(fix)); % read the correctly assembled pieces one more time
    resp_append = ingest_section_into_renderer_database(...
        L_sliced_section,rc_rev_montage_slab, rc, dir_temp_ingest,...
        1);
    
    %%%% ingest slab into [Revised montage collection] --> where all revision montages are stored for tps later
    % 
    
    
end
%delete_renderer_stack(rcmontage);



%%

%% ingestion
%     disp('ingesting');
%     % uncomment below to ingest into rcout
%     %% ingest into Renderer collection
%     disp('Deleting section');disp(L(fix).z);
%     resp = delete_renderer_section(rcout, L(fix).z);
%
%
%     opts.disableValidation = 1;
%     ntiles = numel(Ls1(fix).tiles);
%     Tout = zeros(ntiles,6);
%     tiles = Ls1(fix).tiles;
%     for tix = 1:ntiles
%        Tout(tix,:) = tiles(tix).tform.T(1:6)';
%     end
%     tIds = cell(ntiles,1);
%     for tix = 1:ntiles
%      tIds{tix} = Ls1(fix).tiles(tix).renderer_id;
%     end
%     z_val = zeros(ntiles,1);
%     for tix = 1:ntiles
%      z_val(tix)= Ls1(fix).tiles(tix).z;
%     end
%
%     disp('Ingesting data .....');
%     disp('... export to MET ');
%
%     v = 'v1';
% %     if stack_exists(rcout)
% %         resp = create_renderer_stack(rcout);
% %     end
% %     if ~stack_exists(rcout)
% %         disp('.... target collection not found, creating new collection in state: ''Loading''');
% %         resp = create_renderer_stack(rcout);
% %     end
%
%     chks = round(ntiles/4);
%     cs = 1:chks:ntiles;
%     cs(end) = ntiles;
%     disp(' .... ingesting ....');
%
%     parfor ix = 1:numel(cs)-1
%         disp(ix);
%         vec = cs(ix):cs(ix+1);
%         export_to_renderer_database(rcout, rc, dir_temp_ingest, Tout(vec,:),...
%             tIds(vec), z_val(vec), v, opts.disableValidation);
%     end
%
%




%     %% complete stack
%     disp(' .... completing stack...');
%     resp = set_renderer_stack_state_complete(rcout);
%     disp('.... done!');
%     diary off;
