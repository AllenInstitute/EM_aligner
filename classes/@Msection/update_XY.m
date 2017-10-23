function [obj, P, Pix, pcell, bocell] = update_XY(obj, n)
% update the working arrays X and Y that record center position of
% tiles
% Note: This information is in principle in individual tile objects but is handy to have.
if nargin<2, n = 55+4;end
obj.X = zeros(numel(obj.tiles), 1);
obj.Y = zeros(numel(obj.tiles), 1);
if nargout>1
P = zeros(numel(obj.tiles), n*2);
Pix = zeros(numel(obj.tiles),n);
else
    P = [];
    Pix = [];
end
pcell = {};
if nargout>5, bocell = {};end;
if strcmp(class(obj.tiles(1).tform), 'images.geotrans.PolynomialTransformation2D')...
        || strcmp(class(obj.tiles(1).tform), 'nonlin2d')
%     disp(' update_XY under testing for polynomials');
    
    for tix = 1:numel(obj.tiles)
        %     obj.X(tix) = obj.tiles(tix).tform.T(3) + obj.tiles(tix).W/2;
        %     obj.Y(tix) = obj.tiles(tix).tform.T(6) + obj.tiles(tix).H/2;
        
        px = obj.tiles(tix).W/2;
        py = obj.tiles(tix).H/2;
%         p  = [px py 1] * obj.tiles(tix).tform.T;
%         obj.X(tix) = [1 px py px.*py px.*px py.*py] * obj.tiles(tix).tform.A(:);
%         obj.Y(tix) = [1 px py px.*py px.*px py.*py] * obj.tiles(tix).tform.B(:);
%         
        U = transformPointsInverse(obj.tiles(tix).tform,[px py]);
        obj.X(tix) = U(1);
        obj.Y(tix) = U(2);
        
        W = obj.tiles(tix).W;
        H = obj.tiles(tix).H;
        bb = [0 0;W 0;0 H;W H];
        aa = [rand(n-4,1)*W rand(n-4,1)*H];
        bo = [aa;bb];
        p = transformPointsInverse(obj.tiles(tix).tform,bo);
        P(tix,:)   = p(:)';
        Pix(tix,:) = ones(1,n)*tix;
    end

else
    
    for tix = 1:numel(obj.tiles)
        %     obj.X(tix) = obj.tiles(tix).tform.T(3) + obj.tiles(tix).W/2;
        %     obj.Y(tix) = obj.tiles(tix).tform.T(6) + obj.tiles(tix).H/2;
        
        px = obj.tiles(tix).W/2;
        py = obj.tiles(tix).H/2;
        p  = [px py 1] * obj.tiles(tix).tform.T;
        obj.X(tix) = p(1);
        obj.Y(tix) = p(2);
        if nargout>1
        W = obj.tiles(tix).W;
        H = obj.tiles(tix).H;
        bb = [0 0 1;W 0 1;0 H 1;W H 1];
        aa = [rand(n-4,1)*W rand(n-4,1)*H ones(n-4,1)];
        bo = [aa;bb];
        p = bo*obj.tiles(tix).tform.T;
        p = p(:,1:2);
        pcell{tix} = p;
        if nargout>4, bocell{tix} = bo;end
        P(tix,:)   = p(:)';
        Pix(tix,:) = ones(1,n)*tix;
        
        end
    end
end

if nargout>1
P = reshape(P, numel(obj.tiles) * n, 2);
    Pix = reshape(Pix,numel(obj.tiles)*n,1);
end


























