import numpy as np

class pastixrun:
    def __init__(self,fname):
        self.fname=fname
        self.parse(fname)

    def parse(self,fname):
        #read the file
        f=open(fname,'r')
        self.lines=f.readlines()
        f.close()
        #get the command
        self.cmd=self.lines[0].split('\n')[0]
        #get matrix size
        self.time_analyze=np.nan
        self.time_factorize=np.nan
        self.time_solve=np.nan
        self.time_refine=np.nan
        for line in self.lines:
            if 'Matrix size' in line:
                tmp=line.split()
                self.ndof=int(tmp[-1])
                self.ntileeq=int(self.ndof/6.)
            if 'Time to analyze' in line:
                tmp=line.split()
                self.time_analyze=float(tmp[-2])
            if ('Time to factorize' in line)&('Prediction' not in line):
                tmp=line.split()
                self.time_factorize=float(tmp[-2])
            if 'Time to solve' in line:
                tmp=line.split()
                self.time_solve=float(tmp[-2])
            if 'Time for refinement' in line:
                tmp=line.split()
                self.time_refine=float(tmp[-2])
        self.time=np.array([self.time_analyze,self.time_factorize,self.time_solve,self.time_refine])

