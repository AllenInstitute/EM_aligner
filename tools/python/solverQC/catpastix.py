import numpy as np
import glob
import sys

#look in this directory for xpa*.txt
fdir = sys.argv[1]

#list all of them
pfiles = glob.glob(fdir+'xpa*.txt')

#sort the file names into order
ind = []
for pf in pfiles:
    ind.append(int(pf.split('xpa')[1].split('.')[0]))
ind = np.array(ind)    
s = np.argsort(ind)
pfiles =np.array(pfiles)[s]

#append file contents onto big array
pasin = np.array([0,0])#set the shape
for pf in pfiles:
    pasin = np.vstack((pasin,np.loadtxt(pf)))
pasin = pasin[1:,:]    #lose the first entry

#reorder the array
reind = pasin[:,0].astype('int')-1
psol = np.zeros_like(reind).astype('float')
psol[reind] = pasin[:,1]

#save the result
np.savetxt(fdir+'all_xpa.txt',psol,fmt='%0.10f')
