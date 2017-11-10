function save_K_petsc(fname,K)
    %in principle, thesefiles should only need the symmetric part. pastix
    %is balking on it though. So, let's be inefficient for now
    %if symm
    %    K=tril(K); %lower triangular
    %end
    
    %write to a binary petsc file format forpastix to read
    % http://www.mcs.anl.gov/petsc/petsc-current/docs/manualpages/Mat/MatLoad.html#MatLoad
    fp=fopen(fname,'wb','b');
    fwrite(fp,1211216,'uint32'); %MAT_FILE_CLASSID
    fwrite(fp,size(K,1),'uint32'); %nrows
    fwrite(fp,size(K,2),'uint32'); %ncols
    fwrite(fp,nnz(K),'uint32'); %nnz
    
    %nnzr = zeros(size(K,1),1,'uint32');
    nnzr =  full(sum(K~=0,2));
    %for i=1:size(K,1)
    %    nnzr(i)=nnz(K(i,:));
    %end
    fwrite(fp,nnzr,'uint32'); %non zeros per row
    %column pointers
    [i,j,s] = find(K);
    fwrite(fp,i-1,'uint32'); %column pointers
    fwrite(fp,s,'float64');  %non zero values
    fclose(fp);
    disp(strcat('Wrote',{' '},fname));