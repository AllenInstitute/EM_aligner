function [resp] = fuse_collections_insert_slab(rcsource, rcfixed, rcmoving, overlap, complete)
%%% insert existing rcmoving slab into larger rcfixed slab
%%% input: fixed collection
%%%        moving collection
%%%        section overlap

% % % example:
% % rcsource.stack          = ['v12_acquire_merged'];
% % rcsource.owner          ='flyTEM';
% % rcsource.project        = 'FAFB00';
% % rcsource.service_host   = 'tem-services.int.janelia.org:8080';
% % rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
% % rcsource.verbose        = 1;
% % 
% % 
% % 
% % rcfixed.stack          = ['FULL_FAFB_FUSED_05_ROTATED'];
% % rcfixed.owner          ='flyTEM';
% % rcfixed.project        = 'test2';
% % rcfixed.service_host   = '10.40.3.162:8080';
% % rcfixed.baseURL        = ['http://' rcfixed.service_host '/render-ws/v1'];
% % rcfixed.verbose        = 1;
% % 
% % 
% % rcmoving.stack          = ['Revised_slab_1185_1204_fine'];
% % rcmoving.owner          ='flyTEM';
% % rcmoving.project        = 'test';
% % rcmoving.service_host   = '10.40.3.162:8080';
% % rcmoving.baseURL        = ['http://' rcmoving.service_host '/render-ws/v1'];
% % rcmoving.verbose        = 1;
% % 
% % 
% % overlap = [1185 1190 1200 1204];
if nargin<5, complete = 1; end
%% read range
disp('Reading section id ranges...');
[zu1, sID1, sectionId1, z1, ns1] = get_section_ids(rcfixed, overlap(1), overlap(2));
[zu2, sID2, sectionId2, z2, ns2] = get_section_ids(rcmoving, overlap(1), overlap(2));

