function generate_full_montages(sl, nfirst, nlast)
%% %% generate montages for range using qsub
% assumes input assembled in context similar to example below:
% fn = '/nrs/flyTEM/khairy/FAFB00v13/matlab_production_scripts/montage_input_2630_2641_FAFB_beautification.json';
% sl = loadjson(fileread(fn));
% sl.ncpus = 8;
% disp('Section montage process started');
% kk_clock();
% disp(['-------  Using input file: ' fn]);
% disp('-------  Using solver options:');disp(sl.solver_options);
% disp('-------  Using solver options:');disp(sl.SURF_options);
% 
% % configure source
% rcsource.stack          = 'v12_acquire_merged';
% rcsource.owner          ='flyTEM';
% rcsource.project        = 'FAFB00';
% rcsource.service_host   = '10.40.3.162:8080';
% rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
% rcsource.verbose        = 1;
% 
% sl.source_collection = rcsource;
% 
% nfirst= 2630;
% nlast = 2641;
% overlap = [nfirst nfirst+5 nlast-5 nlast];
% 
% montage_collection = rcsource;
% montage_collection.stack = ['Revised_slab_' num2str(nfirst) '_' num2str(nlast) '_montage'];
% montage_collection.project = 'FAFB00_beautification';
% sl.target_collection = montage_collection;    
% 
% 
% % configure rough
% rcrough.stack          = ['Revised_slab_' num2str(nfirst) '_' num2str(nlast) '_rough'];
% rcrough.owner          ='flyTEM';
% rcrough.project        = 'FAFB00_beautification';
% rcrough.service_host   = '10.40.3.162:8080';
% rcrough.baseURL        = ['http://' rcrough.service_host '/render-ws/v1'];
% rcrough.verbose        = 1;
% 
% dir_rough_intermediate_store = '/nobackup/flyTEM/khairy/FAFB00v13/montage_scape_pms';% intermediate storage of files
% dir_store_rough_slab = '/nobackup/flyTEM/khairy/FAFB00v13/matlab_slab_rough_aligned';
% scale  = 0.05;  
% 
% % configure fine alignment
% rcfine.stack          = ['Revised_slab_' num2str(nfirst) '_' num2str(nlast) '_fine'];
% rcfine.owner          ='flyTEM';
% rcfine.project        = 'FAFB00_beautification';
% rcfine.service_host   = '10.40.3.162:8080';
% rcfine.baseURL        = ['http://' rcrough.service_host '/render-ws/v1'];
% rcfine.verbose        = 1;
% 
% finescale = 0.4;
% nbrs = 3;
% point_pair_thresh    = 5;
% 
% pm.server = 'http://10.40.3.162:8080/render-ws/v1';
% pm.owner = 'flyTEM';
% pm.match_collection = 'v12_SURF';
% 
% sl.target_point_match_collection = pm;
% 
% rcfixed.stack          = 'FULL_FAFB_FUSED_05_ROTATED';
% rcfixed.owner          ='flyTEM';
% rcfixed.project        = 'FAFB00_beautification';
% rcfixed.service_host   = '10.40.3.162:8080';
% rcfixed.baseURL        = ['http://' rcfixed.service_host '/render-ws/v1'];
% rcfixed.verbose        = 1;
% 
% rcmoving = rcfine;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 
fn = ['temp_' num2str(nfirst) '_' num2str(nlast) '_' num2str(randi(10000)) '.json'];
for ix = nfirst:nlast
    sl.section_number = ix;
    jstr = savejson('', sl);
    fid = fopen(fn, 'w');
    fprintf(fid, jstr);
    fclose(fid);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
        % prepare qsub jobs
    jbname = sprintf('m_%d', ix);
    log_fn = sprintf('./log_%d.txt', ix);
       % prepare Matlab cache for this job
    cache_str = ['export MCR_CACHE_ROOT=' sl.scratch '/mcr_cache_root.' num2str(ix) ';mkdir -p $MCR_CACHE_ROOT'];
    mcr_root = [sl.scratch '/mcr_cache_root.' jbname];
    del_dir_mcr_root = sprintf('rm -rf %s', mcr_root);
    
    % prepare job qsub string
    str = sprintf('#!/bin/bash\n');
    str = [str sprintf('export matlabroot="/usr/local/matlab-2016b"\n')];
    str = [str sprintf('export PATH="$PATH:$matlabroot/bin"\n')];
    str = [str sprintf('export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$matlabroot/bin/glnxa64:$matlabroot/runtime/glnxa64:$matlabroot/sys/os/glnxa64:$matlabroot/sys/java/jre/glnxa64/jre/lib/amd64/native_threads:$matlabroot/sys/java/jre/glnxa64/jre/lib/amd64/server:$matlabroot/sys/java/jre/glnxa64/jre/lib/amd64" \n')]; 
    str = [str sprintf('%s;%s %s;%s', cache_str, sl.bin_fn,  fn, del_dir_mcr_root)];
    
    fnbash = [sl.scratch '/temp_' num2str(ix) '_' num2str(randi(10000)) '.sh'];
    
    disp(['Generating shell script: ' fnbash]);
    disp(str);
    % make a bash script that includes this command
    fid = fopen(fnbash, 'w');
    fprintf(fid, ['' str '']);
    fclose(fid);
    system(['chmod +x ' fnbash]);
    
    % generate qsub command to call the bash script
    str =  sprintf('qsub -b y -N %s -A flyTEM -j y -o %s -l d_rt=5400 -cwd -V -pe batch %d "%s;"\n',...
         jbname, log_fn, sl.ncpus, fnbash);
    % submit to cluster
    system(str)
    disp(str);
    

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %montage_section_SL_prll(fn);
    %delete(fn);
end