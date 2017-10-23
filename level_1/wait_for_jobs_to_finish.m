function wait_for_jobs_to_finish(user, jbname, t)
% in the future this should become more of a job monitoring function
jcount = numel(jbname);
nactive = 0;

str = sprintf('qstat -u %s', user);
[a s] = eval('system(str)');
for ix = 1:jcount
    k = findstr(s,jbname{ix});
    if ~isempty(k), nactive = nactive + 1;end
end

while nactive
    disp(['Waiting for ' num2str(nactive) ' of ' num2str(jcount) ' jobs to finish']);
    str = sprintf('qstat -u %s', user);
    [a s] = eval('system(str)');
    nactive = 0;
    for ix = 1:jcount
        k = findstr(s,jbname{ix});
        if ~isempty(k), nactive = nactive + 1;end
    end
    er = findstr(s,'Eqw');
    if ~isempty(er), warning(['one or more jobs not executing --- error: Eqw']);end
    pause(t);
end
disp('----- Finished');