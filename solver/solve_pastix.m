function [x2, R, time_total] = solve_pastix(A, b,opts)
%%% use pastix to solve this system
%%% example opts
% opts.pastix.ncpus = 8;
% opts.pastix.home          =  '/groups/flyTEM/flyTEM/from_tier2/denisovg/pastix_split';
% opts.pastix.pastix_script = ['/groups/flyTEM/flyTEM/from_tier2/denisovg/pastix_split/align_tiles_mod_KK3.sh'];
% opts.pastix.run_script    = ['/groups/flyTEM/flyTEM/from_tier2/denisovg/pastix_split/run_align_tiles_mod_KK3.sh'];
% opts.pastix.data =          ['/nrs/flyTEM/khairy/FAFB00v14/matlab_production_scripts/temp_pastix_' num2str(randi(2000))];
% opts.pastix.parms_fn = '/nrs/flyTEM/khairy/FAFB00v13/matlab_production_scripts/params_file.txt';
% opts.pastix.split = 1; % set to 1 always -- this is not the matrix split during matrix building

kk_clock;tic;
if ~isfield(opts, 'pastix')
    ncpus = 5;
    parms_fn = '/nrs/flyTEM/khairy/FAFB00v13/matlab_production_scripts/params_file.txt';
else
    ncpus = opts.pastix.ncpus;
    parms_fn = opts.pastix.parms_fn;
end

disp(['Using Pastix with: ' num2str(opts.pastix.ncpus) ' cpus.']);
disp(['Matrix A (pastix) dimensions: ' num2str(size(A,1)) ' x ' num2str(size(A,2))]);
disp(['Number of tiles assuming affine: ' num2str(size(A,1)/6)]);
disp(['Matrix A (pastix) non-zeros : ' num2str(nnz(A))]);

%% configure
disp('Solving Ax=b system using pastix...');
if opts.pastix.split
    disp('Using split pastix (currently only option)');
    
    %%%%%%%%%%%%%%%%%%  configure parameters for call to pastix execution script
    if isfield(opts.pastix, 'home')
        PASTIX_HOME = opts.pastix.home;
    else
        PASTIX_HOME = '/groups/flyTEM/flyTEM/from_tier2/denisovg/pastix_split';
    end
    if isfield(opts.pastix, 'data')
        PASTIX_DATA = opts.pastix.data;
        PASTIX_LOG = [opts.pastix.data '/out.txt'];
        PASTIX_ERR = [opts.pastix.data '/err.txt'];
        
    else
        PASTIX_DATA = '/nrs/flyTEM/khairy/FAFB00v13/matlab_large_matrix_system';
        PASTIX_LOG  = '/nrs/flyTEM/khairy/FAFB00v13/matlab_large_matrix_system/out.txt';
        PASTIX_ERR  = '/nrs/flyTEM/khairy/FAFB00v13/matlab_large_matrix_system/err.txt';
    end
    
    if isfield(opts.pastix, 'pastix_script')
        str_pastix_run = opts.pastix.pastix_script;
    else
        str_pastix_run = [PASTIX_HOME '/run_align_tiles_mod_KK3.sh'];
    end
    if ~isfield(opts.pastix, 'run_script')
        opts.pastix.run_script = '/groups/flyTEM/flyTEM/from_tier2/denisovg/pastix_split/run_align_tiles_mod_KK3.sh';
    end
    
    lin_system_fn = 'linear_system_Ab.mat';
    full_path_lin_system_fn = [PASTIX_DATA '/' lin_system_fn];
    
    %%%%%%%%%%%%%%%%%%%%%%%
    disp('Initializing temporary pastix work directory:');
    disp(PASTIX_DATA);    
    if ~exist(PASTIX_DATA, 'dir')
        mkdir(PASTIX_DATA);
    end
    kk_mkdir(PASTIX_DATA);
    %% split matrix files and save
    
    prefixName = full_path_lin_system_fn(1:(length(full_path_lin_system_fn)-4));
    num_col = size(A, 2);
    degree = opts.degree;
    tdim = (degree + 1) * (degree + 2)/2; % number of coefficients for a particular polynomial
    tdim = tdim * 2;        % because we have two dimensions, u and v.
    tiles_per_worker = round(num_col/tdim/ncpus);
    disp(['Parameters per tile: ' num2str(tdim)]);
    disp(['tiles_per_worker=' num2str(tiles_per_worker)]);
    
    % sosi could be parfor, but keep as for-loop for memory reasons
    for i=1:ncpus
%         disp(i);
        col_min = 1 + tdim*(i-1)*tiles_per_worker;
        if i < ncpus
            col_max = col_min   + tdim*tiles_per_worker-1;
        else
            col_max = size(A, 2);
        end
        Aout = A(:, col_min:col_max);
        bout = b(col_min:col_max);
%         disp(['i=' num2str(i) ' col_min=' num2str(col_min) ' col_max=' num2str(col_max) ...
%             ' size(A)=' num2str(size(A)) ' size(b)=' num2str(size(b))]);
        output_mat_file = strcat(prefixName,'_', num2str(i), '.mat');
        save_column_range(output_mat_file, Aout,bout);
    end
    clear Aout bout;
