function [obj, js] = register(obj, opts)
% In-layer montage! Pairwise registrations of all adjacent tiles, and
% update of optimal transformations  based on layer-wide optimization
%
% Usage: [obj, js] = register(obj)
% the property obj.method determines the registration method selected.
% 
%
% *Available methods:
% 'alignTEM',         ---> uses deformable alignment with the matrix method
% To add a method:
% Any registration methods may be added to this class as long as it updates
% the transformation object of every tile at the end of registration
%
%
%
% Author: Khaled Khairy. FlyTEM team project. Copyright 2016 Janelia Research Campus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

js = [];  % initialize output to return empty if not set by regisration method


%% Set the state of all tiles that are currently equal to zero to -1 
%  [they will not be considered for this registration]
% 
% All other tiles will be set to a state of zero, with the expectation that 
% after registration, tiles for which an accepted transformation exists 
% are set to a state of 'one' by the registration method itself
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% for tix = 1:numel(obj.tiles)
%     if obj.tiles(tix).state==0, obj.tiles(tix).state=-1;
%     elseif obj.tiles(tix).state==1
%     obj.tiles(tix).state = 0;
%     end
% end


%% perform registration
if strcmp(obj.method, 'alignTEM')         % use the deformable alignment with matrix solver
    [obj, js] = alignTEM_inlayer(obj, opts);
else
    disp('Method not recognized');
end
s = sum([obj.tiles(:).state]);
if s==0, error('no legal tiles found');end
%% update tile centers
obj = update_tile_centers(obj);
