function manage_jobs(user, jbnames, jbstr, jbdir, t, maxcs)
% submit and babysit jobs --- does not use job arrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
jcount = numel(jbstr);
if isempty(maxcs) || numel(jbstr) < maxcs+1
    %%% submit the jobs
    
    for jbix = 1:jcount
        if iscell(jbdir)
            if ~isempty(jbdir{jbix})
                str = jbstr{jbix};
                
                if numel(jbdir)==1,
                    if iscell(jbdir)
                        cd(jbdir{1});
                    else
                        cd(jbdir);
                    end
                else
                    cd(jbdir{jbix});
                end
                %disp(['Test only -- not submitting anything: ' str]);
                [a, ret_str] = evalc('system(str)');
                c = strsplit(a);
                jbid{jbix} = c{3};
            end
        else
            str = jbstr{jbix};
            cd(jbdir);
            %disp(['Test only -- not submitting anything: ' str]);
            [a, ret_str] = evalc('system(str)'); %
            %disp(a);
            c = strsplit(a);
            
            
            %%%% determine the job id from qsub system message
            counter = 1;
            found = 0;
            while (found==0)
                if strcmp(c{counter}, 'job'), found = 1;end
                counter = counter + 1;
            end
            jbid{jbix} = c{counter};
            
        end
    end
    jbwait(user, jbid, t);         % wait for jobs to finish
    
else % we need to divide the jobs into chuncks
    %%%% define chunks
    vec = 1:jcount;
    cs = ceil(numel(vec)/maxcs);
    projected_size = maxcs*cs;
    vec =  padarray(vec(:),projected_size-numel(vec), -1, 'post');
    vec = reshape(vec,maxcs,cs);
    
    jbchuncks = cell(size(vec,2),1);
    jbnamechuncks = cell(size(vec,2),1);
    jbdirchuncks = cell(size(vec,2),1);
    for cix = 1:size(vec,2)        % loop over the chuncks
        %disp(['chunck: ' num2str(cix) ' of ' num2str(size(vec,2))]);
        jbn = cell(size(vec,1),1);
        jbs = cell(size(vec,1),1);
        jbd = cell(size(vec,1),1);
        for lix = 1:size(vec,1)        %% loop over entries into chunck cix
            if ~(vec(lix,cix)==-1)
                jbn{lix} = jbnames{vec(lix, cix)};
                jbs{lix} = jbstr{vec(lix, cix)};
                if ischar(jbdir)
                    jbd{lix} = jbdir;
                else
                    jbd{lix} = jbdir{vec(lix,cix)};
                end
            end
        end
        jbchuncks{cix} = jbs;
        jbnamechuncks{cix} = jbn;
        jbdirchuncks{cix} = jbd;
    end
    
    %%% submit each chunck and wait for it to finish
    for ix = 1:numel(jbchuncks)
        disp(['Submitting chunck: ' num2str(ix) ' of ' num2str(numel(jbchuncks))]);
        kk_clock;
        manage_jobs(user, jbnamechuncks{ix}, jbchuncks{ix}, jbdirchuncks{ix}, t, []);
        jbwait(user, jbnames, t);         % wait for jobs to finish
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function jbwait(user, jbids, t)
jcount = numel(jbids);
%%% wait for jobs to finish
nactive = jcount;

while nactive
    if ~isempty(user)
        str = sprintf('qstat -u %s', user);
    else
        str = sprintf('qstat');
    end
    [a, s] = eval('system(str)');
    nactive = 0;
    for ix = 1:jcount
        k = strfind(s, jbids{ix});
        if ~isempty(k), nactive = nactive + 1;end
    end
    if nactive == 0
        break;
    end
    er = strfind(s, 'Eqw');
    if ~isempty(er)
        disp('one or more jobs not executing --- error: Eqw');
    end
    pause(t);
end
