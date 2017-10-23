function [] = generate_diagnostic_stats(zstart, zend, todo, diag_dir, opts_fn)
% This generates tile deformation and point match residual diagrams.
% Input:
%   zstart - first section 
%   zend - last section
%   todo - bitwise value that specifies what to do; valid values are:
%          1 - generate the area and perimeter median plots
%          2 - save diagnostic data table
%          4 - generate the residual diagrams
%          8 - generate the deformation diagrams
%   opts_fn - options
%
% Output: (none)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% prepare the parameters
    if nargin < 1, zstart = 1; end
    if nargin < 2, zend = 7062; end
    if nargin < 3, todo = 15; end
    if nargin < 4, diag_dir = '/nrs/flyTEM/khairy/FAFB00v13/map_diagrams'; end

    rs_source_opts = struct();
    pm_opts = struct();
    solver_opts = struct();

    if nargin >= 5
        stats_opts = loadjson(fileread(opts_fn));
        if isfield(stats_opts, 'stats_options')
            rs_source_opts = stats_opts.stats_options;
        end
        if isfield(stats_opts, 'pm_opts')
            pm_opts = stats_opts.pm_opts;       
        end
        if isfield(stats_opts, 'solver_opts')
            solver_opts = stats_opts.solver_opts;       
        end
    end

    if ischar(zstart)
        zstart = str2double(zstart);
    end
    if ischar(zend)
        zend = str2double(zend);
    end
    if ischar(todo)
        todo = str2double(todo);
    end

    save_diag = 1; % this is meaningful only when running in the Matlab IDE if we only want to view the diagrams otherwise we always want to save them
    show_figures = 'off';

    % configure source collection
    rc.stack = eval_field(rs_source_opts, 'stack', 'v12_acquire_merged_fix_1_00', true);
    rc.owner = eval_field(rs_source_opts, 'owner', 'flyTEM', true);
    rc.project = eval_field(rs_source_opts, 'project', 'test2', true);
    rc.service_host = eval_field(rs_source_opts, 'service_host', '10.40.3.162:8080', true);
    rc.baseURL = ['http://' rc.service_host '/render-ws/v1'];
    rc.verbose = eval_field(rs_source_opts, 'verbose', 1, false);

    % configure point-match collection
    pm.server = eval_field(pm_opts, 'server', 'http://10.40.3.162:8080/render-ws/v1', true);
    pm.owner = eval_field(pm_opts, 'owner', 'flyTEM', true);
    pm.match_collection = eval_field(pm_opts, 'match_collection', 'v12_dmesh', true);

    % configure solver
    opts.min_tiles = eval_field(solver_opts, 'min_tiles', 20); % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
    opts.degree = eval_field(solver_opts, 'degree', 1); % degree: 1 = affine, 2 = second order polynomial, maximum is 3
    opts.outlier_lambda = eval_field(solver_opts, 'outlier_lambda', 1e2); % outlier_lambda: large numbers result in fewer tiles excluded
    opts.lambda = eval_field(solver_opts, 'lambda', 10^(-2));
    opts.edge_lambda = eval_field(solver_opts, 'edge_lambda', 10^(-2));
    opts.solver = eval_field(solver_opts, 'solver', 'backslash', true);
    opts.min_points = eval_field(solver_opts, 'min_points', 5);
    opts.nbrs = eval_field(solver_opts, 'nbrs', 4);
    opts.xs_weight = eval_field(solver_opts, 'xs_weight', 1);
    opts.stvec_flag = eval_field(solver_opts, 'stvec_flag', 1); % 0 - do not assume rcsource providing the starting values.
    opts.distributed = eval_field(solver_opts, 'distributed', 1); % 1 - use distributed solver
    opts.conn_comp = eval_field(solver_opts, 'conn_comp', 0);
    opts.filter_pm = eval_field(solver_opts, 'filter_pm', 1);
    opts.use_peg = eval_field(solver_opts, 'use_peg', 0);
    opts.peg_weight = eval_field(solver_opts, 'peg_weight', 1e-3);
    opts.peg_npoints = eval_field(solver_opts, 'peg_npoints', 5);
    
    if bitand(todo, 15) == 0, return; end

    %% generate the diagnostic data
    tic
    [zu1, confidence, tidsvec, sctn_map, tile_areas, tile_perimeters, mA, mS, zresid, counts] = generate_diagnostic_data(rc, zstart, zend, pm, opts);
    toc

    %% plot the medians for the area ratio and the perimeter
    if bitand(todo, 1) == 1
        figure('Visible', show_figures);
        subplot(2,1,1);
        plot(zu1, mA, 'b.');title(sprintf('Area median per layer (%s)', rc.stack));
        subplot(2,1,2);
        plot(zu1, mS, 'g.');title(sprintf('Perimeter median per layer (%s)', rc.stack));
        if save_diag
            diag_file = [diag_dir, sprintf('/%d_%d_%s_area_and_perimeter.png', min(zu1), max(zu1), rc.stack)];
            disp(['Write ' diag_file]);
            print(diag_file, '-dpng');
            closereq
        end
    end

    %% save diagnostic data in a tabular format
    if bitand(todo, 2) == 2
        diagnostics_table = table(zu1', mA, mS, ...
            cellfun(@nanmean, zresid), cellfun(@nanstd, zresid), ...
            cellfun(@nanmean, tile_areas), cellfun(@nanstd, tile_areas), ...
            cellfun(@nanmean, tile_perimeters), cellfun(@nanstd, tile_perimeters), ...
            'VariableNames', {'Z', 'Median_area_ratio', 'Median_perimeter',...
            'Resid_mean', 'Resid_std', ...
            'Areas_mean', 'Areas_std', ...
            'Perimeters_mean', 'Perimeters_std'});
        diag_table_file = [diag_dir, sprintf('/%d_%d_diagnostics.txt', min(zu1), max(zu1))];
        writetable(diagnostics_table, diag_table_file, 'Delimiter', ',')
    end
    
    %% plot the residual diagrams
    colormap jet;

    if bitand(todo, 4) == 4
        %%% display tile residuals
        min_resid = min(cell2mat(transpose(cellfun(@transpose, zresid, 'UniformOutput', false))));
        max_resid = max(cell2mat(transpose(cellfun(@transpose, zresid, 'UniformOutput', false))));
        parfor zix = 1:numel(zu1)
            figure('Visible', show_figures);
            title(['Residuals ' num2str(zu1(zix))]);
            sm = sctn_map{zix};
            resid = zresid{zix};
            c = mat2gray(resid, [min_resid * 1.15 max_resid * .85]);

            for tix = 1:numel(sm)
                P = sm{tix}{1};   % patch for this tile
                patch( P(:,1), P(:,2), [c(tix)],'FaceColor', 'flat',   'EdgeColor', 'k' , 'Facealpha', 0.4);
            end
            daspect([1 1 1]);
            colorbar;
            axis ij;
            if save_diag
                diag_file = [diag_dir, sprintf('/%d_residuals.png', zu1(zix))];
                disp(['Write ' diag_file]);
                print(diag_file, '-dpng');
                closereq
            end
        end
    end
    
    %% plot the residual diagrams
    if bitand(todo, 8) == 8
        %%% display tile distortions
        min_area = min(cell2mat(transpose(cellfun(@transpose, tile_areas, 'UniformOutput', false))));
        max_area = max(cell2mat(transpose(cellfun(@transpose, tile_areas, 'UniformOutput', false))));
        parfor zix = 1:numel(zu1)
            figure('Visible', show_figures);
            title(['Deformation ' num2str(zu1(zix))]);
            sm = sctn_map{zix};
            areas = tile_areas{zix};
            c = mat2gray(areas, [min_area * 1.15 max_area *.85]);

            for tix = 1:numel(sm)
                P = sm{tix}{1};   % patch for this tile
                patch( P(:,1), P(:,2), [c(tix)],'FaceColor', 'flat',   'EdgeColor', 'k' , 'Facealpha', 0.4);
            end
            daspect([1 1 1]);
            colorbar;
            axis ij;
            if save_diag
                diag_file = [diag_dir, sprintf('/%d_deformations.png', zu1(zix))];
                disp(['Write ' diag_file]);
                print(diag_file, '-dpng');
                closereq
            end
        end
    end
    if show_figures == 'off', close all; end
end
