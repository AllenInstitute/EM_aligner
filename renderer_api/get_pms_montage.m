function jj = get_pms_montage(pm, sID, wopts)
%% based on one or more point-match structs get all montage point-matches for a particular section id


%%%%%%% uncomment if using 2017a (uses Renderer machinery to concatenate more than one poin-match
%%%%%%% collection
% urlChar = sprintf('%s/owner/%s/matchCollection/%s/group/%s/matchesWithinGroup', ...
%     pm(1).server, pm(1).owner, pm(1).match_collection, sID);
%
% U = matlab.net.URI(urlChar);
%
% if numel(pm)>1
%     data_options_str = '?';
%     for ix = 2:numel(pm)
%         if ix ==2
%             data_options_str = [data_options_str 'mergeCollection=' pm(ix).match_collection];
%         else
%             data_options_str = [data_options_str '&mergeCollection=' pm(ix).match_collection];
%         end
%     end
%     QPs = matlab.net.QueryParameter(data_options_str);
%     U.Query = QPs;
% end
%
% try
%     jj = webread(char(U), wopts);
% catch err_fetch_pm
%     kk_disp_err(err_fetch_pm)
%     pause(1);
%     disp('trying again');
%     jj = webread(char(U), wopts); % try again
% end

%%%%%%% uncomment if using 2016a --- or want to concatenate point-match collection directly
try
    jj = [];
    for pix = 1:numel(pm)
        urlChar = sprintf('%s/owner/%s/matchCollection/%s/group/%s/matchesWithinGroup', ...
            pm(pix).server, pm(pix).owner, pm(pix).match_collection, sID);
        
        %original, json structuring fails for large files and returns zero
        %jresp = webread(urlChar, wopts);
        %jj = [jj; jresp];
        
        %new, offload json decoding to separate function
        wopts.ContentType = 'raw';
        jresp = jsondecode(webread(urlChar, wopts));
        jj = [jj; jresp];
        wopts.ContentType = 'auto';

        %this was for manual loading.
        %fname='/home/danielk/tmp/1421.json';
        %jresp = loadjson(char(fname));
        %jj = cat(1, jresp{:});
        
    end
catch err_fetch_pm
    kk_disp_err(err_fetch_pm)
    pause(1);
    jj = [];
    for pix = 1:numel(pm)
        urlChar = sprintf('%s/owner/%s/matchCollection/%s/group/%s/matchesWithinGroup', ...
            pm(pix).server, pm(pix).owner, pm(pix).match_collection, sID);
        try
            %original
            %jresp = webread(urlChar, wopts);
            %jj = [jj; jresp];
            
            %new, offload json decoding to separate function
            wopts.ContentType = 'raw';
            jresp = jsondecode(webread(urlChar, wopts));
            jj = [jj; jresp];
            wopts.ContentType = 'auto';
            
        catch err_fetch_pm_try_02
            disp(['Not able to get montage point-matches:']);
            disp(urlChar);
            disp('------- giving up');
        end
    end
end

if numel(pm)>1
    jj = concatenate_point_match_sets(jj);
end
