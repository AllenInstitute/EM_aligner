function js = PM_json(L2, fn)
% generate json string from point-match information in L2
if ~isempty(L2.pm)
    counter = 1;
    M = L2.pm.M;
    adj = L2.pm.adj;
    
%     if isempty(L2.sectionID), 
%         sectionID = num2str(L2.z,'%.1f');
%     else
%         sectionID = L2.sectionID;
%     end

    for mix = 1:size(M,1)
        indx1 = adj(mix,1);
        indx2 = adj(mix,2);
        tid1 = [L2.tiles(indx1).renderer_id];
        tid2 = [L2.tiles(indx2).renderer_id];
        
        MP{counter}.pz = L2.tiles(indx1).sectionId;
        MP{counter}.pId= tid1;
        MP{counter}.p  = M{mix,1};
        
        MP{counter}.qz = L2.tiles(indx2).sectionId;
        MP{counter}.qId= tid2;
        MP{counter}.q  = M{mix,2};
        
        MP{counter}.w  = L2.pm.W(mix);
        counter = counter + 1;
    end
    if nargin == 1, js = pairs2json(MP); end% generate json blob to be ingested into point-match database
if nargin>1, js = pairs2json(MP, fn);end

else
    error('Load or calculate point-matches first!');
end
