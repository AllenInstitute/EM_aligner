% Example script to solve a FAFBv12 slab for an existing set of point matches
%
% Assumes that all the work for generating point-matches has been done
% at the tile level
%
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%% [0] configure collections and prepare quantities
clc;kk_clock;





nfirstvec = [ 1   20     40   120    250    500   750   1000   1150  1300  1450  1600     1750  1950   2100   2250  2400  2550  ...
         2700  2850  3000  3150  3300 3450:150:5400];
      
      
nlastvec =  [35   45    150   300    550    800   1050  1200   1350  1500  1650  1800     2000  2150   2300   2450  2600  2750   ...
          2900 3050   3200 3350  3500 3650:150:5650];
      
      
scale = [0.1   0.1   0.07  0.06  0.06    0.05  0.05  0.035  0.035 0.035 0.035 0.035   0.035  0.035  0.035  0.035 0.030 0.030  ...
        0.030  0.03  ones(1,17)*0.3];
    
    


failed = [];

dir_temp = '/nobackup/flyTEM/khairy/FAFB00v13/matlab_slabs';

%%

for ix = 5  %11:numel(scale)
    nfirst = nfirstvec(ix);
    nlast  = nlastvec(ix);
    %nlast  = 1200;
    
    % % configure source collection
    % rcsource.stack          = 'v12_acquire_merged';
    % rcsource.owner          ='flyTEM';
    % rcsource.project        = 'FAFB00';
    % rcsource.service_host   = '10.37.5.60:8080';
    % rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
    % rcsource.verbose        = 1;
    
    
    % configure source collection
    rcsource.stack          = ['PROD_ROUGH_MP1_RR_' num2str(nfirstvec(ix)) '_' num2str(nlastvec(ix))];
    rcsource.owner          ='flyTEM';
    rcsource.project        = 'test2';
    rcsource.service_host   = '10.37.5.60:8080';
    rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
    rcsource.verbose        = 1;
    
    % configure align collection
    rctarget_align.stack          = ['PROD_FINE_MP1_RR_P1_' num2str(nfirst) '_' num2str(nlast) '_xs_2'];
    rctarget_align.owner          = 'flyTEM';
    rctarget_align.project        = 'test2';
    rctarget_align.service_host   = '10.37.5.60:8080';
    rctarget_align.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
    rctarget_align.verbose        = 1;
    
    % configure point-match collection
    pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
    pm.owner            = 'flyTEM';
    pm.match_collection = 'v12_dmesh';
        
    %%
    % configure solver
    opts.min_tiles = 20; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
    opts.degree = 1;    % 1 = affine, 2 = second order polynomial, maximum is 3
    opts.outlier_lambda = 1e3;  % large numbers result in fewer tiles excluded
    opts.solver = 'backslash';
    opts.min_points = 5;
    opts.nbrs = 4;
    opts.xs_weight = 1;
    opts.stvec_flag = 0;   % 0 = regularization against rigid model (i.e.; starting value is not supplied by rc)
    opts.distributed = 0;
%%%%%
    opts.lambda = 10^(-1);
    opts.edge_lambda = 10^(-1);
%%%%
    opts.base_collection = [];
    opts.conn_comp = 0;
    opts.use_peg = 0;
    opts.peg_weight = 1e-3;
    opts.peg_npoints = 5;
%%
    try
        disp('---------------');
        disp('Processing:');
        disp(rcsource);
        disp('---------------');
        
        %% read point-matches and filter them
        [L, tIds, PM, pm_mx, sectionId_load, z_load]  = ...
            load_point_matches(nfirst, nlast, rcsource, pm, opts.nbrs, ...
            opts.min_points, opts.xs_weight); % disp(pm_mx{ix});
        
        ntiles = max(L.pm.adj(:));
        if ntiles~=numel(L.tiles)
            disp('Discrepancy between number of tiles and availability of point-matches');
        end
        
        
        L.pm = filter_pm(L.pm);
        
        % save
        str = sprintf('save %s rcsource rctarget_align L nfirst nlast pm opts;',...
            ['Read_EXP_dmesh_rough_P1_' num2str(nfirst) '_' num2str(nlast) '.mat']);
        dir_curr = pwd;
        cd(dir_temp);
        eval(str);
        cd(dir_curr);
        
        %% start actual solver process
        if opts.degree==1
            [mL, err1, Res1, A, b, B, d, W, K, Lm, xout, LL2, U2, tB, td,...
                invalid] = solve_affine_explicit_region(L, opts);
        else
            disp('----------------- Solving using polynomial degree:');
            disp(opts.degree);
            [mL, err1, Res1] =...
                solve_polynomial_explicit_region(L,opts.degree, opts);
            
        end
        
        [mL, Af, Sf] = filter_based_on_tile_area(mL, 1000);%opts.outlier_lambda);
        
        %% inspect (optional)
