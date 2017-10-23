function jj = get_pms_montage(pm, sID, wopts)
%% based on one or more point-match structs get all montage point-matches for a particular section id

urlChar = sprintf('%s/owner/%s/matchCollection/%s/group/%s/matchesWithinGroup', ...
    pm(1).server, pm(1).owner, pm(1).match_collection, sID);
U = matlab.net.URI(urlChar);

if numel(pm)>1
    data_options_str = '?';
    for ix = 2:numel(pm)
        if ix ==2
            data_options_str = [data_options_str 'mergeCollection=' pm(ix).match_collection];
        else
            data_options_str = [data_options_str '&mergeCollection=' pm(ix).match_collection];
        end
    end
    QPs = matlab.net.QueryParameter(data_options_str);
    U.Query = QPs;
end

try
    jj = webread(char(U), wopts);
catch err_fetch_pm
    kk_disp_err(err_fetch_pm)
    pause(1);
    disp('trying again');
    jj = webread(char(U),options); % try again
end

