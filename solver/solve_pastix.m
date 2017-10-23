function [x2, R, time_total] = solve_pastix(A, b,options)
%%% use pastix to solve this system
kk_clock;
tic;
if ~isfield(options, 'pastix')
    ncpus = 5;
    parms_fn = '/nrs/flyTEM/khairy/FAFB00v13/matlab_production_scripts/params_file.txt';
else
    ncpus = options.pastix.ncpus;
    parms_fn = options.pastix.parms_fn;
end


disp(['Using Pastix with: ' num2str(options.pastix.ncpus) ' cpus.']);
disp(['Matrix A (pastix) dimensions: ' num2str(size(A,1)) ' x ' num2str(size(A,2))]);
disp(['Number of tiles assuming affine: ' num2str(size(A,1)/6)]);
disp(['Matrix A (pastix) non-zeros : ' num2str(nnz(A))]);

%% configure
disp('Solving Ax=b system using pastix...');
if options.pastix.split
    disp('Using split pastix');
    dir_temp_mx = '/nrs/flyTEM/khairy/FAFB00v13/matlab_large_matrix_system';
    PASTIX_HOME = '/groups/flyTEM/flyTEM/from_tier2/denisovg/pastix_split';
    PASTIX_DATA = [dir_temp_mx];
    PASTIX_LOG  = '/nrs/flyTEM/khairy/FAFB00v13/matlab_large_matrix_system/out.txt';
    PASTIX_ERR  = '/nrs/flyTEM/khairy/FAFB00v13/matlab_large_matrix_system/err.txt';
    lin_system_fn = 'linear_system_Ab.mat';
    full_path_lin_system_fn = [PASTIX_DATA '/' lin_system_fn];
    str_pastix_solver = PASTIX_HOME;
    str_pastix_run = [PASTIX_HOME '/run_align_tiles_mod_KK2.sh'];
    pastix_script = [str_pastix_solver '/align_tiles_mod_KK2.sh'];
    
    str_env = sprintf('export PASTIX_HOME=%s;export PASTIX_DATA=%s;',str_pastix_solver, PASTIX_DATA);
    if ~exist(PASTIX_DATA, 'dir') 
        mkdir(PASTIX_DATA);
    end
    kk_mkdir(PASTIX_DATA); 
    %% save file
    %save(full_path_lin_system_fn, 'A', 'b');
    
    %save_empty_Ab(full_path_lin_system_fn, size(A,1), size(b,1));
    %split_mat_file(full_path_lin_system_fn, ncpus);
%     split_mat_file(full_path_lin_system_fn, ncpus);

prefixName = full_path_lin_system_fn(1:(length(full_path_lin_system_fn)-4));
num_col = size(A, 2);
    tiles_per_worker = round(num_col/6./ncpus);
    disp(['tiles_per_worker=' num2str(tiles_per_worker)]);
%     delete(gcp);
%     parpool(4);

% could be parfor, but keep as for-loop for memory reasons
    for i=1:ncpus
        disp(i);
        col_min = 1 + 6*(i-1)*tiles_per_worker;
        if i < ncpus
            col_max = col_min   + 6*tiles_per_worker-1;
        else
            col_max = size(A, 2);
        end
        Aout = A(:, col_min:col_max);
        bout = b(col_min:col_max);
        disp(['i=' num2str(i) ' col_min=' num2str(col_min) ' col_max=' num2str(col_max) ...
            ' size(A)=' num2str(size(A)) ' size(b)=' num2str(size(b))]);
        output_mat_file = strcat(prefixName,'_', num2str(i), '.mat');
        save_column_range(output_mat_file, Aout,bout);
    end
    
    
    
    lin_system_fn = full_path_lin_system_fn;
%     delete(lin_system_fn);
%     dir_curr = pwd;
%     cd ..
%     cd(dir_curr);
else
    dir_temp_mx = '/nrs/flyTEM/khairy/FAFB00v13/matlab_large_matrix_system';
    %PASTIX_HOME = '/nrs/flyTEM/khairy/FAFB00v13/pastix_solver';
    PASTIX_HOME = '/groups/flyTEM/flyTEM/from_tier2/flyTEM/denisovg/pastix';
    PASTIX_DATA = [dir_temp_mx];
    lin_system_fn = 'linear_system_Ab.mat';
    full_path_lin_system_fn = [PASTIX_DATA '/' lin_system_fn];
    str_pastix_solver = PASTIX_HOME;
    str_pastix_run = [PASTIX_HOME '/run_align_tiles.sh'];
    pastix_script = [str_pastix_solver '/align_tiles_mod_KK2.sh'];
    str_env = sprintf('export PASTIX_HOME=%s;export PASTIX_DATA=%s;',str_pastix_solver, PASTIX_DATA);
    %kk_mkdir(PASTIX_DATA);
    %% save A and b to disk
    %save(full_path_lin_system_fn, 'A', 'b');
