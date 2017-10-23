
%% configure montage --- please edit lines below
clc;
nfirst= 3279;
nlast = 3378;
fnsource = '/mydir/montage_input.json'; % template input json file
bin_fn = '/mydir/montage_section_SL_prll';   % where is the executable
montage_collection.stack = ['SURF_' num2str(nfirst) '_' num2str(nlast) '_kk_montage'];
local_scratch = '/scratch/myscratch';


%% preparations
sl = loadjson(fileread(fnsource));
sl.target_collection.stack = montage_collection.stack;
dir_scratch = [sl.scratch '/temp_' num2str(randi(10000))];
kk_mkdir(dir_scratch);
cd(dir_scratch);

%% generate job commands and submit

for ix = nfirst:nlast
    disp('------------------------------ montage section:');
    disp(ix);
    disp('-----------------------------------------------');

    %%%% overrides json input
    sl.section_number = ix;
    sl.complete = 0;
    sl.ncpus = 4;
    %cd(dir_scratch);
    fn = [dir_scratch '/temp_' num2str(randi(10000)) '_' num2str(ix) '.json'];
    disp(fn);
    % generate json file for this montage run
    jstr = savejson('', sl);
    fid = fopen(fn, 'w');
    fprintf(fid, jstr);
    fclose(fid);
    

    %%%% uncomment code block to use qsub and distribute over cluster
    % prepare qsub jobs
    jbname = sprintf('m_%d', ix);
    log_fn = sprintf('./log_%d.txt', ix);
    % prepare Matlab cache for this job: Without this step, only a limited number of deployed jobs is possible to run concurrently
    cache_str = ['export MCR_CACHE_ROOT=' local_scratch '/mcr_cache_root.' num2str(ix) ';mkdir -p $MCR_CACHE_ROOT'];
    mcr_root = [dir_scratch '/mcr_cache_root.' jbname];
    del_dir_mcr_root = sprintf(';rm -rf %s', mcr_root);
    
    % prepare job qsub string
    str = sprintf('%s;qsub -N %s -A spc -j y -o %s -l d_rt=1200 -cwd -V -b y -pe batch %d "%s %s;%s"',...
        cache_str, jbname, log_fn, sl.ncpus,bin_fn, fn, del_dir_mcr_root);
    
    disp(str);
     [a resp] = system(str);
     disp(a);disp(resp);



    %%%% uncomment code block if non-deployed version should be called
    %montage_section_SL_prll(fn);
    %delete(fn);
end

%% when all jobs are finished, complete the stack.
%resp = set_renderer_stack_state_complete(sl.target_collection);
