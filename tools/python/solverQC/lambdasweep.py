import numpy as np
import matplotlib.pyplot as plt
import MatlabClasses as mlc
reload(mlc)
import json
import renderapi

dirs = []
dirs.append('/allen/programs/celltypes/workgroups/em-connectomics/danielk/solver_exchange/matlab/20171211.7/')
dirs.append('/allen/programs/celltypes/workgroups/em-connectomics/danielk/solver_exchange/matlab/20171211.8/')
dirs.append('/allen/programs/celltypes/workgroups/em-connectomics/danielk/solver_exchange/matlab/20171211.9/')
dirs.append('/allen/programs/celltypes/workgroups/em-connectomics/danielk/solver_exchange/matlab/20171211.10/')
dirs.append('/allen/programs/celltypes/workgroups/em-connectomics/danielk/solver_exchange/matlab/20171211.11/')
dirs.append('/allen/programs/celltypes/workgroups/em-connectomics/danielk/solver_exchange/matlab/20171211.12/')
dirs.append('/allen/programs/celltypes/workgroups/em-connectomics/danielk/solver_exchange/matlab/20171211.13/')
dirs.append('/allen/programs/celltypes/workgroups/em-connectomics/danielk/solver_exchange/matlab/20171211.14/')
dirs.append('/allen/programs/celltypes/workgroups/em-connectomics/danielk/solver_exchange/matlab/20171211.15/')
dirs.append('/allen/programs/celltypes/workgroups/em-connectomics/danielk/solver_exchange/matlab/20171211.17/')
dirs.append('/allen/programs/celltypes/workgroups/em-connectomics/danielk/solver_exchange/matlab/20171211.18/')
dirs.append('/allen/programs/celltypes/workgroups/em-connectomics/danielk/solver_exchange/matlab/20171211.19/')
dirs.append('/allen/programs/celltypes/workgroups/em-connectomics/danielk/solver_exchange/matlab/20171211.20/')
dirs.append('/allen/programs/celltypes/workgroups/em-connectomics/danielk/solver_exchange/matlab/20171211.21/')
dirs.append('/allen/programs/celltypes/workgroups/em-connectomics/danielk/solver_exchange/matlab/20171211.22/')
dirs.append('/allen/programs/celltypes/workgroups/em-connectomics/danielk/solver_exchange/matlab/20171211.23/')

inputs = []
lam = []
shear = []
scalex = []
scaley = []
rot = []
render_connect_params ={
    'host':'em-131fs',
    'port':8080,
    'owner':'danielk',
    'project':'MM2',
    'client_scripts':'/allen/programs/celltypes/workgroups/em-connectomics/gayathrim/nc-em2/Janelia_Pipeline/render_latest/render-ws-java-client/src/main/scripts',
    'memGB':'2G'
}
render = renderapi.connect(**render_connect_params)
for d in dirs:
    fp = open(d+'input.json','r')
    inputs.append(json.load(fp))
    fp.close()
    lam.append(inputs[-1]['solver_options']['lambda'])
    stack = inputs[-1]['target_collection']['stack']
    project = inputs[-1]['target_collection']['project']
    result_stack = renderapi.tilespec.get_tile_specs_from_stack(stack,render=render,project=project)
    tmpshear = 0.0
    tmpscalex = 0.0
    tmpscaley = 0.0
    tmprot = 0.0
    for t in result_stack:
        #tmpshear = tmpshear+np.abs(t.tforms[1].shear)
        #tmprot = tmprot+np.abs(t.tforms[1].rotation)
        tmpshear = tmpshear+(t.tforms[1].shear)
        tmprot = tmprot+(t.tforms[1].rotation)
        tmpscalex = tmpscalex+np.abs(t.tforms[1].scale[0])
        tmpscaley = tmpscaley+np.abs(t.tforms[1].scale[1])
    tmpshear = tmpshear/len(result_stack)
    tmprot = tmprot/len(result_stack)
    tmpscalex = tmpscalex/len(result_stack)
    tmpscaley = tmpscaley/len(result_stack)
    rot.append(tmprot)
    shear.append(tmpshear)
    scalex.append(tmpscalex)
    scaley.append(tmpscaley)
   


print 'lambda   error   shear   rotation   scalex   scaley'
ind = np.argsort(lam)
err = []
for i in np.arange(len(dirs)):
    d = mlc.Diagnostics(dirs[i],'Diagnostics.mat',words=False,plot=False)
    err.append(d.err)
for j in np.arange(len(dirs)):
    i = ind[j]
    print '%0.2e %0.2e %0.2f %0.2f %0.2f %0.2f'%(lam[i],d.err,shear[i],rot[i],scalex[i],scaley[i])

lam = np.array(lam)
err = np.array(err)
shear = np.array(shear)
rot = np.array(rot)
scalex = np.array(scalex)
scaley = np.array(scaley)

plt.figure(1)
plt.clf()
plt.subplot(5,1,1)
plt.loglog(lam[ind],err[ind],'-o')
plt.ylabel('Residual error')
plt.gca().set_xticklabels([])
plt.grid()

plt.subplot(5,1,2)
#plt.loglog(lam[ind],shear[ind],'-o')
plt.semilogx(lam[ind],shear[ind],'-o')
plt.ylabel('avg shear')
plt.gca().set_xticklabels([])
plt.grid()

plt.subplot(5,1,3)
#plt.loglog(lam[ind],rot[ind],'-o')
plt.semilogx(lam[ind],rot[ind],'-o')
plt.ylabel('avg rotation')
plt.gca().set_xticklabels([])
plt.grid()

plt.subplot(5,1,4)
plt.semilogx(lam[ind],scalex[ind],'-o')
plt.ylabel('avg x scale')
plt.gca().set_xticklabels([])
plt.grid()

plt.subplot(5,1,5)
plt.semilogx(lam[ind],scaley[ind],'-o')
plt.ylabel('avg y scale')
plt.grid()
plt.xlabel('regularization lambda')
plt.show()
