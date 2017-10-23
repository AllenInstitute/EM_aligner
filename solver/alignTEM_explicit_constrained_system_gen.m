function [B,d, tB, td] = alignTEM_explicit_constrained_system_gen(L, options, tdim, ncoeff, sf)
% % construct regularization matrix B and vector d  
% % tB and td have the translation factor mutiplied to x and y for use in
% the regularized system construction

if options.verbose,disp('Populating d');end
d = zeros(ncoeff,1);
td = zeros(ncoeff,1);
if options.verbose, disp('Populating vector d');end
pos = 0;
for lix = 1:numel(L)
    %if options.verbose, disp(['Adding vector d elements for layer: ' num2str(lix)]);end
    for tix = 1:numel(L(lix).tiles)
            if tdim==6
                d(pos+1:pos+tdim) = L(lix).tiles(tix).tform.T(1:6);
                tt = L(lix).tiles(tix).tform.T(1:6);
                tt(3) = tt(3) * options.translation_fac;
                tt(6) = tt(6) * options.translation_fac;
                td(pos+1:pos+tdim) = tt;
            elseif tdim==12 && strcmp(class(L(lix).tiles(tix).tform), 'affine2d')
                t = L(lix).tiles(tix).tform.T(1:6);
                d(pos+1:pos+tdim) = [t(3) t(1) t(2) 0 0 0 t(6) t(4) t(5) 0 0 0];
                td(pos+1:pos+tdim) = [t(3)*options.translation_fac t(1) t(2) 0 0 0 t(6)*options.translation_fac t(4) t(5) 0 0 0];
            elseif tdim==20
                t = L(lix).tiles(tix).tform.T(1:6);
                d(pos+1:pos+tdim) = [t(3) t(1) t(2) zeros(1,7) t(6) t(4) t(5) zeros(1,7)];
                td(pos+1:pos+tdim) = [t(3)*options.translation_fac t(1) t(2) zeros(1,7)...
                                      t(6)*options.translation_fac t(4) t(5) zeros(1,7)];
            else
                error('wrong tdim');
            end
            pos = pos + tdim;
    end
end
% % scaling x and y in the starting vector d
% Tfacx = max(abs(d(3:6:end)));
% Tfacy = max(abs(d(6:6:end)));
d(3:6:end) = d(3:6:end)./sf(1);
d(6:6:end) = d(6:6:end)./sf(2);
if options.verbose,
    disp('Constructing matrix B');
    disp(['Using translation factor: ' num2str(options.translation_fac)]);
end
Bd = ones(ncoeff,1);
tBd = ones(ncoeff,1);
if tdim ==6
    tBd(3:3:end) = options.translation_fac;% options.translation_fac;% 0 = do not constrain translation
elseif tdim==12
    tBd(1:6:end) = options.translation_fac;
elseif tdim==20
    tBd(1:10:end) = options.translation_fac;
end
B = sparse(1:ncoeff, 1:ncoeff, Bd, ncoeff, ncoeff);
%% differential containts for individual parameters
if isfield(options, 'dw')
    if ~isempty(options.dw)
        if tdim==6,
            tBd(1:6:end) = options.dw(1);
            tBd(2:6:end) = options.dw(2);
            tBd(4:6:end) = options.dw(4);
            tBd(5:6:end) = options.dw(5);
        end
    end
end
%%
tB = sparse(1:ncoeff, 1:ncoeff, tBd, ncoeff, ncoeff);












