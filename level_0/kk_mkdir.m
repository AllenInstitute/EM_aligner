function kk_mkdir(dir_new)
% makes the directory if doesn't exist. Deletes contents if exists
if exist(dir_new, 'dir')
    disp(['Purging directory contents: ' dir_new]);
    rmdir(dir_new, 's');
    mkdir(dir_new);
else
    mkdir(dir_new);
end