%         j = 28;
%         [L2, tpr1, minconf, maxconf] = tile_based_point_pair_errors(L, A, d, j, [], []);
%         figure;
%         [mL2, tpr2] = tile_based_point_pair_errors(mL, A, xout, j, minconf, maxconf);
%         figure
%         [mL3, minconf, maxconf] = tile_based_deformation(mL,j , [], [], A, xout);
%         figure
%          [mL3, minconf, maxconf] = tile_based_deformation(L,j , minconf, maxconf, A, d);
%         
%         
%         
        

        
%         Ro = K*d-Lm;
%         R1 = K*xout-Lm;
%         Ror = reshape(abs(Ro), 6,numel(L.tiles));
%         R1r = reshape(abs(R1), 6,numel(mL.tiles));
%         mx = max([R1r(:)']);
%         mn = min([R1r(:)']);
%         
%         
%         
%         Ror = 1-mat2gray(Ror, [mn mx]);
%         R1r = 1-mat2gray(R1r, [mn mx]);
% %         M = mat2gray([Ror;R1r]);
% %         Ror = M(1:6,:);
% %         R1r = M(7:12,:);
%         p = 1;
%         for tix = 1:numel(mL.tiles)
%             L.tiles(tix).confidence = (abs([Ror(p, tix)]));
%             mL.tiles(tix).confidence = (abs([R1r(p, tix)]));
%         end
% 
%         l = split_z(L);
%         ml = split_z(mL);
%         j = 28;
%         show_map_confidence(l(j), [1]);
%         figure;
%         show_map_confidence(ml(j), [1]);
%         
%         
%         ro = sum(reshape(abs(Ro), 6,numel(mL.tiles)));hist(ro, 100);
%         r1 = sum(reshape(abs(R1), 6,numel(mL.tiles)));figure;hist(r1(:), 100);
%         [~, ia] = sort(r1, 'descend');
%         
%         % remove spurious tiles
%         del_ix = find(r1>0.5 * 10000);
%         mL.tiles(del_ix) = [];
        
        
        %     npoints = size(A,1);
        %     nparms = size(A,2);
        %     nttiles = nparms/6;
        %     %%% determine residual per tile
        %     R = mat2gray(Res1);
        %     hist(Res1,1000);
        %
        %     disp('Error in pixels per tile:');
        %     disp(err1/numel(mL.tiles));
        


%         [~, iaf] = sort(Af, 'descend');
%         
%         
%         disp([ia(1:20)' iaf(1:20)']);
%         
%         %mL.tiles([mL.tiles(:).state]==-3) = [];
%         
%         
%        
%         
%         Ro = K*d-Lm;
%         R1 = K*xout-Lm;
%         
%         ro = sum(reshape(Ro.^2, 6,numel(mL.tiles)));hist(ro);
%         r1 = sum(reshape(R1.^2, 6,numel(mL.tiles)));
%         figure;hist([ro(:) r1(:)], 200);
        
        
        %%
        
        % save
        str = sprintf('save %s rcsource rctarget_align L nfirst nlast pm opts Af Sf err1 Res1;',...
            ['Solved_PRD_dmesh_fine_P1_' num2str(nfirst) '_' num2str(nlast) '_xs_2']);
        dir_curr = pwd;
        cd(dir_temp);
        eval(str);
        cd(dir_curr);
        %%%%% ingest affine solution
        try
            ingest_section_into_renderer_database_overwrite(mL, rctarget_align, rcsource, pwd, 1);
            %resp = set_renderer_stack_state_complete(rctarget_montage);
        catch err_ingesting
            
            disp(['Error ingesting affine: ' num2str(nfirst) ]);
            kk_disp_err(err_ingesting);
        end
        disp('Error in pixels per tile:');
        disp(err1/numel(mL.tiles));
    catch err_solving
        kk_disp_err(err_solving);
        failed = [failed ix];
    end
    %clear L mL err1 Res1
end

%% render optional
% w = 2000;
% h = 2000;
% Wbox = [62318-w/2 54676-h/2 w h];
% scale = 1.0;
% % z = 250;
% % [im, v, url] = get_image_box_renderer(rctarget_align, z, Wbox, scale);
% %  imshow(im);
% 
% % %
% im = zeros(Wbox(3)*scale, Wbox(4) * scale, numel([nfirst:nlast]));
% vec = [nfirst:nlast];
% vec = vec(:);
% parfor ix = 1:numel(vec)
%     disp(ix);
% %     try
%         im(:,:, ix)= get_image_box_renderer(rctarget_align, vec(ix), Wbox, scale);
% 
% %     catch err
% %         disp(['Err: ' num2str(ix)']);
% %     end
% end
% im = mat2gray(im);
% implay(im);
% 
% im1 = permute(im,[3 1 2]);
% imshow(im1(:,:,1));daspect([49 4 4]);













