%%% generate set of rough alignment jobs and store data for later use.


%% general configuration

clc; %clear all;

% configure source collection
rcsource.stack          = 'v12_acquire_merged';
rcsource.owner          ='flyTEM';
rcsource.project        = 'FAFB00';
rcsource.service_host   = '10.37.5.60:8080';
rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
rcsource.verbose        = 1;

% configure montage collection
rctarget_montage.stack          = ['EXP_dmesh_montage_P1_peg'];
rctarget_montage.owner          ='flyTEM';
rctarget_montage.project        = 'test';
rctarget_montage.service_host   = '10.37.5.60:8080';
rctarget_montage.baseURL        = ['http://' rctarget_montage.service_host '/render-ws/v1'];
rctarget_montage.verbose        = 1;

% configure montage-scape point-match generation
ms.service_host                 = rctarget_montage.service_host;
ms.owner                        = rctarget_montage.owner;
ms.project                      = rctarget_montage.project;
ms.stack                        = rctarget_montage.stack;
ms.fd_size                      = '10'; % '8'
ms.min_sift_scale               = '0.2';%'0.55';
ms.max_sift_scale               = '1.0';
ms.steps                        = '3';
ms.similarity_range             = '15';
ms.skip_similarity_matrix       = 'y';
ms.skip_aligned_image_generation= 'y';
ms.base_output_dir              = '/nobackup/flyTEM/spark_montage';

ms.script                       = '/groups/flyTEM/home/khairyk/EM_aligner/renderer_api/generate_montage_scape_point_matches.sh';%'../unit_tests/generate_montage_scape_point_matches_stub.sh'; %
ms.number_of_spark_nodes        = '2.0';

dir_rough_intermediate_store = '/nobackup/flyTEM/khairy/FAFB00v13/montage_scape_pms';

%% generate scales and slabs


%%% calculate rough alignment, solve and generate renderer collection

nfirst = [ 1   20     40   120    250    500   750   1000   1150  1300  1450  1600     1750  1950   2100   2250  2400  2550  ...
         2700  2850  3000  3150  3300 3450:150:5400];
      
      
nlast =  [35   45    150   300    550    800   1050  1200   1350  1500  1650  1800     2000  2150   2300   2450  2600  2750   ...
          2900 3050   3200 3350  3500 3650:150:5650];
      
      
scale = [0.1   0.1   0.07  0.06  0.06    0.055 0.05  0.035  0.035 0.035 0.035 0.035   0.035  0.035  0.035  0.035 0.030 0.030  ...
        0.030  0.03  ones(1,17)*0.3];
    
    
failed = [];
for ix = 6:6%numel(scale)
    kk_clock;
    % configure rough collection
    rctarget_rough.stack          = ['PROD_ROUGH_MP1_RR_' num2str(nfirst(ix)) '_' num2str(nlast(ix))];
    rctarget_rough.owner          ='flyTEM';
    rctarget_rough.project        = 'test2';
    rctarget_rough.service_host   = '10.37.5.60:8080';
    rctarget_rough.baseURL        = ['http://' rctarget_rough.service_host '/render-ws/v1'];
    rctarget_rough.verbose        = 1;
    
    ms.first                        = num2str(nfirst(ix));
    ms.last                         = num2str(nlast(ix));
    ms.scale = num2str(scale(ix));
    ms.run_dir                      = ['scale_' ms.scale];
    
    run_now = 1;
    disp(['-------------------- Processing slab: ' num2str(nfirst(ix)) ' to ' num2str(nlast(ix)) ' at scale ' num2str(scale(ix))]);
%    try
    [L2, needs_correction, pmfn, zsetd, zrange, t, dir_spark_work, cmd_str, fn_ids, ...
        target_solver_path, target_ids, target_matches, target_layer_images] =  ...
        ...
        solve_rough_slab(rcsource, ...
        rctarget_montage, rctarget_rough, ms, nfirst(ix), nlast(ix), dir_rough_intermediate_store, ...
        run_now);
