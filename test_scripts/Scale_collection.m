% Script to rotate a colleciton
%
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%%
%% Step 0: configure 
nfirst = 1;
nlast  = 10;

s = 0.4;


clc;kk_clock;
tic
% configure rough collection
rc.stack          = 'FULL_FAFB_FUSED_05';
rc.owner          ='flyTEM';
rc.project        = 'test2';
rc.service_host   = '10.40.3.162:8080';
rc.baseURL        = ['http://' rc.service_host '/render-ws/v1'];
rc.verbose        = 1;

% configure fine output collection
rcout.stack          = ['FAFB_fused_1_10_scaled'];
rcout.owner          ='flyTEM';
rcout.project        = 'test2';
rcout.service_host   = '10.40.3.162:8080';
rcout.baseURL        = ['http://' rcout.service_host '/render-ws/v1'];
rcout.verbose        = 1;
rcout.versionNotes   = 'testing scaling 0.4';

opts.dir_scratch = '/scratch/khairyk';
%% Step 1: load transformations, tile ids
% load all tiles in this range and pool into Msection object
dir_scratch = [opts.dir_scratch '/temp_' num2str(randi(3000000))];
kk_mkdir(dir_scratch);
cd(dir_scratch);
diary on;
[zu, sID, sectionId, z, ns] = get_section_ids(rc, nfirst, nlast);
disp('Loading transformations and tile/canvas ids from Renderer database.....');
[T, ma, tIds, z_val] = load_all_transformations(rc, zu, dir_scratch);
ntiles = size(T,1);
disp(['..system has ' num2str(ntiles) 'tiles...']);
disp('....done!');diary off;diary on;
%% rotate

    %R = [cosd(deg) -sind(deg) 0; sind(deg) cosd(deg) 0; x y 1];
    S = [s 0 0; 0 s 0; 0 0 1];
    parfor tix = 1:size(T,1)
        t = T(tix,:);%[T(tix,1) T(tix,2) T(tix,3) T(tix,4) T(tix,5) T(tix,6)];
        t = reshape(t,3,2);
        t(3,3) = 1;
        Tr = t * S;
        t = Tr(1:3,1:2);
        T(tix,:) = t(:)';
    end
    
%% Step 5: ingest into Renderer database

disp('** STEP 5:   Ingesting data .....');
disp(' ..... translate to +ve space');
delta = -3000;
dx = min(T(:,3)) + delta;%mL.box(1);
dy = min(T(:,6)) + delta;%mL.box(2);
for ix = 1:size(T,1)
    T(ix,[3 6]) = T(ix, [3 6]) - [dx dy];
end

disp('... export to MET (in preparation to be ingested into the Renderer database)...');

v = 'v1';
if stack_exists(rcout)
    disp('.... removing existing collection');
    resp = create_renderer_stack(rcout);
end
if ~stack_exists(rcout)
    disp('.... target collection not found, creating new collection in state: ''Loading''');
    resp = create_renderer_stack(rcout);
end

chks = round(ntiles/64);
cs = 1:chks:ntiles;
cs(end) = ntiles;
disp(' .... ingesting ....');
parfor ix = 1:numel(cs)-1
    vec = cs(ix):cs(ix+1)-1;
    export_to_renderer_database(rcout, rc, dir_scratch, T(vec,:),...
                                tIds(vec), z_val(vec), v);
end


% % complete stack
disp(' .... completing stack...');
resp = set_renderer_stack_state_complete(rcout);
disp('.... done!');
diary off;
toc
kk_clock;
% delete_renderer_stack(rcout);








