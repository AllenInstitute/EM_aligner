## Prerequisites
We are assuming that the Renderer and point-match services (and associated database) are set up and accessible for example at http://tem-services.int.janelia.org.
Also, you are using Matlab 2016b and above with toolboxes: Computer Vision Systems (or Video and Blockset), ImageProcessing, Statistics, (optional) Matlab compiler and (optional) Parallel computing. The latest EM_aligner directory and subdirectories are on your Matlab path.




## use updated_diagnostics (recommended)
Calling updated_gen_diagnostics(rcsource, rc, zstart, zend, point_matches, options) will produce an output struct that has information about areas, perimeters and residuals that can be useful for diagnosing issues in sections. 
[Consult pdf file for more information] (UpdatedDiagnosticsTools.pdf).

## generate general diagnostics about tile deformation and point-match residuals


After montage, rough alignment, fine alignment or to optimize solver parameters, it is often required to get a general idea about the extent of tile deformation within a section or group of sections. Also, it is important to identify the magnitude of point-match residuals post-solve (for example compared to pre-solve, or rough alignment). For more difficult stitching tasks, the number of tiles identified as outliers (whether through deformation or point-match residuals) provides a quick way of homing in on troublesome sections and even removing trouble-maker tiles.

Below is an example of using the function "gen_diagnostics.m" to display a summary table of stitching quality and identify outlier tiles


------------------------------------------- Example -----------------------------
```json
% solver options
sl.solver_options.degree                = 1;
sl.solver_options.solver                = 'backslash';
sl.solver_options.min_points            = 10;
sl.solver_options.max_points            = 100;
sl.solver_options.lambda                = 0.1;              % regularization parameter
sl.solver_options.edge_lambda           = 0.1;
sl.solver_options.translation_fac       = 1;
sl.solver_options.use_peg               = 1;                % peg
sl.solver_options.peg_weight            = 1e-2;             % peg
sl.solver_options.peg_npoints           = 10;                % peg

sl.solver_options.outlier_lambda        = 1000;
sl.solver_options.small_region          = 5;
sl.solver_options.calc_confidence       = 1;
sl.solver_options.small_region_lambda   = 10;
sl.solver_options.stvec_flag            = 0;
sl.solver_options.conn_comp             = 1;
sl.solver_options.distributed           = 0;
sl.solver_options.min_tiles             = 3;

% configure source collection
sl.source_collection.stack          = 'v12_acquire_merged';
sl.source_collection.owner          = 'flyTEM';
sl.source_collection.project        = 'FAFB00';
sl.source_collection.service_host   = '10.37.5.60:8080';
sl.source_collection.baseURL        = 'http://10.37.5.60:8080/render-ws/v1';
sl.source_collection.verbose        = 0;

% configure target collection
sl.target_collection.stack          = 'Revised_FAFB_montage_kk';
sl.target_collection.owner          = 'flyTEM';
sl.target_collection.project        = 'FAFB00_beautification';
sl.target_collection.service_host   = '10.37.5.60:8080';
sl.target_collection.baseURL        = 'http://10.37.5.60:8080/render-ws/v1';
sl.target_collection.versionNotes   = 'Created using script /mypath/myscript.m';
sl.target_collection.verbose        = 0;
sl.target_collection.complete       = 0;
sl.target_collection.initialize     = 0;

% configure point-match collection(s)
clear pm;
pmix = 1;
pm(pmix).server = 'http://10.40.3.162:8080/render-ws/v1';
pm(pmix).owner  = 'flyTEM';
pm(pmix).match_collection = 'FAFB_pm_2';
pmix = pmix + 1;
sl.source_point_match_collection = pm;

% other configurations
sl.z_value = 1;
sl.filter_point_matches = 1;
sl.temp_dir = '/scratch/khairyk';
sl.verbose = 0;

           

% diagnostics options
dopts.nbrs = 0;
dopts.min_points = 3;
dopts.show_deformation = 0;
dopts.show_residuals = 0;
dopts.show_deformation_summary = 0;
dopts.nstd = 2;

% run diagnostics
[mA, mS, sctn_map, confidence, tile_areas, tile_perimeters, ...
    tidsvec, section_conf, residual_outliers, area_outliers, outliers, T ] =...
    gen_diagnostics(sl.source_collection,...
    sl.target_collection,...
    1, ...
    10, ...
    sl.source_point_match_collection,...
    dopts);

```



