% Script to solve a FAFBv12 rough aligned slabs for an existing set of point matches
%
% Assumes that all the work for generating point-matches has been done
% at the tile level
%
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%%
%%[0] configure collections and prepare quantities
clc;kk_clock;
Slab_definition;
failed = [];
dir_temp = '/nobackup/flyTEM/khairy/FAFB00v13/matlab_slabs';

%%

for ix = [38:39]%nslabs
    nfirst = nfirstvec(ix);
    nlast  = nlastvec(ix);
    
    
    % configure source collection
    rcsource_rough                = rough_collection{ix};
    
    % configure align collection
    rctarget_align                  = fine_collection{ix};
    
    
    
    %%
    % configure solver
    opts.min_tiles = 20; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
    opts.degree = 1;    % 1 = affine, 2 = second order polynomial, maximum is 3
    opts.outlier_lambda = 1e2;  % large numbers result in fewer tiles excluded
    opts.solver = 'backslash';
    opts.min_points = 5;
    opts.nbrs = 4;
    opts.xs_weight = 1;
    opts.stvec_flag = 1;   % 0 = regularization against rigid model (i.e.; starting value is not supplied by rc)
    opts.distributed = 1;
    %%%%%
    opts.lambda = 10^(-2);
    opts.edge_lambda = 10^(-2);
    %%%%
    %     opts.base_collection = [];
    %     opts.conn_comp = 0;
    %     opts.use_peg = 0;
    %     opts.peg_weight = 1e-3;
    %     opts.peg_npoints = 5;
    %%
    try
        disp('---------------');
        disp('Processing:');
        disp(rcsource_rough);
        disp(ix);
        disp('---------------');
        
        %% read point-matches and filter them
        [L, tIds, PM, pm_mx, sectionId_load, z_load]  = ...
            load_point_matches(nfirstvec(ix), nlastvec(ix), rcsource_rough, pm, opts.nbrs, ...
            opts.min_points, opts.xs_weight); % disp(pm_mx{ix});
        
        ntiles = max(L.pm.adj(:));
        if ntiles~=numel(L.tiles)
            disp('Discrepancy between number of tiles and availability of point-matches');
        end
        
        disp('Filtering point-matches');
        L.pm = filter_pm(L.pm);
        
        % save starting
        disp('Saving starting slab');
        str = sprintf('save %s rcsource rctarget_align L nfirst nlast pm opts;',...
            ['Read_EXP_dmesh_rough_P1_' num2str(nfirstvec(ix)) '_' num2str(nlastvec(ix)) '.mat']);
        dir_curr = pwd;
        cd(dir_temp);
        eval(str);
        cd(dir_curr);
        
        %% start actual solver process
        if opts.degree==1
            disp('----------------- Solving using affine model:');
            tic
            [mL, err1, Res1, A, b, B, d, W, K, Lm, xout, LL2, U2, tB, td,...
                invalid] = solve_affine_explicit_region(L, opts);
            toc
            disp('Done!');
        else
            disp('----------------- Solving using polynomial degree:');
            tic
            disp(opts.degree);
            [mL, err1, Res1] =...
                solve_polynomial_explicit_region(L,opts.degree, opts);
            toc
            disp('Done!');
        end
        
        %          %         [mL, Af, Sf] = filter_based_on_tile_area(mL, opts.outlier_lambda);
        [mL, deformation, Ar, S] = tile_based_deformation(mL, 100);
        
        %         [mL, tpr, minconf, maxconf] = tile_based_point_pair_errors(mL, A, xout, j, [], []);
        %% sosi ------- inspect  for excessive deformation or point-match residuals
        %          j = 12;
        %
        %         figure
        %         [L2, minconf, maxconf] = tile_based_deformation(L,j , [], [], A, xout);
        %         figure
        %          [L, minconf, maxconf] = tile_based_deformation(L,j , minconf, maxconf, A, d);
        
        %% save solution
        try
            disp('Saving solution slab');
            kk_clock;
            dir_curr = pwd;
            cd(dir_temp);
            str = sprintf('save %s rcsource rctarget_align mL A d xout nfirst nlast pm opts err1 Res1 Ar deformation S;',...
                ['Solved_PRD_dmesh_fine_P1_' num2str(nfirst) '_' num2str(nlast) '_xs_2']);
            eval(str);
            
            str = sprintf('save %s Ar deformation S;',...
                ['Deformation_PRD_dmesh_fine_P1_' num2str(nfirst) '_' num2str(nlast) '_xs_2']);
            eval(str);
            
            
            cd(dir_curr);
            kk_clock;
            disp('Done!');
        catch err_saving
            disp('Didnt save');
        end
        %% %%% ingest affine solution
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