[zu3, sID3, sectionId3, z3, ns3] = get_section_ids(rcfixed, overlap(3), overlap(4));
[zu4, sID4, sectionId4, z4, ns4] = get_section_ids(rcmoving, overlap(3), overlap(4));
zu1 = [zu1 zu3];
zu2 = [zu2 zu4];
disp('Done!');
%% find corresponding tile centers
disp('Building list of corresponding tile centers...');
tic
X1 = {};
Y1 = {};
X2 = {};
Y2 = {};
Tvec =  zeros(numel(zu1),9);
for zix = 1:numel(zu1)
    [x1, y1, tids1] = get_tile_centers(rcfixed, zu1(zix));
    [x2, y2, tids2] = get_tile_centers(rcmoving, zu2(zix));
    [~,ia,ib] = intersect(tids1,tids2);
    X1{zix} = [x1(ia)'];
    Y1{zix} = [y1(ia)'];
    X2{zix} = [x2(ib)'];
    Y2{zix} = [y2(ib)'];
    a = [x1(ia) y1(ia)];
    b = [x2(ib) y2(ib)];
    warning off;[tform] = cp2tform(b, a, 'nonreflective similarity');warning on;
    t = [tform.tdata.T];
    Tvec(zix,:) = t(1:9);
end
X1 = cell2mat(X1)';
Y1 = cell2mat(Y1)';
X2 = cell2mat(X2)';
Y2 = cell2mat(Y2)';

toc
disp('Done!');
% Tvec = sum(Tvec)/size(Tvec,1);
% T = reshape(Tvec(end,:), 3, 3);
%
% scale = sqrt(T(1).^2 + T(1,2).^2);
% theta = atan(T(2,1)/T(1));
% R = [cos(theta) -sin(theta);sin(theta) cos(theta)];
% T(1:2,1:2) = R;

%% % sosi
% L = Msection(rcfixed, 1);
% rc = rcfixed;
% rc.stack = 'EXP_dmesh_section_one';
% ingest_section_into_renderer_database_overwrite(L,rc, rcsource, pwd, 1);
% Lr= Msection(rc,1);
% delete_renderer_stack(rc);
%% sosi --- visualize
% figure;plot(X1, Y1, 'b*');drawnow;pause(1);hold on;plot(X2,Y2,'r*');
%% find rotation/translation to overlap tile centers
% disp('Determining rotation and translation based on overlap region.....');
A = [X1 Y1];
B = [X2 Y2];
% warning off;[tform] = cp2tform(B, A, 'nonreflective similarity');warning on;
% T = tform.tdata.T;
% disp('Done!');


assert(size(A,1)==size(B,1));
centroid_A = mean(A);
centroid_B = mean(B);
% disp('-- Building linear system for rotation');
N = size(A,1);
H = (A-repmat(centroid_A,N,1))' * (B-repmat(centroid_B,N,1));
[U,S,V] = svd(H);
R = V*U';
if det(R)<0  % detect reflection special case
    V(:,1) = V(:,1) * (-1);
    R = V*U';
end
disp('-- building linear system for translation');
% find translation
% t = -R*centroid_A' + centroid_B';
% T = R;
% T2 = zeros(3,3);
% T2(3,3) = 1;
% T2([3 6]) = -t(:)';
%
U = [X1 Y1];% + repmat(t(:)', length(X1),1);
V = [X2 Y2] *R;
warning off; x = ones(length(X1),2)\(V-U);warning on;
V = V - repmat(x(1,:), length(X1),1);
T2 = zeros(3,3);
T2(3,3) = 1;
T2([3 6]) = x(1,:);
%% inspect result:

% % %
% figure;
% A = [X1 Y1];
% B = [X2 Y2];
%
% plot(A(:,1), A(:,2), '*b');
% hold on;


% [Btx, Bty] = tformfwd(tform, B(:,1), B(:,2));
%plot(Btx, Bty, '*r');

%
%
% figure;
% [x1, y1, tids1, L1, cm1] = get_tile_centers(rcfixed, zu1(1), 0);
% show_map(L1);drawnow; % first overlap section of fixed
% hold on;
% plot(x1, y1, '*b');
%
%
% figure;
% [x2, y2, tids2, L2, cm2] = get_tile_centers(rcmoving, zu2(1), 0);
% show_map(L2);drawnow; % first overlap section of fixed
% hold on;
% plot(x2, y2, '*b');
%%
% figure;
%  A = [X1 Y1];
%  B = [X2 Y2];
%
% plot(A(:,1), A(:,2), '*b');
% hold on;
%  [tform] = cp2tform(B, A, 'nonreflective similarity');
% Btr = [B ones(size(B,1),1)]*tform.tdata.T(1:3,1:3) ;% + repmat(tform.tdata.T([3 6]), size(B,1),1);
% plot(Btr(:,1), Btr(:,2), '*r');
% [Btx Btr(:,1)]
%% read collections --- (L11) L12 L21 L22

tic
disp('Reading tile collections ...');

disp('-- Overlap region of fixed collection.');
[~, tiles12_1] = get_slab_tiles(rcfixed, overlap(1), overlap(2));
[~, tiles12_2] = get_slab_tiles(rcfixed, overlap(3), overlap(4));
tiles12 = [tiles12_1;tiles12_2];

disp('-- Overlap region of moving collection.');
[~, tiles21_1] = get_slab_tiles(rcmoving, overlap(1), overlap(2));
[~, tiles21_2] = get_slab_tiles(rcmoving, overlap(3), overlap(4));
tiles21 = [tiles21_1;tiles21_2];

disp('-- Non-overlap region of moving collection.');
[~, tiles22] = get_slab_tiles(rcmoving, overlap(2)+1, overlap(3)-1);

disp('Done!');
toc

%% transform all rcmoving
tic
disp('Applying transformations to moving tiles...');
% initialize transformed tile arrays
tiles21t = tiles21;
tiles22t = tiles22;

% H = tiles21(1).H;
% W = tiles21(1).W;
%
% % assemble full trnsformation matrix rotation and translation
Tr = zeros(3,3);Tr(3,3) = 1;
Tr(1:2,1:2) = R;
delta = [0 0];
T3 = T2;
T3([3 6]) = T3([3 6]) + delta;
T = -T3  + Tr;
T(3,3) = 1;


% apply transformations to overlap region

% zvals = [tiles21t(:).z];
% for zix = 1:numel(zu1)
%     indx = find(zvals==zu1(zix));
%     tt = reshape(Tvec(zix,:),3,3);
%     for tix = 1:numel(indx)
%
%         tiles21t(indx(tix)).tform.T = tiles21t(indx(tix)).tform.T *tt;
%     end
% end


% apply transformations to overlap region
for tix = 1:numel(tiles21)
    tiles21t(tix).tform.T = tiles21(tix).tform.T *T;
    
end

% apply to non-ovelap moving region
for tix = 1:numel(tiles22t)
    tiles22t(tix).tform.T = tiles22t(tix).tform.T *T;
end

L21t = Msection(tiles21t);
L22t = Msection(tiles22t);
disp('Done!');
toc
%% rescale global
% if collection_start,
%     jtiles = [tiles11(:)' tiles21t(:)' tiles22t(:)'];
%     [zu] = [1:rcmoving.nlast];
% else
%     jtiles = [tiles21(:)' tiles22t(:)'];
%     [zu] = get_section_ids(rcmoving, overlap(1), rcmoving.nlast);
% end
%
% [mA, mAfit] = calculate_mean_tile_areas_by_section_and_fit(jtiles, zu);
%
% % apply rescaling to tiles
% zval = [jtiles(:).z];
% for zix = 1:numel(zu)
%     indx = find(zvals==zu(zix));
%     tt = [1/mAfit(zix) 0 0; 0 1/mAfit(zix) 0; 0 0 1];
%     if zu(zix)<=overlap(2)
%         for tix = 1:numel(indx)
%             tiles21t(indx(tix)).tform.T = tiles21t(indx(tix)).tform.T *tt;
%         end
%     else
%         for tix = 1:numel(indx)
%             tiles22t(indx(tix)).tform.T = tiles22t(indx(tix)).tform.T *tt;
%         end
%     end
% end


%% inspect
% % apply transformations
% [x2, y2, tids2, L2] = get_tile_centers(rcfixed, zu2(1));
% for tix = 1:numel(tiles21)
%     tiles21t(tix).tform.T = tiles21(tix).tform.T *T;
% end
% figure;
%
% show_map(L2);drawnow; % first overlap section of fixed
% hold on;
% plot(x2, y2, '*b');
%% interpolate: tiles in L21t need to be modified to comply with interpolation
%
tic
disp('Interpolating tile transformations within overlap region...');
% % determine intersecting tiles for each section and interpolate
% [zu1, sID1, sectionId1, z1, ns1] = get_section_ids(rcfixed, overlap(1), overlap(2));
[zu2, sID2, sectionId2, z2, ns2] = get_section_ids(rcmoving, overlap(1), overlap(2));
dlambda = 1/numel(zu2);
lambda = 0;
del_ix = [];
L12 = Msection(tiles12);
for zix = 1:numel(zu2)
    %disp([zix zu2(zix) lambda]);
    zcurr = zu2(zix);
    tindx = find([tiles21t(:).z]==zcurr);
    for tix = 1:numel(tindx)
        if isKey(L12.map_renderer_id, tiles21t(tindx(tix)).renderer_id)
            ind1 = L12.map_renderer_id(tiles21t(tindx(tix)).renderer_id);
            %if zcurr==26, disp([tiles21t(tindx(tix)).tform.T(:)' - tiles12(ind1).tform.T(:)']);end
            tiles21t(tindx(tix)).tform.T(1:3,1:2) = tiles12(ind1).tform.T(1:3,1:2).* (1-lambda) +...
                tiles21t(tindx(tix)).tform.T(1:3,1:2).* lambda;
        else
            del_ix = [del_ix tindx(tix)];
        end
    end
    lambda = lambda + dlambda;
end
tiles21t(del_ix) = [];



[zu2, sID2, sectionId2, z2, ns2] = get_section_ids(rcmoving, overlap(3), overlap(4));
dlambda = 1/numel(zu2);
lambda = 0;
del_ix = [];
for zix = 1:numel(zu2)
    %disp([zix zu2(zix) lambda]);
    zcurr = zu2(zix);
    tindx = find([tiles21t(:).z]==zcurr);
    for tix = 1:numel(tindx)
        if isKey(L12.map_renderer_id, tiles21t(tindx(tix)).renderer_id)
            ind1 = L12.map_renderer_id(tiles21t(tindx(tix)).renderer_id);
            %if zcurr==26, disp([tiles21t(tindx(tix)).tform.T(:)' - tiles12(ind1).tform.T(:)']);end
            tiles21t(tindx(tix)).tform.T(1:3,1:2) = tiles12(ind1).tform.T(1:3,1:2).* (lambda) +...
                tiles21t(tindx(tix)).tform.T(1:3,1:2).* (1-lambda);
        else
            del_ix = [del_ix tindx(tix)];
        end
    end
    lambda = lambda + dlambda;
end
tiles21t(del_ix) = [];
disp('Done!');
toc

%%
disp('Assembling slab composed of transformed (and interpolated) sections ...');
 L = Msection([tiles21t(:)' tiles22t(:)']);
disp('Done!');


%% inspect rescaling

%[mA, mAfit] = calculate_mean_tile_areas_by_section_and_fit(L.tiles, zu);


%% inspection
% % close all;
% %%% compare result overlap(1) with original overlap(1) (in rcfixed)
% figure;
% zmL21t = split_z(L21t);
% show_map(zmL21t(1)); % first overlap section of moving
% %hold on;
% %plot(Btx, Bty, '*r');
%
% hold on;
% L12t = Msection(tiles12);
% ll12t = split_z(L12t);
% show_map(ll12t(1));drawnow; % first overlap section of fixed
% hold on;
% %plot(A(:,1), A(:,2), '*b');
%% export to collection
%%% ingest into renderer database as rough collection
tic
disp('Ingesting into renderer database using append.');
%resp = ingest_section_into_LOADING_collection(L,rcout, rcsource, pwd);
% disp('-- Translate to positive space');


%%

%     % %%%%%%%%%%%%%%%%%%%%% sosi -----> slow %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     disp('-- Splitting into sections to prepare for distributed ingestion');
%     zmL = split_z(L);
%     disp('-- Start distributed process to populate new renderer collection');
%     resp_append = {};
%     translate_to_positive_space = 0;
%     complete = 0;
%     parfor ix = 1:numel(zmL)
%         %disp(ix);
%         resp = ingest_section_into_renderer_database(zmL(ix), ...
%             rcout, rcsource, pwd, translate_to_positive_space, complete);
%     end
%     resp = set_renderer_stack_state_complete(rcout);
%     disp('Done!');
% 
%     % %%%%%%%%%%%%%%%%%%%%% just distribute MET file generation and ingestion %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rcout = rcfixed;
if ~stack_exists(rcout)
    disp('Target collection not found, creating new collection in state: ''Loading''');
    resp = create_renderer_stack(rcout);
end

if stack_complete(rcout)
    disp('Cannot append COMPLETE stack: setting state to LOADING');
    resp = set_renderer_stack_state_loading(rcout);
end

%%%% delete the affected section
disp('Removing affected sections completely from the fixed collection ----------------');
parfor six = overlap(1):overlap(4)
    try
    resp = delete_renderer_section(rcfixed, six,0);
    catch err_delete_section
        kk_disp_err(err_delete_section);
    end
end
disp('--------------------------------------------------------------------------------');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
resp = set_renderer_stack_state_complete(rcout);
if stack_complete(rcout)
    disp('Cannot append COMPLETE stack: setting state to LOADING');
    resp = set_renderer_stack_state_loading(rcout);
end

% export tiles to renderer;
alltiles = L.tiles;
chnks = {};
count = 1;
nc = 100;
ntiles = numel(alltiles);
nix = 1;
while count<ntiles
    if (count+nc-1)>ntiles
        chnks{nix} = count:ntiles;
    else
    chnks{nix} = count:count+nc-1;
    end
    %disp(chnks{nix});
    count = count + nc;
    nix = nix + 1;
end

%%
disp('Ingesting into renderer');
tic

z = [alltiles(:).z];
renderer_id = {alltiles(:).renderer_id};
tform = [alltiles(:).tform];
col = [alltiles(:).col];
row = [alltiles(:).row];
cam = [alltiles(:).cam];
path = {alltiles(:).path};
temca_conf = [alltiles(:).temca_conf];
state = [alltiles(:).state];

append_to_stack_jobs = {};
job_names = {};
job_wkdirs = {};
job_name = ['appendTo' rcout.stack];
if isfield(rcout, 'grid_account')
    grid_account = rcout.grid_account;
else
    grid_account = '';
end
if isfield(rcout, 'grid_user')
    grid_user = rcout.grid_user;
else
    grid_user = '';
end
parfor nix = 1:numel(chnks)
    indx = chnks{nix}; % indx is an array of indices into alltiles.
                       % Those tiles (i.e. alltiles(indx)) will be exported
    fn = [pwd '/X_A_' num2str(randi(100000000)) '_' num2str(nix) '.txt'];
    fid = fopen(fn,'w');
    for tix = 1:numel(indx)
        ind = (indx(tix));
        if state(ind)>=1          % only export those that are turned on
            fprintf(fid,'%d\t%s\t%d\t%.12f\t%.12f\t%.12f\t%.12f\t%.12f\t%.12f\t%d\t%d\t%d\t%s\t%d\n',...
                z(indx(tix)),...
                renderer_id{indx(tix)}, ...
                1, ...
                tform(ind).T(1), ...
                tform(ind).T(2), ...
                tform(ind).T(3), ...
                tform(ind).T(4), ...
                tform(ind).T(5), ...
                tform(ind).T(6), ...
                col(ind), ...
                row(ind), ...
                cam(ind), ...
                path{ind},...
                temca_conf(ind));
        end
    end
    fclose(fid);
    if isempty(grid_account)
        % upload TEM files in here
        resp_append = append_renderer_stack(rcout, rcsource, fn, 'v1');
        disp(resp_append)
        try
            delete(fn);
        catch err_delete,
            kk_disp_err(err_delete);
        end
    else
        % qsub TEM file upload
        [cmd] = get_append_renderer_cmd(rcout, rcsource, fn, 'v1');
        rm_fn_cmd = ['rm -f ' fn];
        local_cmd = [cmd ';' rm_fn_cmd];
        current_job_name = sprintf('%s_%d', job_name, nix); 
        job_names{nix} = current_job_name;
        job_log_dir = sprintf('fuse-logs/%s', rcmoving.stack);
        try 
            system(['mkdir -p ' pwd '/' job_log_dir]);
        catch err_md
            kk_disp_err(err_md);
        end
        submit_cmd = sprintf('qsub -N %s -A %s -cwd -e :%s -o :%s -pe batch 1 -l h_rt=3599 -b y "%s" ',...
                     current_job_name, grid_account, job_log_dir, job_log_dir, local_cmd);
        append_to_stack_jobs{nix} = submit_cmd;
        job_wkdirs{nix} = pwd;
    end
end

%% Submit append renderer stack jobs
if ~isempty(append_to_stack_jobs)
    disp('Submit append jobs')
    manage_jobs(grid_user, job_names, append_to_stack_jobs, job_wkdirs, 5, 300);
end

toc

%% Complete the stack
if complete
    disp('Complete stack')
    resp = set_renderer_stack_state_complete(rcout);
end
