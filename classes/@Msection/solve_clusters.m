function [mL, err, R, L_s_mL, w] = solve_clusters(L_vec, opts, stvec_flag)
% % returns a solved fully assembled coherent group of tiles
% % that could be made of more than one cluster (connected component)
% % 
% % L has full point pair information as obtained for example by using:
% % rc.stack = 'v9_acquire_LC_merged_2';
% % rc.owner='flyTEM';
% % rc.project='FAFB00';
% % rc.baseURL ='http://tem-services.int.janelia.org:8080/render-ws/v1';
% %
% % pm.server = 'http://tem-services.int.janelia.org:8080/render-ws/v1';
% % pm.owner  = 'flyTEM';
% % pm.match_collection = 'v9_2';
% %
% % nfirst = 1502;
% % nlast  = 1502;
% %
% % [L, tIds, PM] = load_point_matches(nfirst, nlast, rc, pm);
% %
% % Author: Khaled Khairy: Janelia Research Campus 2016
% %
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global L dref zC xr yr cm

if ~isfield(opts, 'calc_conf'), opts.calc_confidence = 0;end
if ~isfield(opts, 'small_region'), 
    opts.small_region = 1; 
    opts.small_region_labda = 1.0;
end

if nargin<3, stvec_flag = 0;end  % in that case we do not assume a starting value, and perform rigid fit
lambda = opts.lambda;
edge_lambda = opts.edge_lambda;