end




%% system command to solve
% str = sprintf('%s %d %s %s', pastix_script, ncpus, lin_system_fn, str_pastix_run);
str = sprintf('%s %d %s %s %s %s', pastix_script, ncpus, lin_system_fn,...
                                PASTIX_HOME, PASTIX_DATA, parms_fn);

disp(str);
disp('--- pastix run:');
disp([ 'Pastix script:               ' pastix_script]);
disp( ['Number of cpus:              ' num2str(ncpus)]);
disp( ['Input matrix system file:    ' lin_system_fn]);
disp( ['Pastix run script:           ' str_pastix_run]);
disp(['Pastix work directory (data): ' PASTIX_DATA]);
disp(['Pastix home directory (home): ' PASTIX_HOME]);
disp(['Pastix paramters file: ' parms_fn]);
type(parms_fn);

[a, resp_str] = system(str);disp(resp_str);
[a, resp_str] = system('qstat');disp(resp_str);
%% wait for response
disp('... waiting for solution ...');
dt = 5;
pause(dt);
[a, resp_str] = system('qstat');disp(resp_str);
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
fn_log = [dir_temp_mx '/out.txt'];
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

%x2 = assemble_x(PASTIX_DATA);
% disp('Assembling solution vector...');
% fn = dir(PASTIX_DATA);
% fn_range1 = [];
% fn_range2 = [];%zeros(numel(fn)-2,1);
% count = 1;
% for fix = 2:numel(fn)
%     if strcmp(fn(fix).name(1), 'x')
%         c = strsplit(fn(fix).name(3:end), '-');
%         fn_range1(count) = str2double(c{1});
%         c = strsplit(c{end}, '.');
%         fn_range2(count) = str2double(c{1});
%         count = count + 1;
%     end
% end
% [~, ia] = sort(fn_range2);
% fn_range1 = fn_range1(ia);
% fn_range2 = fn_range2(ia);
% % now reassemble everything
% x2 = [];
% for fix = 1:numel(fn_range1)
%     fn = sprintf('%s/x_%s-%s.mat', PASTIX_DATA, num2str(fn_range1(fix)), ...
%         num2str(fn_range2(fix)));
%     disp(fn);
%     c = load(fn);
%     x2 = [x2;c.x(:)];
% end
% disp('Done.');



