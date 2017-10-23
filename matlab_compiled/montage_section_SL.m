function montage_section_SL(fn)
% Intended for deployment: 
% generate montage based on json input provided by fn


% read json input
sl = loadjson(fileread(fn));

if sl.verbose,
    disp('Section montage process started');
    kk_clock();
    disp(['Using input file: ' fn]);
    disp(['Montage section:' num2str(sl.section_number)]);
    disp('Using solver options:');disp(sl.solver_options);
    disp('Using source collection:');disp(sl.source_collection);
    disp('Using target collection:');disp(sl.target_collection);
end

L                = Msection(sl.source_collection, sl.section_number);   % instantiate Msection object using the Renderer service to read tiles
L.dthresh_factor = 1.2;                             % factor x tile diagonal = search radius. increase this paramter to cover a wider radius of tile-tile comparisons
%%% update scratch and Renderer information
for tix = 1:numel(L.tiles)
    L.tiles(tix).dir_temp_render = sl.scratch;
    L.tiles(tix).renderer_client = sl.renderer_client;
end
if sl.verbose
    disp('section data imported --- registration initiated');
    disp(['Found ' num2str(numel(L.tiles)) ' tiles']);
end



%%%%%%% start parallel pool
% delete(gcp('nocreate'));
% if sl.verbose, disp('Starting parallel pool');end
% 
%       %defaultProfile = parallel.defaultClusterProfile;
%       %myCluster = parcluster(defaultProfile);
%       %parpool(myCluster);
%       parpool(12);
%       poolobj = gcp('nocreate');
% if sl.verbose, disp(['Parallel pool created. Pool size: ' num2str(poolobj.NumWorkers)]);end
    
if sl.verbose, disp('Starting registration process');end
if sl.verbose,
kk_clock();
tic;
end
[mL, ~]          = register(L);                    % perform the actual registration
if sl.verbose,
toc
kk_clock();
end
% if sl.verbose, disp('Deleting parallel pool');end
% delete(poolobj);


if sl.verbose
    disp('Section montage finished --- Ingesting into target collection');
end

%% ingest into Renderer database (optional);
delete_renderer_stack(sl.target_collection); 
if ~(stack_exists(sl.target_collection))
    disp('Target stack does not exist: creating and then ingesting');
    create_renderer_stack(sl.target_collection);
end
ingest_section_into_LOADING_collection(mL, sl.target_collection,...
                                       sl.source_collection, pwd, 1); % ingest
resp = set_renderer_stack_state_complete(sl.target_collection);  % set to state COMPLETE

if sl.verbose
    disp(resp);
    disp('Finished montage and ingestion');
    kk_clock();
end