%% determine how clusters are related to place after registration
zC = {}; % store uniqe z values spanned by a component
for cix = 1:numel(L_vec)
    zC{cix} = unique([L_vec(cix).tiles(:).z]'); % z-values spanned by this component
end

if numel(zC)>1
zref = intersect(zC{1}, zC{2});
else
    zref = zC{1};
end
%%
L_s_mL = Msection; % array of connected components
err = [];
R = [];

for cix = 1:numel(L_vec)
    %disp(['Processing: ' num2str(cix) ' with #tiles: ' num2str(numel(L_vec(cix).tiles))]);
    if numel(L_vec(cix).tiles)>=opts.min_tiles
        
        if stvec_flag==0
            %%% perform rigid transformation
            [ll2r, errR, mL, is, it, Res]  = get_rigid_approximation...
                (L_vec(cix),opts.solver, opts);
            
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % RECOVER POSSIBLE ROTATION AND TRANSLATION RELATIVE TO MAIN COMPONENT
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            
            zref = intersect(zC{1}, zC{cix});
            indxz = find([ll2r.tiles(:).z]==zref(1));
            if cix==1 || zref(1) == min(zC{1}), 
                Lref = L_vec(cix);
            
            else
                % Lref is z section in component L_vec(cix) transformed 
                % relative to how L_vec(1) of lowest z was transformed
                % sosi: this will fail if main component doesn't span all z
                % get z = zref section of primary component
                Lz = split_z(L_vec(1));
                Lzp = Lz(find([Lz(:).z]==zref(1))); % z = zref(1) of primary component before registration
                % what was the necessary rotation
                anglep = zeros(numel(Lzp.tiles), 1);
                angle = zeros(numel(Lzp.tiles),1);
                Lz = split_z(L_s_mL(1)); % primary component after registration
                zind = find([Lz(:).z]==zref(1));
                Lref = L_vec(cix);
                
%                 indxLz = find([Lz(zind).tiles(:).z]==zref(1));
%                 for ix = 1:numel(Lz(zind).tiles)
%                     tindxo = Lzp.map_renderer_id(Lz(zind).tiles(ix).renderer_id);
%                     anglep(ix) = acosd(Lzp.tiles(tindxo).tform.T(1));
%                     angle(ix)  = acosd(Lz(zind).tiles(indxLz(ix)).tform.T(1));
%                 end
%                 da = mean(angle-anglep);
%                 cmr = get_center_of_mass(Lz(zind)); %calculate center of mass of this connected component
%                 % apply rotation to L_vec(cix) component
%                 
%                 for tix = 1:numel(Lref.tiles)
%                     Lref.tiles(tix) = rotate(Lref.tiles(tix), cmr(1), cmr(2), da);
%                 end
%                 %%%%%%%%%%%
                
                
                % what was the translation
                cm1 = get_center_of_mass(Lzp); %calculate center of mass of one section of connected component
                cm2 = get_center_of_mass(Lz(zind)); %calculate center of mass of this connected component
                % apply translation to 
                for tix = 1:numel(Lref.tiles)
                    Lref.tiles((tix)).tform.T([3 6]) = Lref.tiles((tix)).tform.T([3 6]) - (cm1-cm2);% - [dx dy];
                end
            end
            
            
            %%%%%%%%%%%%% Do rotation 
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%% Record angle of reference layer before rigid transformation
            %%% Record angle of first layer after rigid transformation
            anglep = zeros(numel(indxz), 1);
            angle = zeros(numel(indxz),1);
            Lz = split_z(ll2r);
            zind = find([Lz(:).z]==zref(1));
            for ix = 1:numel(indxz)
                tindxo = Lref.map_renderer_id(Lz(zind).tiles(ix).renderer_id);
                anglep(ix) = acosd(Lref.tiles(tindxo).tform.T(1));
                angle(ix)  = acosd(ll2r.tiles(indxz(ix)).tform.T(1));
            end
            
            
%             for tix = 1:numel(indxz)
%                 angle(tix) = acosd(ll2r.tiles(indxz(tix)).tform.T(1));
%             end
            % average angle difference for the reference layer
            da = mean(angle-anglep);
            
            Lz = split_z(ll2r);
            
            cm = get_center_of_mass(Lz(zind)); %calculate center of mass of this connected component

            %%% rotate all tiles around this center of mass using the average
            %%% angle da
            for tix = 1:numel(ll2r.tiles)
                ll2r.tiles(tix) = rotate(ll2r.tiles(tix), cm(1), cm(2), da);
            end
            
            %%%%% tanslation for this connected component
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%% Record tile positions of reference section before rigid transformation

            Lz = split_z(Lref);
            zind = find([Lz(:).z]==zref(1));
            cm1 = get_center_of_mass(Lz(zind)); %calculate center of mass of one section of connected component
            
            Lz = split_z(ll2r);
            zind = find([Lz(:).z]==zref(1));
            cm2 = get_center_of_mass(Lz(zind)); %calculate center of mass of this connected component
%             cm3 = get_center_of_mass(L_vec(1));
            for tix = 1:numel(ll2r.tiles)
                ll2r.tiles((tix)).tform.T([3 6]) = ll2r.tiles((tix)).tform.T([3 6]) + (cm1-cm2);% - [dx dy];
            end
  
            
        else
            ll2r = L_vec(cix);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if numel(ll2r.tiles)<=opts.small_region
            opts.lambda = opts.small_region_lambda;
            opts.edge_lambda = opts.small_region_lambda;
        else
            opts.lambda = lambda;
            opts.edge_lambda = edge_lambda;
        end
        if opts.degree==0
            ll2r.pm = [];
            L_s_mL(cix) = ll2r;
            R = [R Res(:)'];
        elseif opts.degree==1
            [lsolved, err(cix), Res, A, b, B, d, W, K, Lm, xout, LL2, U2, tB, td,...
                invalid, time_Axb] = solve_affine_explicit_region(ll2r, opts);
            R = [R Res(:)'];
            lsolved.pm = [];
            L_s_mL(cix) = lsolved;
        elseif opts.degree>1
            [ll3] = solve_affine_explicit_region(ll2r, opts);
            clear ll2r;
            tic
            [lsolved, err(cix), Res, A, b, B, d, W, K, Lm, xout, LL2, U2, tB, td,...
                invalid, time_Axb] =...
                solve_polynomial_explicit_region(ll3,opts.degree, opts);
            toc
            R = [R Res(:)'];
            lsolved.pm = [];
            L_s_mL(cix) = lsolved;
        end
        %R(cix) = {[Res]};
        %R = [R Res(:)'];
        if opts.calc_confidence
        % estimate confidence interval
        w{cix} = bootstrp(100, @solve_AxB, Lm, K);
        else
            w{cix} = [];
        end
            
    end

end
%%
mL = concatenate_tiles(L_s_mL, opts.outlier_lambda);

