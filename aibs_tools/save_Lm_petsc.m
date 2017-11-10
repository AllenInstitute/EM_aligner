function save_Lm_petsc(fname,Lm)
    %for some reason, pastix wants the RHS in ascii (while the matrix is in binary)
    fp=fopen(fname,'w');
    %for i=1:size(Lm,1)
    fprintf(fp,'%0.10f\n',Lm);
    %end
    fclose(fp);