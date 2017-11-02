function total_del = remove_small_adjacency_clusters(rc, pm, opts, cluster_thresh, nfirst, nlast)
% reads montage tiles for a given range and removes tiles in clusters
% smaller than cs. clusters are based on adjacency
% Example configuration
% rc.stack          = 'temp_work_568824_fine';
% rc.owner          ='flyTEM';
% rc.project        = 'FAFB00v14_kk';
% rc.service_host   = '10.40.3.162:8080';
% rc.baseURL        = ['http://' rc.service_host '/render-ws/v1'];
% rc.verbose        = 0;
% 
% pix  = 1;
% pm(pix).server = 'http://10.40.3.162:8080/render-ws/v1';
% pm(pix).owner = 'flyTEM';
% pm(pix).match_collection = 'FAFB_pm_7';%'v12_dmesh';%'FAFB_pm_7';
% 
% nfirst = 2178;
% nlast  = 2184;
% 
% dir_scratch = opts.dir_scratch; %'/scratch/khairyk';
% 
% opts.Width = 2160;  % used for point-match consistency filtering (assumes all tiles same size)
% opts.Height = 2560;
% opts.min_points = 3;
% opts.max_points = inf;
% opts.nbrs = 4;
% opts.xs_weight = 1.0;
% opts.filter_point_matches = 1;
% opts.pmopts.NumRandomSamplingsMethod = 'Desired confidence';
% opts.pmopts.MaximumRandomSamples = 5000;
% opts.pmopts.DesiredConfidence = 99.9;
% opts.pmopts.PixelDistanceThreshold = 1;
% 
% cluster_thresh = 9;  % clusters smaller than that will be deleted
set_to_complete = 0;
total_del = 0;
for ix = nfirst:nlast
    z = ix;
    disp(['Filtering out small clusters for section: ' num2str(z)]);
    try
        L = Msection(rc, z);
        
       
        %%%% load all available point-matches for this section
        [zu, sID, sectionId, z, ns] = get_section_ids(rc,...
            z, z);
        [T, map_id, tIds, z_val, r, c] = load_all_transformations(rc,...
            zu, opts.dir_scratch);
        
        [M, adj, W, np] = system_solve_helper_load_point_matches(...
            zu, opts, pm, map_id, ...
            sID, size(T,1), r, c);
        PM.M = M;
        PM.adj = adj;
        PM.W = W;
        PM.np = np;
        L.pm = PM; 
        
        %%%% to delete tiles based on point-match connectivity/clusters
        %         [L_vec, a] = reduce_to_connected_components(L, 1);
        %         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%% to delete based on adjacency
        H = L.tiles(1).H;
        W = L.tiles(1).W;
        L = update_XY(L);
        x1 = L.X(:);
        y1 = L.Y(:);
        %[x1, y1] = get_tile_centers_tile_array(L.tiles);
        a = [x1(:) y1(:)];%[obj.X(:) obj.Y(:)];
        d = pdist2(a,a);        % depends on statistic toolbox  -------- Sosi: not good for large numbers of tiles
        dthresh = sqrt(H^2 + W^2) * L.dthresh_factor;   % diagonal of the tile times factor
        L.A = sparse(triu(d<dthresh,1));
        L.G = graph(L.A, 'upper');
        b = conncomp(L.G, 'OutputForm', 'vector');  % generate logical clusters (connected components)
        bins = unique(b);
        clear c a L_vec ntiles ndel;
        ndel = 0;
        if numel(bins)>1
            for bix = 1:numel(bins)
                indx = b==bins(bix);
                if sum(indx)>cluster_thresh
                    L_vec(bix) = reduce_to_tile_subset(L, find(indx));
                else
                    L_vec(bix) = Msection(L.tiles(indx));
                end
                ntiles(bix) = sum(indx);
                
            end
            [a, c] = sort(ntiles, 'descend');
            L_vec = L_vec(c);
        else
            L_vec = L;
            a = numel(L.tiles);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        L_small = L_vec(a<cluster_thresh);
        for lix = 1:numel(L_small)
            ndel = ndel + numel({L_small(lix).tiles(:).renderer_id});
            resp = delete_renderer_tile(rc, {L_small(lix).tiles(:).renderer_id}, set_to_complete);
        end
        disp(['Removed ' num2str(ndel) ' tiles for section ' num2str(z)]);
        total_del = total_del + ndel;
    catch err_delete_section_tiles
        disp(ix);
        kk_disp_err(err_delete_section_tiles);
    end
end
%%% 
disp('resetting stack completion ....');
%set_renderer_stack_state_loading(rc);
set_renderer_stack_state_complete(rc);
disp('... done!');




