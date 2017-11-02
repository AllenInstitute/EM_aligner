function [x2, R, time_solve, flag] = solve_AxB(K,Lm,options,d)
% SOLVE
% Performs the actual solve of the final linear system.
% Input: K is a sparse square matrix assembled elsewhere nxn.
%        Lm is a sparse vector nx1
%        options is a struct with fields:
%        options.solver: determines the solver strategy. Allowed values
%
%           "backslash" : uses Matlab's backslash operator
%            solving the system K * x2 = Lm directly. This is
%            memory-limited
%
%           "lsqlin", "gmres", "tfqmr", "bicg", "bicgstab", "lsqr", "pcg",
%           "symmlq", "cgs", "minres": All of these are iterative methods
%           that benefit from a good starting value "d" and require
%           preconditioning. They have tradeoffs regarding accuracy,
%           efficiency, suitability for a particular system and memory requirements.
%
%          options.L2 and options.U2, if not empty will re-use
%          preconditioners.
%
%           options.ilu_udiag, options. ilu_droptol, options.ilu_type
%           control the calculation of incomplete LU decomposition. Refer
%           to Matlab's documentation.
%
%           options.restart, options.tol, options.maxit, control execution of the
%           individual methods.
%
% Output: x2: solution vector
%          R: a 2-vector of residuals
%
% Author: Khaled Khairy: Copyright 2016. Janelia Research Campus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
time_solve = 0;
if strcmp(options.solver, 'pastix')

    kk_clock;[x2, R, time_solve] = solve_pastix(K,Lm,options);kk_clock;  % needs external PaStiX installed
    
else
    tic_Axb = tic;
    
    if ~isfield(options, 'distributed'), options.distributed = 0;end
    disp(['Using distributed: ' num2str(options.distributed)]);
    x2 = [];
    R  = [];
    
    if options.verbose    % then we also want to know how long it takes to solve the system
        tic;
    end
    
    %%%%%%%%%%%%%%%%% preconditioning
    if ~strcmp(options.solver,'backslash') ...
            && ~strcmp(options.solver,'backslash--noreg') ...
            && ~strcmp(options.solver,'lsqlin')
        if options.use_ilu 
            if options.verbose,disp('Calculating preconditioner');end
            [L2,U2] = ilu(K,struct('type',options.ilu_type,'droptol',options.ilu_droptol, 'udiag', options.ilu_udiag));
        else
            if isfield(options, 'L2')
            L2 = options.L2;
            U2 = options.U2;
            else
                L2 = [];
                U2 = [];
            end
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    flag = -999;
    if strcmp(options.solver, 'lsqlin')
        if options.verbose,disp('------------ Performing lsqlin ');end
        x2 = lsqlin(A, b, B, d);
        
        
    elseif strcmp(options.solver, 'backslash')
        if options.verbose,disp('------------ Performing backslash x2 = K\Lm solution ');end
        if options.distributed
            disp('Using distributed Ax=b');
            x2 = gather(distributed(K)\distributed(Lm));
        else
            x2 = K\Lm;
        end
        
    elseif strcmp(options.solver, 'gmres')
        if options.verbose,disp('------------ Performing gmres');end
        %x1 = K\Lm; % sosi
        %[x2,flag,relres,iter,resvec] = gmres(K,Lm,options.restart,options.tol, options.maxit, L2, U2, x1);
        [x2,flag,relres,iter,resvec] = gmres(K,Lm,options.restart,options.tol, options.maxit,L2, U2, d);
        disp('gmres flag:');
        disp(flag);
        % flag = 0
        % gmres converged to the desired tolerance tol within maxit outer iterations.
        % flag = 1
        % gmres iterated maxit times but did not converge.
        % flag = 2
        % Preconditioner M was ill-conditioned.
        % flag = 3
        % gmres stagnated. (Two consecutive iterates were the same.)
    elseif strcmp(options.solver, 'tfqmr')
        if options.verbose,disp('------------ Performing tfqmr');end
        [x2,flag,relres,iter,resvec] = tfqmr(K,Lm,options.tol, options.maxit,L2,U2,d);
        
    elseif strcmp(options.solver, 'bicg')
        if options.verbose,disp('------------ Performing biconjugate gradients');end
        [x2,flag,relres,iter,resvec] = bicg(K,Lm,options.tol, options.maxit, L2, U2, d);
        
    elseif strcmp(options.solver, 'bicgstab')
        if options.verbose,disp('------------ Performing biconjugate gradients stabelized');end
        [x2,flag,relres,iter,resvec] = bicgstab(K,Lm,options.tol, options.maxit, L2, U2, d);
        
    elseif strcmp(options.solver, 'lsqr')
        if options.verbose,disp('------------ Performing lsqr');end
        [x2,flag,relres,iter,resvec] = lsqr(A,b,options.tol,options.maxit, L2, U2, d);
        
    elseif strcmp(options.solver, 'symmlq')
        if options.verbose,disp('------------ Performing symmlq');end
        [x2,flag,relres,iter,resvec] = symmlq(K,Lm,options.tol, options.maxit, L2, U2, d);
        
    elseif strcmp(options.solver, 'cgs')
        if options.verbose,disp('------------ Performing cgs');end
        [x2,flag,relres,iter,resvec] = cgs(K,Lm,options.tol, options.maxit, L2, U2, d);
        
    elseif strcmp(options.solver, 'pcg')
        if options.verbose,disp('------------ Performing pcg with incomplete cholesky preconditioning');end
        [x2,flag,relres,iter,resvec] = pcg(K,Lm,options.tol, options.maxit, L2, U2, d);
        
    elseif strcmp(options.solver, 'minres')
        if options.verbose,disp('------------ Performing minres');end
        [x2,flag,relres,iter,resvec] = minres(K,Lm,options.tol, options.maxit, L2, U2, d);
    end
    if options.verbose
        disp('-----------    Time ----------');
        toc
        disp('------------------------------');
    end
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% sosi
    % x1 = K\Lm;
    % disp(num2str([d(100:130) x1(100:130) x2(100:130)]));
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if options.verbose,
        disp('Flag (default is -999 for backslash)');disp(flag);
        disp('Done!');
    end
    if ~strcmp(options.solver,'backslash') ...
            && ~strcmp(options.solver,'backslash--noreg')
        c1 = [0:numel(resvec)-1];
        c2 = resvec/norm(Lm);
        R  = [c1(:) c2(:)];
    else
        R = K*x2-Lm;
    end
    
    if options.debug && ~strcmp(options.solver,'backslash')...
            && ~strcmp(options.solver,'backslash--noreg')
        
        semilogy(R(:,1),R(:,2),'-o');
        xlabel('Iteration Number');
        ylabel('Relative Residual');
        warning on;
        drawnow;
        pause(3);
    end
    
    x2 = real(x2);
    time_solve = toc(tic_Axb);
end

