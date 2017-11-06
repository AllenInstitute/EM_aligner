function [nfirstvec, nlastvec, tilecountvec] = collection_zranges_by_ntiles(tiles_per_slab, slo, ntiles,  zu)

disp(tiles_per_slab);
disp(slo);

cumntiles = cumsum(ntiles);
ct = cumntiles;
zcurr = zu;
counter = 0;
indxpos = 0;
nfirstvec = [];
nlastvec = [];
ixfirst = [];
ixlast  = [];
tilecountvec = [];
nfirstvec(1) = 1;
accum = 1;


ixlast(1)  = slo + 1;
counter = 0;
slab_accum = 1;
kkcount = 0;
while slab_accum
    counter = counter + 1;
    % update ixfirst position
    ixfirst(counter) = ixlast(end)-slo; % start the next slab slo slabs before last for overlap
    last_pos = ixfirst(counter); % initialize the new last position 
    
    % determine index (ixlast) of last section in a slab
    last_accum = 1;  % enable the loop
    while last_accum
        if last_pos <= numel(ntiles)
            s = sum(ntiles(ixfirst(counter):last_pos));
            if s<tiles_per_slab
                last_pos = last_pos + 1;
            else
                ixlast(counter) = last_pos;
                tilecountvec(counter) = s;
                last_accum = 0;
            end
        else
            slab_accum = 0;
        end
    end
    
disp([zu(ixfirst(counter)) zu(ixlast(counter)) tilecountvec(counter) ...
    zu(ixlast(counter))-zu(ixfirst(counter)) ...
    tilecountvec(counter)/(zu(ixlast(counter))-zu(ixfirst(counter)))]);

    kkcount = kkcount + 1;
    disp(kkcount);
    if kkcount>20, slab_accum = 0;end
end



% 
% while accum
%     disp(counter);
%     indx = find(ct<tiles_per_slab);
%     tilecountvec(counter) = ct(indx(end));
%     %disp([indx(end) numel(indx) ct(indx(end))]);
%     nfirstvec(counter) = zcurr(indx(1));
%     ixfirst(counter) = indx(1);
%     if indx(end)>numel(zcurr)
%         nlastvec(counter) = zcurr(end);
%         ixlast(counter) = numel(nlast);
%     else
%         nlastvec(counter) = zcurr(indx(end));
%         ixlast(counter) = indx(end);
%     end
%     disp([nfirstvec(counter) nlastvec(counter) tilecountvec(counter) ...
%         nlastvec(counter)-nfirstvec(counter) tilecountvec(counter)/(nlastvec(counter)-nfirstvec(counter))]);
%     %     zcurr = zu(nlastvec(counter)-slo:numel(zu));
%     if nlastvec(end)~=zu(end)
%         zcurr = zcurr(indx(end)-slo:numel(zcurr));
%        indxpos = indxpos + numel(indx) -slo;   % keep track of where we are on ntiles
%        disp('ntiles range');
%        disp([indxpos numel(ntiles)]);
%        ct = cumsum(ntiles(indxpos:numel(ntiles)));
%        ct = cumsum(ntiles(ixfirst(counter):ixlast(counter)));
%        counter = counter + 1;
%         if counter>2
%             if nfirstvec(end)==nfirstvec(end-1)
%                 accum = 0;
%                 nfirstvec(end-1:end) = [];
%                 nlastvec(end-1:end) = [];
%                 
%             end
%         end
%     else
%         accum = 0;
%     end
% 
% end
disp('Slabs defined:');
disp([nfirstvec(:) nlastvec(:) tilecountvec(:)]);