%    catch err_rough
%        kk_disp_err(err_rough);
%        failed = [failed ix];
%    end
       
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     % look at the result (optional)
%     [Wbox, bbox, url] = get_slab_bounds_renderer(rctarget_rough);
%     Wboxr = [Wbox(1) Wbox(2)+Wbox(4)/2 Wbox(3) 10]; 
%     imout = [];
%     parfor imix = nfirst(ix):nlast(ix)
%         im = get_image_box_renderer(rctarget_rough, imix, Wboxr, 0.1);
%         imout(:,:,imix) = (im);
%         %disp(size(im));
%     end
%     imout = permute(imout, [3 2 1]);
%     imout = mat2gray(sum(imout,3));
%     imtool(imout(:,:));

 %       fix_section_pair_alignment(rctarget_rough, rcsource, 32,33, 0.1);
        
        
    %% [2'] correct if needed
    if needs_correction   %%%%%%%%%% manually correct
        failed = [failed ix];
        
         disp('Please interrup <ctrl-c> and proceed to manually set point correspondences');
        disp('generate images and then use cpselect(im1,im2)');
        disp('When done, set run-now to zeros and re-run generate_montage_scapes_SIFT_point_matches');
        pause;
        
        [~, ai] = sort(zrange(:,2),'ascend');
        disp('Available connected tiles:');
        disp(zrange(ai,:));
        
        % define point-match pairs that need to be connected
        c = [32 33];
        
        p = 1;
        im1 = imread(t(c(p,1)).path);
        im2 = imread(t(c(p,2)).path);
        cpselect(im1,im2);
        
        m1 = movingPoints;
        m2 = fixedPoints;
        
        
        %% try SURF first
        imp1  = detectSURFFeatures(im1, 'NumOctaves', 10,...
            'NumScaleLevels', 5,...
            'MetricThreshold', 1000);
        imp2  = detectSURFFeatures(im2, 'NumOctaves', 10,...
            'NumScaleLevels', 5,...
            'MetricThreshold', 1000);
        
        [f1, vp1]  = extractFeatures(im1,  p1);
        [f2, vp2]  = extractFeatures(im2,  p2);
            [m1, m2, ~]  = im_pair_match_features(f1, vp1, f2, vp2);
            showMatchedFeatures(im1,im2,m1,m2, 'montage', 'PlotOptions', {'ro', 'g+', 'w-'});h2 = findobj('Type', 'line');for lix = 1:numel(h2), set(h2(lix), 'LineWidth',2);end
        
            
            %% update matches.txt by filtering out occurrences of c(p,2)
            
            disp('Reading data ...');tic
            fid = fopen(target_ids,'r');if fid==-1, error('Failed to open stack layout file.');end
            IDS     = textscan(fid,'%u64%s', 'delimiter', '');
            fclose(fid);
            %%% typecast the uint64 to double to get actual z-values
            z = typecast(IDS{1}, 'double');
            IDS{1} = double(IDS{1});
            %% read point matches
            fid = fopen(target_matches,'r');if fid==-1, error('Failed to open stack layout file.');end
            MATCHES = textscan(fid,'%n%n%n%n%n%n', 'delimiter', '\t');
            fclose(fid);
            disp('Done!');
            
            
            %%%% remove all entries with id of misplaced tile
            srchix = IDS{1}(c(p,2));
            del_ix = [];
            for pmix = 1:size(MATCHES{1},1)
                if MATCHES{1}(pmix)==srchix || MATCHES{4}(pmix)==srchix
                    del_ix = [del_ix; pmix];
                end
            end
            for mix = 1:size(MATCHES,2)
            MATCHES{mix}(del_ix) = [];
            end
            
            pmfn = [target_matches '_modified.txt'];
            fid = fopen(pmfn,'w');
            for mix = 1:size(MATCHES{1},1)
                fprintf(fid, '%d\t%.13f\t%.13d\t%d\t%.13f\t%.13f\n', ...
                    MATCHES{1}(mix), MATCHES{2}(mix),MATCHES{3}(mix),...
                    MATCHES{4}(mix),MATCHES{5}(mix),MATCHES{6}(mix)); 
            end
            fclose(fid);
            
            
        %%% use cpselect for each image pair manually and append point-match file with new point-matches
        fid = fopen(pmfn, 'a+');
        
        str = '';
        for pix = 1:size(m1,1)
            str = [str sprintf('%.0f\t%.13f\t%.13f\t%.0f\t%.13f\t%.13f\n', ...
                t(c(p,1)).id, m1(pix,1), m1(pix,2), t(c(p,2)).id, m2(pix,1), m2(pix,2))];
        end
        
        fprintf(fid, '%s', str);
        fclose(fid);
        
        
        
        % manually run all corrections then re-run point-match generation
        run_now = 0;
    [L2, needs_correction, pmfn, zsetd, zrange, t, dir_spark_work, cmd_str, fn_ids, ...
        target_solver_path, target_ids, target_matches, target_layer_images] =  ...
        ...
        solve_rough_slab(rcsource, ...
        rctarget_montage, rctarget_rough, ms, nfirst(ix), nlast(ix), dir_rough_intermediate_store, ...
        run_now);
        
        
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    kk_clock;
end

%% %%%%%%%%%%%%%%%%%  fuse collections



% clc;clear all;
% 
% % configure source collection
% rcsource.stack          = 'v12_acquire_merged';
% rcsource.owner          ='flyTEM';
% rcsource.project        = 'FAFB00';
% rcsource.service_host   = '10.37.5.60:8080';
% rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
% rcsource.verbose        = 1;
% 
% % configure rough collection
% rcfixed.stack          = ['EXP_dmesh_rough_P1_1_45_fused'];
% rcfixed.owner          ='flyTEM';
% rcfixed.project        = 'test';
% rcfixed.service_host   = '10.37.5.60:8080';
% rcfixed.baseURL        = ['http://' rcfixed.service_host '/render-ws/v1'];
% rcfixed.verbose        = 1;
% rcfixed.nfirst         = 1;
% rcfixed.nlast          = 45;
% 
% % configure rough collection
% rcmoving.stack          = ['EXP_dmesh_rough_P1_40_150'];
% rcmoving.owner          ='flyTEM';
% rcmoving.project        = 'test';
% rcmoving.service_host   = '10.37.5.60:8080';
% rcmoving.baseURL        = ['http://' rcmoving.service_host '/render-ws/v1'];
% rcmoving.verbose        = 1;
% rcmoving.nfirst         = 40;
% rcmoving.nlast          = 150;
% 
% % configure output collection
% rcout.stack          = ['EXP_dmesh_rough_P1_fused'];
% rcout.owner          ='flyTEM';
% rcout.project        = 'test';
% rcout.service_host   = '10.37.5.60:8080';
% rcout.baseURL        = ['http://' rcmoving.service_host '/render-ws/v1'];
% rcout.verbose        = 1;
% 
% overlap = [40 40];
% resp = fuse_collections(rcsource, rcfixed, rcmoving, overlap, rcout);
% 
% 






















