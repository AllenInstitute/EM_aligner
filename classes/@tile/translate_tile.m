function obj = translate_tile(obj, d)

if isa(obj.tform,  'images.geotrans.PolynomialTransformation2D')
    A = obj.tform.A;
    B = obj.tform.B;
    A(1) = A(1)-d(1);
    B(1) = B(1)-d(2);
    obj.tform = images.geotrans.PolynomialTransformation2D(A,B);
else
    obj.tform.T([3 6]) = obj.tform.T([3 6])-d;
end
