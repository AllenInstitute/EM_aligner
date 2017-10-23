function ingest_point_match_set(pm, tid1, tid2, sid1, sid2, p1, p2, dir_scratch)
% ingests one point_match set into pm point match collection

    MP{1}.pz = sid1;
    MP{1}.pId= tid1;
    MP{1}.p  = p1;
    MP{1}.qz = sid2;
    MP{1}.qId= tid2;
    MP{1}.q  = p2;
    js = pairs2json(MP); % generate json blob to be ingested into point-match database
    fn = [dir_scratch '/temp_' num2str(randi(100000000)) '.json'];
    fid = fopen(fn, 'w');
    fwrite(fid,js);
    fclose(fid);
    urlChar = sprintf('%s/owner/%s/matchCollection/%s/matches/', ...
        pm.server, pm.owner, pm.match_collection);
    cmd = sprintf('curl -X PUT --connect-timeout 30 --header "Content-Type: application/json" --header "Accept: application/json" -d "@%s" "%s"',...
        fn, urlChar);
    [a, resp]= evalc('system(cmd)');