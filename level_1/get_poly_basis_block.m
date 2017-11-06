function p = get_poly_basis_block(m12_1, degree)
if degree>=0
p = [ones(size(m12_1, 1),1)];
end
if degree>0
p = [p m12_1(:,1) m12_1(:,2)];
end
if degree>1
p = [p m12_1(:,1).*m12_1(:,1) m12_1(:,1).*m12_1(:,2) m12_1(:,2).*m12_1(:,2)];
end