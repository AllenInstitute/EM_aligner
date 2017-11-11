import numpy as np
import matplotlib.pyplot as plt
import Diagnostics 
reload(Diagnostics)
from Diagnostics import Diagnostics

fdir='/allen/programs/celltypes/workgroups/em-connectomics/danielk/EM_aligner/breakpoints'
fname='5_sections_standard_forcesymm_diagnostics.mat'
d=Diagnostics(fdir,fname)
