function save_Lm_petsc(fname,Lm)
    %for some reason, pastix wants the RHS in ascii (while the matrix is in binary)
    fp=fopen(fname,'w');
    %fprintf(fp,'%0.10f\n',Lm); sparse write failed for solve_rigid
    fprintf(fp,'%0.10f\n',full(Lm));
    fclose(fp);