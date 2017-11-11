import glob
import numpy as np
import matplotlib.pyplot as plt
from PastixRun import *
fnames=glob.glob('/allen/programs/celltypes/workgroups/em-connectomics/danielk/em-131sn_shared/log/*.log')

dlab=['Queen','Cube','Long','Hook','PFlow','Coup']

plt.figure(1)
plt.clf()
ax=plt.subplot(1,1,1)
xvals = []
logs=[]
for fname in fnames:
   logs.append(pastixrun(fname))
  
x=[]
y=[]
w=0.01
for log in logs:
    xvals.append(log.ntileeq/1e6)
    if 'hosts1' in log.cmd:
        xoff=-w
        clab='20'
    if 'hosts2' in log.cmd:
        xoff=0
        clab='40'
    if 'hosts3' in log.cmd:
        xoff=w
        clab='60'
    plt.bar(log.ntileeq/1e6+xoff,log.time_factorize,w,color='b',alpha=0.5,align='center')
    plt.text(log.ntileeq/1e6+xoff,200,clab,horizontalalignment='center')

xvals=np.unique(np.array(xvals))
plt.text(0.02,200,'NCPU',horizontalalignment='center')
ax.set_yscale("log")
plt.xlabel('Mtile equivalent',fontsize=18)
plt.ylabel('Time to factorize (and solve, etc.) [s]',fontsize=18)
plt.gca().set_xticks(xvals)
xtl = []
for xv in xvals:
    xtl.append('%0.2f'%xv)
plt.gca().set_xticklabels(xtl)
plt.xlim(0.0,0.5)
plt.show()
    