%% .bashrc
% # ~/.bashrc: executed by bash(1) for non-login shells.
% # see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
% # for examples
%
% # If not running interactively, don't do anything
% case $- in
%     *i*) ;;
%       *) return;;
% esac
%
% # don't put duplicate lines or lines starting with space in the history.
% # See bash(1) for more options
% HISTCONTROL=ignoreboth
%
% # append to the history file, don't overwrite it
% shopt -s histappend
%
% # for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
% HISTSIZE=1000
% HISTFILESIZE=2000
%
% # check the window size after each command and, if necessary,
% # update the values of LINES and COLUMNS.
% shopt -s checkwinsize
%
% # If set, the pattern "**" used in a pathname expansion context will
% # match all files and zero or more directories and subdirectories.
% #shopt -s globstar
%
% # make less more friendly for non-text input files, see lesspipe(1)
% [ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"
%
% # set variable identifying the chroot you work in (used in the prompt below)
% if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
%     debian_chroot=$(cat /etc/debian_chroot)
% fi
%
% # set a fancy prompt (non-color, unless we know we "want" color)
% case "$TERM" in
%     xterm-color) color_prompt=yes;;
% esac
%
% # uncomment for a colored prompt, if the terminal has the capability; turned
% # off by default to not distract the user: the focus in a terminal window
% # should be on the output of commands, not on the prompt
% #force_color_prompt=yes
%
% if [ -n "$force_color_prompt" ]; then
%     if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
% 	# We have color support; assume it's compliant with Ecma-48
% 	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
% 	# a case would tend to support setf rather than setaf.)
% 	color_prompt=yes
%     else
% 	color_prompt=
%     fi
% fi
%
% if [ "$color_prompt" = yes ]; then
%     PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
% else
%     PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
% fi
% unset color_prompt force_color_prompt
%
% # If this is an xterm set the title to user@host:dir
% case "$TERM" in
% xterm*|rxvt*)
%     PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
%     ;;
% *)
%     ;;
% esac
%
% # enable color support of ls and also add handy aliases
% if [ -x /usr/bin/dircolors ]; then
%     test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
%     alias ls='ls --color=auto'
%     #alias dir='dir --color=auto'
%     #alias vdir='vdir --color=auto'
%
%     alias grep='grep --color=auto'
%     alias fgrep='fgrep --color=auto'
%     alias egrep='egrep --color=auto'
% fi
%
% # some more ls aliases
% alias ll='ls -alF'
% alias la='ls -A'
% alias l='ls -CF'
%
% # Add an "alert" alias for long running commands.  Use like so:
% #   sleep 10; alert
% alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
%
% # Alias definitions.
% # You may want to put all your additions into a separate file like
% # ~/.bash_aliases, instead of adding them here directly.
% # See /usr/share/doc/bash-doc/examples in the bash-doc package.
%
% if [ -f ~/.bash_aliases ]; then
%     . ~/.bash_aliases
% fi
%
% # enable programmable completion features (you don't need to enable
% # this, if it's already enabled in /etc/bash.bashrc and /etc/profile
% # sources /etc/bash.bashrc).
% if ! shopt -oq posix; then
%   if [ -f /usr/share/bash-completion/bash_completion ]; then
%     . /usr/share/bash-completion/bash_completion
%   elif [ -f /etc/bash_completion ]; then
%     . /etc/bash_completion
%   fi
% fi
% # User specific aliases and functions
%
% # Source global definitions
% if [ -f /etc/bashrc ]; then
% 	. /etc/bashrc
% fi
%
% # JAVA settings
% export PATH=$PATH:$HOME/jdk1.7.0_60/bin
%
%
% # Use Intel compiler for MPI
% if [ -f /usr/local/INTEL2016.sh ]; then
%      . /usr/local/INTEL2016.sh
% fi
% export I_MPI_FABRICS=shm:ofa
% export I_MPI_FALLBACK=disable
%
%
% #export I_MPI_DEBUG=0
% #export I_MPI_RENDEZVOUS_RDMA_WRITE=1
% #export I_MPI_DEVICE=rdssm:OpenIB-iwarp
% #export I_MPI_FALLBACK_DEVICE=0
% #export I_MPI_USE_DYNAMIC_CONNECTIONS=0
%
% # export I_MPI_OFA_USE_XRC=1
% # export I_MPI_OFA_DYNAMIC_QPS=1
%
% # Matlab configuration
% export matlabroot="/usr/local/matlab-2016a"
% export PATH="$PATH:$matlabroot/bin"
% export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:\
% $matlabroot/bin/glnxa64:\
% $matlabroot/runtime/glnxa64:\
% $matlabroot/sys/os/glnxa64:\
% $matlabroot/sys/java/jre/glnxa64/jre/lib/amd64/native_threads:\
% $matlabroot/sys/java/jre/glnxa64/jre/lib/amd64/server:\
% $matlabroot/sys/java/jre/glnxa64/jre/lib/amd64"
% export XAPPLRESDIR="$matlabroot/X11/app-defaults"
% export MCR_INHIBIT_CTF_LOCK=1
%
% #### PaStiX stuff
% export LD_LIBRARY_PATH=$HOME/lib64:/usr/local/hwloc-1.11.3/lib:$LD_LIBRARY_PATH
% export LD_LIBRARY_PATH=$HOME/lib64:/lib64:/usr/local/hwloc-1.11.3/lib:$LD_LIBRARY_PATH
%
% export PASTIX_HOME="/tier2/flyTEM/denisovg/pastix"
% #export PASTIX_HOME="/nobackup/flyTEM/khairy/FAFB00v13/pastix_solver"
% export PASTIX_DATA="/nobackup/flyTEM/khairy/FAFB00v13/matlab_large_matrix_system"
% export PE=impi
% #
% # End bashrc
%
% ### add path to latest cmake
% #export PATH="$HOME/downloads/cmake-3.0.2/bin/bin:$PATH"
% ### add path to latest version of curl
% export PATH="$HOME/downloads/curl-7.38.0/bin/bin:$PATH"
% ### add path for BUILDEM
% #export BUILDEM_DIR=$HOME/downloads/bpd
% #export PATH=/usr/local/gcc/bin:/usr/local/cmake-2.8.8/bin:/usr/local/git-1.8.1/bin:$BUILDEM_DIR/bin:$PATH
% #export LD_LIBRARY_PATH=$BUILDEM_DIR/lib:/usr/local/gcc/lib64:$LD_LIBRARY_PATH
% #export PYTHONPATH=$BUILDEM_DIR/lib/python2.7:$BUILDEM_DIR/lib/python2.7/site-packages:$BUILDEM_DIR/lib
% #export LD_LIBRARY_PATH=/usr/local/gcc/lib64
% #echo "Activated environment for building in '$BUILDEM_DIR'"
%
% #### PaStiX stuff
% #export LD_LIBRARY_PATH=/usr/local/hwloc-1.11.3/lib:$LD_LIBRARY_PATH
% #export LD_LIBRARY_PATH=$HOME/lib64:/usr/local/hwloc-1.11.3/lib:$LD_LIBRARY_PATH














