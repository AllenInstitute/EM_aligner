function r = wait_for_file(fn, wt, verbose)
% this function is very slow: ---- probably a system call could speed this up.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin<3, verbose = 1;end
r = 0;
counter = 0;
while ~exist(fn,'file') && counter<wt
    pause(5);
    counter = counter+1;
    if verbose, disp(counter);end
end
if exist(fn,'file'), r = 1;end