else
    error('non-split pastix has been deprecated');
end

%% construct and submit system command to solve
% Note: opts.pastix.pastix_script contains the qsub command
%       opts.pastix.run_script contains the actual script that 
%       envokes the pastix executable
disp('--------');
str = sprintf('%s %d %s %s %s %s %s %s %s', opts.pastix.pastix_script, ...
    ncpus, full_path_lin_system_fn,...
    PASTIX_HOME, PASTIX_DATA, parms_fn, ...
    PASTIX_LOG, PASTIX_ERR, opts.pastix.run_script);
disp('System command to start pastix solver:');
disp(str);
disp('--------');
disp('--- pastix run:');
disp([ 'Pastix script:               ' opts.pastix.pastix_script]);
disp( ['Number of cpus:              ' num2str(ncpus)]);
disp( ['Input matrix system file:    ' full_path_lin_system_fn]);
disp( ['Pastix run script:           ' str_pastix_run]);
disp([ 'Pastix work directory (data):' PASTIX_DATA]);
disp([ 'Pastix home directory (home):' PASTIX_HOME]);
disp([ 'Pastix paramters file:       ' parms_fn]);
type(parms_fn);
%%% setting system environment variables:
% curr_path = getenv('PATH');
% curr_ld_library_path = getenv('LD_LIBRARY_PATH');

% setenv('I_MPI_FABRICS', 'shm:ofa');
% setenv('I_MPI_FALLBACK', 'disable');
% setenv('PASTIX_HOME', PASTIX_HOME);
% setenv('PASTIX_DATA', PASTIX_DATA);
% setenv('PATH', ['/usr/local/matlab-2016a/bin;' getenv('PATH')]);
% lp_str = '/usr/local/matlab-2016a/bin/glnxa64:/usr/local/matlab-2016a/runtime/glnxa64:/usr/local/matlab-2016a/sys/os/glnxa64:/usr/local/matlab-2016a/sys/java/jre/glnxa64/jre/lib/amd64/native_threads:/usr/local/matlab-2016a/sys/java/jre/glnxa64/jre/lib/amd64/server:/usr/local/matlab-2016a/sys/java/jre/glnxa64/jre/lib/amd64:$LD_LIBRARY_PATH';
% setenv('LD_LIBRARY_PATH', [lp_str ';' getenv('LD_LIBRARY_PATH')]);
disp('Submitting system command ...');
[a, resp_str] = system(str);disp(resp_str);
[a, resp_str] = system('bjobs');disp(resp_str);
% setenv('LD_LIBRARY_PATH', curr_ld_library_path);
% setenv('PATH', curr_path);
%% wait for response
disp('... waiting for solution ...');
dt = 5;
pause(dt);
[a, resp_str] = system('bjobs');disp(resp_str);
solving = 1;
while(solving)
    fn = dir(PASTIX_DATA);
    for fix = 2:numel(fn)
        if strcmp(fn(fix).name(1), 'x')
            solving = 0;
        end
    end
    pause(dt);
end
disp('Done.');
%%%% determine amount of time for solution
fn_log = [PASTIX_DATA '/out.txt'];
fid1 = fopen(fn_log,'r'); % open csv file for reading
count = 1;
time_total = 0;
while ~feof(fid1)
    line = fgets(fid1); % read line by line
    k = strfind(line, 'Time');
    if isempty(k)
        k = strfind(line, 'time');
    end
    if ~isempty(k)
        %disp([count k]);
        c = strsplit(line, ' ');
        %disp(c);
        if strcmp(c{end}(1), 's')
            time_total = time_total + str2double(c{end-1});
            %disp(str2double(c{end-1}));
        else
            time_total = time_total + str2double(c{end-2});
            %disp(str2double(c{end-2}));
        end
    end
    count = count + 1;
end
fclose(fid1);
%%%%
pause(1);
%% read and assemble result into x2


disp('Assembling solution vector...');
fn = dir(PASTIX_DATA);
fn_range1 = [];
count = 1;
for fix = 2:numel(fn)
    if strcmp(fn(fix).name(1), 'x')
        c = strsplit(fn(fix).name(3:end), '.');
        fn_count(count) = str2double(c{1});
        count = count + 1;
    end
end
[~, ia] = sort(fn_count);
fn_count = fn_count(ia);
disp(['Found: ' num2str(fn_count) ' fragment files. Expected: ' num2str(ncpus)]);
% now reassemble everything
x2 = [];
for fix = 1:numel(fn_count)
    fn = sprintf('%s/x_%s.mat', PASTIX_DATA, num2str(fn_count(fix)));
    disp(fn);
    try
        c = load(fn);
    catch err_load_fragment
        kk_disp_err(err_load_fragment);
        pause(2);
        disp('Retrying ------');
        c = load(fn);
    end
    x2 = [x2;c.x(:)];
end
disp('Done.');
%% calculate residual
R = A*x2-b;
toc
kk_clock

%%
function save_empty_Ab(full_path_lin_system_fn, szA, szb)
A = sparse(szA,szA);
b = sparse(szb);
save(full_path_lin_system_fn, 'A', 'b');

%%
function save_column_range(output_mat_file, A,b)
save(output_mat_file, 'A', 'b', '-v7.3');










