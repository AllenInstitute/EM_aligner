from scipy.io import loadmat
import matplotlib.pyplot as plt
import numpy as np

class Diagnostics:
    def __init__(self,fdir,fname):
        self.fdir=fdir
        self.fname=fname
        self.raw=(loadmat(fdir+'/'+fname))['Diagnostics']
        self.parse()
        self.words()
        self.plot_overview()

    def parse(self):
        self.sections = self.raw[0][0][0][0]
        self.ntiles = self.raw[0][0][1][0][0]
        self.timer_generate_A = self.raw[0][0][2][0][0]
        self.timer_solve_A = self.raw[0][0][3][0][0]
        self.nnz_A = self.raw[0][0][4][0][0]
        self.nnz_K = self.raw[0][0][5][0][0]
        self.precision = self.raw[0][0][6][0][0]
        self.err = self.raw[0][0][7][0][0]
        self.dim_A = self.raw[0][0][8][0]
        self.residuals = self.raw[0][0][9]
        self.tile_err = self.raw[0][0][10]
        self.rms = self.raw[0][0][11]
        self.delix = self.raw[0][0][12]
  
    def words(self):
        print 'Read from %s/%s'%(self.fdir,self.fname)
        print 'number of sections : %d'%self.sections.size
        tstr = 'sections used: '
        for s in self.sections: tstr = tstr+'%d, '%s
        print tstr
        print 'number of tiles    : %d'%self.ntiles
        print 'time to generate A : %0.1f seconds'%self.timer_generate_A
        print 'time to solve:     : %0.1f seconds'%self.timer_solve_A
        print 'size of A          : %0.6e x %0.6e'%(self.dim_A[0],self.dim_A[1])
        print 'nnz in A           : %d'%self.nnz_A
        print 'nnz in K           : %d'%self.nnz_K
        print 'precision of soln  : %0.1e   (norm(K*x-Lm)/norm(Lm))'%self.precision
        print 'error              : %0.1e   norm(A*x-b) (not K!)'%self.err

    def plot_overview(self): 
        f = plt.figure()
        print 'Showing in Figure %s'%f.number
        # residuals
        plt.subplot(3,1,1)
        plt.plot(self.residuals,'-k')
        plt.xlabel('row of A (point match DOF)')
        plt.ylabel('residual (Ax-b) [pixels]')
        plt.grid()
        plt.xlim(0,self.residuals.size)
        plt.ticklabel_format(style='sci', axis='x', scilimits=(0,0))

        #tile error x
        plt.subplot(3,2,3)
        plt.plot(self.tile_err[:,0])
        plt.grid()
        plt.xlim(0,self.tile_err.shape[0])
        plt.ylabel('average x error per tile [pixels]')
        plt.xlabel('tile number')
        
        #tile error y
        plt.subplot(3,2,5)
        plt.plot(self.tile_err[:,1])
        plt.grid()
        plt.xlim(0,self.tile_err.shape[0])
        plt.ylabel('average y error per tile [pixels]')
        plt.xlabel('tile number')

        #rms
        plt.subplot(3,2,4)
        plt.plot(self.rms,'g')
        plt.xlim(0,self.tile_err.shape[0])
        plt.grid()
        plt.ylabel('rms error per tile [pixels]')
        plt.xlabel('tile number')
        
        #delix
        plt.subplot(3,2,6)
        plt.plot(self.delix,'m')
        plt.xlim(0,self.tile_err.shape[0])
        plt.grid()
        plt.ylabel('delix')
        plt.xlabel('tile number')
        
class PointMatches:
    def __init__(self,fdir,fname):
        self.fdir=fdir
        self.fname=fname
        self.raw=(loadmat(fdir+'/'+fname))['PM']
        self.parse()
        self.words()
        self.plot_overview()

    def parse(self):
        self.ntilepairs = len(self.raw[0][0][0])
        self.nptsperpair = np.zeros(self.ntilepairs)
        for i in np.arange(self.ntilepairs):
            self.nptsperpair[i] = len(self.raw[0][0][0][i][0]) 

    def words(self):
        print 'Read from %s/%s'%(self.fdir,self.fname)
        print 'number of tile pairs : %d'%self.ntilepairs
        print 'average pts per pair : %0.1f'%(self.nptsperpair.mean())

    def plot_overview(self):
        f=plt.figure()
        plt.subplot(2,1,1)
        plt.plot(self.nptsperpair,'.')
        plt.xlim(0,self.nptsperpair.size)
        plt.grid()
        plt.xlabel('tile pair number')
        plt.ylabel('points per pair')
        plt.ticklabel_format(style='sci', axis='x', scilimits=(0,0))

        plt.subplot(2,2,3)
        plt.hist(self.nptsperpair,bins=20)
        plt.grid()
        plt.ylabel('# pts per tile pair')
        plt.xlabel('# of tile pairs')
        plt.ticklabel_format(style='sci', axis='y', scilimits=(0,0))

