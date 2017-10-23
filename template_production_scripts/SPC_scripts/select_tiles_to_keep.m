%%%% select subset of tiles of a section
clear all;clc
%% configure

% source stack for sections
rc.stack          = 'v2_rough';
rc.owner          ='flyTEM';
rc.project        = 'spc';
rc.service_host   = '10.40.3.162:8080';
rc.baseURL        = ['http://' rc.service_host '/render-ws/v1'];

% output stack with only selected tiles
% rcout.stack          = ['v2_rough_reduced'];
% rcout.stack          = 'v2_rough_try_7_slab_g_reduced';
rcout.stack          = 'v2_rough_gm_4000_4563';
rcout.owner          ='flyTEM';
rcout.project        = 'spc';
rcout.service_host   = '10.40.3.162:8080';
rcout.baseURL        = ['http://' rcout.service_host '/render-ws/v1'];

% where are the source image montage-scapes?
dir_source_images = '/nrs/spc/matlab_work/rough/v2_rough_manual/layer_images';
dir_temp_ingest = '/groups/spc/spc/scratch';

%% load sections and associate (load) mosaic images
fn = dir([dir_source_images '/*.png'] );
scale = 0.04;
zid  = {};
for fix = 1:numel(fn)
    zid{fix} = fn(fix).name(1:end-4);
end

L(numel(fn)) = Msection;
%% % Specify set of sections to work on. 
%%%% sections to be redone:
redo_lst = [2777:2791];


redo_lst = [4033:4047];
redo_lst = [4311 4392 4428 4485 4486 4492 4493];
redo_lst = [3879 3880 3882:3886];

redo_lst = [];
redo_lst = [4539:4541];
z_num = str2double(zid);
indx_redo = [];
for ix = 1:numel(redo_lst)
    ix
    indx_redo(ix) = find(z_num==redo_lst(ix));
end
vec = indx_redo;

%note that loading and saving the images for all sections can cause memory problems
vec = 1:4;
vec = 5:50;
vec = 51:200;
vec = 194:200;
vec = [indx_redo 395:400];

vec = 574:600;
vec = 713:1000;
% vec = 1:numel(fn);
% Gayathri: use range 1730:numel(fn)

%% this can take some time --- don't go overboards with the range of vec
for fix = vec
    L(fix) = Msection(rc, str2double(zid{fix}));
    L(fix).mosaic = imread([dir_source_images '/' fn(fix).name]);
end

%%
% % select tiles manually: Figure opens and tile boxes appear. Make selection
% of tiles to keep, as soon as mouse is released the selected tiles will be ingested
% in case of mistake, ctrl-c, then record the value of fix, and set vec to start from 
% current section to be repeated. then run only this current Matlab code section
% with the for loop below.
for fix = vec
    % show the user tiles and montage-scape
    clf;
    show_map_with_mosaic(L(fix), scale);title([ num2str(fix) ' -- ' num2str(L(fix).z)]);
    [pl,xs,ys] = selectdata('sel','lasso');  % the user can select tiles
    % do we need to have a wait state here?
    
    
    handles.x = vertcat(xs{:});
    handles.y = vertcat(ys{:});
    hold on;
    plot(handles.x, handles.y,'y*'); % plot to confirm selection to user
    drawnow;pause(2);
    %% determine the selected tiles
    tix = zeros(numel(handles.x),1);
    for pix = 1:numel(handles.x)
        tix(pix) =get_tile_index(L(fix), handles.x(pix), handles.y(pix));
    end
    tix = unique(tix);
    Ls1(fix) = Msection(L(fix).tiles(tix));
    
    disp(fix);
    disp('ingesting');
    % uncomment below to ingest into rcout
    %% ingest into Renderer collection
    disp('Deleting section');disp(L(fix).z);
    resp = delete_renderer_section(rcout, L(fix).z);
    
    
    opts.disableValidation = 1;
    ntiles = numel(Ls1(fix).tiles);
    Tout = zeros(ntiles,6);
    tiles = Ls1(fix).tiles;
    for tix = 1:ntiles
       Tout(tix,:) = tiles(tix).tform.T(1:6)';
    end
    tIds = cell(ntiles,1);
    for tix = 1:ntiles
     tIds{tix} = Ls1(fix).tiles(tix).renderer_id;
    end
    z_val = zeros(ntiles,1);
    for tix = 1:ntiles
     z_val(tix)= Ls1(fix).tiles(tix).z;
    end
    
    disp('Ingesting data .....');
    disp('... export to MET ');
    
    v = 'v1';
%     if stack_exists(rcout)
%         resp = create_renderer_stack(rcout);
%     end
%     if ~stack_exists(rcout)
%         disp('.... target collection not found, creating new collection in state: ''Loading''');
%         resp = create_renderer_stack(rcout);
%     end
    
    chks = round(ntiles/4);
    cs = 1:chks:ntiles;
    cs(end) = ntiles;
    disp(' .... ingesting ....');
    
    parfor ix = 1:numel(cs)-1
        disp(ix);
        vec = cs(ix):cs(ix+1);
        export_to_renderer_database(rcout, rc, dir_temp_ingest, Tout(vec,:),...
            tIds(vec), z_val(vec), v, opts.disableValidation);
    end
    
%     

end


%     %% complete stack
%     disp(' .... completing stack...');
%     resp = set_renderer_stack_state_complete(rcout);
%     disp('.... done!');
%     diary off;
