
figure(1);
clf();

G = graph(K,'upper','omitselfloops');

subplot(1,3,1);
spy(A);
title('structure of A');

subplot(1,3,2);
spy(K);
title('graph of K');

subplot(1,3,3);
p = plot(G);
title('graph of K');
