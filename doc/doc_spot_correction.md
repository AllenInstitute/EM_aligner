## Prerequisites
We are assuming that the Renderer and point-match services (and associated database) are set up and accessible for example at http://tem-services.int.janelia.org.
Also, you are using Matlab 2016b and above with toolboxes: Computer Vision Systems (or Video and Blockset), ImageProcessing, Statistics, (optional) Matlab compiler and (optional) Parallel computing. The EM_aligner directory and subdirectories are on your Matlab path.

## Correcting a local issue with one or more full sections: re-solve locally (to correct) and ingest into same collection
Use this only if you have calculated a better point-match set for sections that need to be corrected, or wish to solve for a local range (one or more) sections within an existing collection but using a different set of parameters.
"system_solve_affine_with_constraints" can address the common issue with alignment quality that occurs when the point-match set is deficient or solve-parameters need to be different for a certain region.


An example to re-solve for sections sandwiched between sections 480 and 561 of FAFB:
In this case, alignment showed drifts in that region. We were able to observe this after materialzing (rendering) the whole collection. To get a better solution, a new point-match set was calculated (not shown here) for that range. Since we don't want to re-solve the whole collection (which is expensive and would force us to materialize the whole collection again), we use the code below to "patch" the collection by retaining all sections the way they are exactly, and only allowing sections within the specified range to re-align. The sandwich sections 480 and 561 (are so strongly constrained that they don't change at all, but sections in between are free to align and deform. A temporary collection is generated (and deleted) in the process.


```json

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% configure
diary on;
clc;kk_clock;

%%
%collection that stays mostly fixed and needs patching for subset of sections within a "sandwich" region
rcfixed.stack          = 'kk_13_pm7';
rcfixed.owner          ='flyTEM';
rcfixed.project        = 'FAFBv14_kk';
rcfixed.service_host   = '10.40.3.162:8080';
rcfixed.baseURL        = ['http://' rcfixed.service_host '/render-ws/v1'];
rcfixed.verbose        = 0;


% configure collection that will be used as a source for the less-constrained sections (this is usually the rough collection used for alignment)
rcmoving.stack          = ['pf5']; %
rcmoving.owner          ='flyTEM';
rcmoving.project        = 'FAFB00v14_kk';
rcmoving.service_host   = '10.40.3.162:8080';
rcmoving.baseURL        = ['http://' rcmoving.service_host '/render-ws/v1'];
rcmoving.verbose        = 0;

%set_renderer_stack_state_complete(rcfixed);
%% define individual sections that need fixing
% specify individual sections: nfirst nlast z_affected

c_vec = [ ...   
          480 561
          ];

ix = 1;
pm(ix).server = 'http://10.40.3.162:8080/render-ws/v1';
pm(ix).owner = 'flyTEM';
pm(ix).match_collection = 'FAFB_pm_7';
dir_scratch = '/scratch/khairyk';
kk_clock();

%% start the process
failed = [];
z_affected = [];
for cix = 1:size(c_vec,1)

    nfirst= c_vec(cix,1);
    nlast = c_vec(cix,2);
    z_affected = nfirst+1:nlast-1;
    disp('-------------------------------------------------');
    disp([nfirst z_affected nlast]);
    disp('-------------------------------------------------');
    %% step 1: Create a temporary collection with three sections
    
    rctemp.stack          = ['temp_work_' num2str(randi(1000000))];
    rctemp.owner          ='flyTEM';
    rctemp.project        = 'FAFB00v14_kk';
    rctemp.service_host   = '10.40.3.162:8080';
    rctemp.baseURL        = ['http://' rctemp.service_host '/render-ws/v1'];
    rctemp.verbose        = 0;
    create_renderer_stack(rctemp);
    
    % copy sections
    copy_renderer_section([nfirst nlast], rcfixed, rctemp, dir_scratch);
    copy_renderer_section(z_affected, rcmoving, rctemp, dir_scratch);
    set_renderer_stack_state_complete(rctemp);

    %% step 2: configure Affine fine alignment
    rcfine = rctemp;
    rcfine.stack = [rcfine.stack '_fine'];
    rcrough = rctemp;
    
    opts.transfac = 1e-7;  % translation parameter regidity
    opts.lambda = 10^(0); %  ------------------>
    opts.constrain_by_z = 1;
    opts.sandwich = 1;
    opts.constraint_fac = 1e15;
    opts.translate_to_positive_space = 0;
    
    % configure solver
    opts.degree = 1;    % 1 = affine, 2 = second order polynomial, maximum is 3
    opts.solver = 'backslash';%'pastix';%'bicgstab';% %%'gmres';%'backslash';'pastix';
   
    opts.nbrs = 5;
    opts.nbrs_step = 1;
    opts.xs_weight = 1.0;
    opts.min_points = 5;
    opts.max_points = inf;
    opts.filter_point_matches = 1;
    opts.outlier_lambda = 1e2;  % large numbers result in fewer tiles excluded
    opts.min_tiles = 2; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
    opts.pastix.ncpus = 8;
    opts.pastix.parms_fn = '/nrs/flyTEM/khairy/FAFB00v13/matlab_production_scripts/params_file.txt';
    opts.pastix.split = 1; % set to either 0 (no split) or 1
    opts.matrix_only = 0;   % 0 = solve , 1 = only generate the matrix
    opts.distribute_A = 16;  % # shards of A
    opts.dir_scratch = '/scratch/khairyk';
    
    % opts.stvec_flag = 1;   % 0 = regularization against rigid model (i.e.; starting value is not supplied by rc)
    opts.distributed = 0;
    opts.disableValidation = 0;
    opts.edge_lambda = opts.lambda;
    opts.use_peg = 0;
    
    % % configure point-match filter
    opts.pmopts.NumRandomSamplingsMethod = 'Desired confidence';
    opts.pmopts.MaximumRandomSamples = 5000;
    opts.pmopts.DesiredConfidence = 99.9;
    opts.pmopts.PixelDistanceThreshold = .1;
    opts.verbose = 1;
    opts.debug = 0;
    
    %%

    rcmoving.versionNotes = gen_versionNotes(opts);
    [err,R, Tout] = system_solve_affine_with_constraint(...
        nfirst, nlast, rcrough, pm, opts, rcfine);
    kk_clock;
    %% filter the added section
    filter_section_tiles(rcfine, rcrough, z_affected, dir_scratch, 1.0);
    set_renderer_stack_state_complete(rcfine);
    %% copy the fixed section back into rcfixed
    copy_renderer_section(z_affected, rcfine, rcfixed, dir_scratch);
   %% cleanup 
   delete_renderer_stack(rcrough);
   delete_renderer_stack(rcfine);

end
% %
if ~isempty(failed)
    disp('failed cases:');disp(failed);
end

set_renderer_stack_state_complete(rcfixed);



```


