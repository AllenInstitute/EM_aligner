function jj = get_pms_cross_layer(pm, sID1, sID2, wopts, outside_group)
%% get point-matches between two groups (layers) sID1 and sID2
%%%%%%%%
if nargin<5
    outside_group = false;
end

%%%% uncomment if using Matlab 2017a
%
% urlChar = sprintf('%s/owner/%s/matchCollection/%s/group/%s/matchesWith/%s', ...
%    pm(1).server, pm(1).owner, pm(1).match_collection, sID1, sID2);
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
%     if strfind(err_fetch_pm.message,'Maximum variable size allowed by the function is exceeded')
%         disp('trying again with websave');
%         filename = ['large_pm_file_' num2str(randi(3000000)) '_' strrep(num2str(sum(clock)),'.','') '.json'];
%         websave(filename,char(U), wopts);
%         jj_cell_array = loadjson(filename);
%         jj(numel(jj_cell_array),1)=struct('pGroupId',[],'pId',[],'qGroupId',[],'qId',[],'matches',[]);
%         for i=1:numel(jj_cell_array)
%             jj(i) = jj_cell_array{i};
%         end
%     else
%         disp('trying again');
%         jj = webread(char(U),wopts); % try again
%     end
% end


%%%% uncomment if using 2016a
% % %disp([sID{isix} ' ---- ' sID{jsix}]);
% % %%jj = webread(urlChar, wopts);
try
    jj = [];
    for pix = 1:numel(pm)
        if outside_group
            urlChar = sprintf('%s/owner/%s/matchCollection/%s/group/%s/matchesOutsideGroup', ...
                pm(pix).server, pm(pix).owner, pm(pix).match_collection, sID1);
        else
             urlChar = sprintf('%s/owner/%s/matchCollection/%s/group/%s/matchesWith/%s', ...
                pm(pix).server, pm(pix).owner, pm(pix).match_collection, sID1, sID2);
        end
        jj =[jj; webread(urlChar, wopts)];
    end
catch err_fetch_pm
    kk_disp_err(err_fetch_pm)
    pause(1);
    jj = [];
    for pix = 1:numel(pm)
        if outside_group
            urlChar = sprintf('%s/owner/%s/matchCollection/%s/group/%s/matchesOutsideGroup', ...
                pm(pix).server, pm(pix).owner, pm(pix).match_collection, sID1);
        else
            urlChar = sprintf('%s/owner/%s/matchCollection/%s/group/%s/matchesWith/%s', ...
                pm(pix).server, pm(pix).owner, pm(pix).match_collection, sID1, sID2);
        end
        jj =[jj; webread(urlChar, wopts)];
    end
end
if outside_group
    if ~isempty(jj)
        pGroupIds = cellfun(@str2num,{jj.pGroupId});
        qGroupIds = cellfun(@str2num,{jj.qGroupId});
        to_remove = (pGroupIds == str2num(sID1) & (qGroupIds<str2num(sID1) | qGroupIds>str2num(sID2))) |...
            (qGroupIds == str2num(sID1) & (pGroupIds<str2num(sID1) | pGroupIds>str2num(sID2))); %make sure only taking correct pairs
        jj(to_remove) = []; %Delete those outside range
    end
end
if numel(pm)>1
    jj = concatenate_point_match_sets(jj);
end
%%%%%%%%%%%%%%%

