function [newdir] = set_AIBS_logging_path(inpath,description)
    %check thepath is valid
    if isdir(inpath)==0
        disp('not a valid path in set_AIBS_path(inpath):');
        disp(inpath);
        return;
    end
    
    %make a new directory
    basedir=datestr(now,'yyyymmdd');
    newbasedir=basedir;
    newdir=sprintf('%s/%s/',inpath,basedir);
    i=0;
    while isdir(newdir)==1
        newbasedir=sprintf('%s.%d',basedir,i);
        newdir=sprintf('%s/%s',inpath,newbasedir);
        i=i+1;
    end
    status=mkdir(newdir);
    disp('exchange directory created: ');
    disp(newdir);
    
    %add a line to the overall log
    logfile=sprintf('%s/logdirectory.txt',inpath);
    f = fopen(logfile,'a');
    fprintf(f,'%s  %s  %s\n',newbasedir,description,datestr(now));
    fclose(f);
    