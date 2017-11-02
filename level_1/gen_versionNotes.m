function str = gen_versionNotes(opts)
%
if ~isfield(opts, 'xfac'), opts.xfac = 'n_a';end
if ~isfield(opts, 'yfac'), opts.yfac = 'n_a';end
if ~isfield(opts, 'use_peg'), opts.use_peg = 'n_a';end
if ~isfield(opts, 'transfac'), opts.transfac = '1';end

str = ['l_' num2str(log10(opts.lambda)) '_deg_' num2str(opts.degree)...
       '_solver_' opts.solver '_peg_' num2str(opts.use_peg) ...
       '_transfac_' num2str(opts.transfac) '_xfac_' num2str(opts.xfac) ...
       '_yfac_' num2str(opts.yfac)];