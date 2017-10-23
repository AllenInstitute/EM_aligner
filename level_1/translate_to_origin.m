function obj = translate_to_origin(obj)

disp('Deprecated');
% % % mL = get_bounding_box(mL);
% % tiles = obj.tiles;
% % parfor ix = 1:numel(tiles)
% %     if isa(tiles(ix).tform,  'images.geotrans.PolynomialTransformation2D')
% %         X(ix) = tiles(ix).tform.A(1);
% %         Y(ix) = tiles(ix).tform.B(1);
% %         
% %     else
% %         X(ix) = tiles(ix).tform.T(3);
% %         Y(ix) = tiles(ix).tform.T(6);
% %         
% %     end
% % end
% % 
% % delta = 0;
% % dx = min(X(:)) + delta;%mL.box(1);
% % dy = min(Y(:)) + delta;%mL.box(2);
% % 
% % parfor ix = 1:numel(obj.tiles)
% %     tiles(ix) = translate_tile(tiles(ix), -[dx dy]);
% % end
% % obj.tiles = tiles;