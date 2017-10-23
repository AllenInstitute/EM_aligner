function [obj,err,R, A, b, B, d, W, K, Lm, xout, LL2, U2, tB, td, invalid, time_Axb, time_gen_A] ...
    = solve_polynomial_explicit_region(obj, pdegree, opts)
% Returns the matrix solution for a contiguous region
%
%%%%%%%%%%%% SOSI: complete error checks and options 
if nargin<2, pdegree = 2;end
%%  lsq_options.verbose         = 1;

 lsq_options.solver          ='backslash';%'bicgstab';%'cgs';%%'tfqmr';%'gmres';%'pcg';%''symmlq';%minres';%'lsqlin';% ;%'lsqr';%'bicgstab' bicg tfqmr backslash
 lsq_options.constraint      ='explicit';%'none';% 'similarity';% 'trivial';%
 lsq_options.pdegree         = pdegree;
 lsq_options.constraint_only = 0;
 lsq_options.lidfix          = 0;
 lsq_options.tfix            = 0;
 lsq_options.constrain_edges = 1;

 lsq_options.translation_fac = 1e0;

if pdegree == 2
     lsq_options.lambda          = 1e2;
     lsq_options.edge_lambda     = 1e6;
else
     lsq_options.lambda      = 1e3;
     lsq_options.edge_lambda = 1e6;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 lsq_options.verbose         = 0;
 lsq_options.dw              = [1 1 1 1 1 1];

% needed if iterative methods are used
 lsq_options.ilu_droptol     = 3e-3;
 lsq_options.use_ilu         = 1;
 lsq_options.ilu_type        = 'ilutp';%'crout'; %'nofill';%%'ilutp';%;
 lsq_options.ilu_udiag       = 1;
 lsq_options.L2              = [];
 lsq_options.U2              = [];
 lsq_options.A               = [];
 lsq_options.b               = [];
 lsq_options.B               = [];
 lsq_options.d               = [];
 lsq_options.tB              = [];
 lsq_options.td              = [];
 lsq_options.W               = [];
 lsq_options.dw              = [];
 lsq_options.restart         = 5;
 lsq_options.tol             = 1e-16;
 lsq_options.maxit           = 30000;
% needed only in case of trivial constraint
deg                                 = 180;
 lsq_options.Rtfix           =  [cosd(deg) -sind(deg) 0; sind(deg) cosd(deg) 0; 0 0 1];
 lsq_options.debug           = 0;
 lsq_options.LARGE           = 1e2;
 lsq_options.nmax            = inf;
 lsq_options.use_Tfac        = 0;
 lsq_options.use_spmd        = 0;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% overrides
if nargin>2, 
     if isfield(opts, 'translation_fac'), lsq_options.translation_fac = ...
             opts.translation_fac;end
     if isfield(opts, 'solver'), lsq_options.solver = opts.solver;end
     if isfield(opts, 'lambda'), lsq_options.lambda = opts.lambda;end
     if isfield(opts, 'edge_lambda'), lsq_options.edge_lambda = opts.edge_lambda;end
     if isfield(opts, 'constrain_edges'), lsq_options.constrain_edges = ...
             opts.constrain_edges;end
     if isfield(opts, 'lidfix'), lsq_options.lidfix = opts.lidfix; end
     if isfield(opts, 'tfix'), lsq_options.tfix = opts.tfix; end
     if isfield(opts, 'distributed'), lsq_options.distributed = ...
             opts.distributed; end
end
[obj,err, R, A, b, B, d, W, K, Lm, xout, LL2, U2, tB, td, invalid, time_Axb, time_gen_A] = ...
    alignTEM_solver(obj, [],  lsq_options);
