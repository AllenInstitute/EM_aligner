function resp_str = write_script(fn_script, str)
% generates a text file fn with content str and executable on a unix system

fid = fopen(fn_script, 'w');
fprintf(fid, '%s', str);
fclose(fid);

% make it executable
cmd_str = sprintf('chmod +x %s', fn_script);
[a, resp_str] = system(cmd_str);


