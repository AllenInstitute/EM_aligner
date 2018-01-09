import numpy as np
from pymongo import MongoClient
import matplotlib.pyplot as plt
from matplotlib.collections import PatchCollection
import matplotlib.patches as mpatches
from shapely.geometry import Polygon
from descartes.patch import PolygonPatch
import mpl_scatter_density
import renderapi
from multiprocessing import Pool
import copy
import requests
import sys

def make_patch(tile):
    pts = []
    pts.append((tile.minX,tile.minY))
    pts.append((tile.maxX,tile.minY))
    pts.append((tile.maxX,tile.maxY))
    pts.append((tile.minX,tile.maxY))
    pts.append((tile.minX,tile.minY))
    return PolygonPatch(Polygon(pts))

def plot_patches(ax,patches,bounds):
    for patch in patches:
        ax.add_patch(patch)
    ax.set_xlim(bounds['minX']*0.9,bounds['maxX']*1.1)
    ax.set_ylim(bounds['minY']*0.9,bounds['maxY']*1.1)
    ax.set_aspect(1)

def fixpi(arr):
    #make the angular values fall around zero
    ind = np.argwhere(arr>np.pi)
    while len(ind)!=0:
        arr[ind] = arr[ind]-2.0*np.pi
        ind = np.argwhere(arr>np.pi)
    ind = np.argwhere(arr<-np.pi)
    while len(ind)!=0:
        arr[ind] = arr[ind]+2.0*np.pi
        ind = np.argwhere(arr<-np.pi)
    return arr

def transform(pt,tr):
    #apply an affine transformation
    newpt = np.zeros_like(pt)
    newpt[0,:] = tr.M[0,0]*pt[0,:]+tr.M[0,1]*pt[1,:]+tr.M[0,2]
    newpt[1,:] = tr.M[1,0]*pt[0,:]+tr.M[1,1]*pt[1,:]+tr.M[1,2]
    return newpt

   
def make_sd_plot(fig,i,j,k,x,y,c):
    #function to make the map of the residuals as scatter density plots
    ax = fig.add_subplot(i,j,k,projection='scatter_density')
    density = ax.scatter_density(x, y, c=c,cmap=plt.cm.plasma_r)
    ax.set_aspect('equal')
    ax.patch.set_color([0.5,0.5,0.5])
    ax.set_xticks([])
    ax.set_yticks([])
    #ax.invert_yaxis() #match fine stack in ndviz
    fig.colorbar(density)
    return density

def make_sd_plot_thr(fig,i,j,k,x,y,c,thr):
    #function to make the map of the residuals as scatter density plots
 
    ax = fig.add_subplot(i,j,k,projection='scatter_density')
    ind = np.argwhere(c<thr).flatten()
    density = ax.scatter_density(x[ind], y[ind], color='k')
    ind = np.argwhere(c>=thr).flatten()
    density = ax.scatter(x[ind], y[ind], color='r',marker='.')

    ax.set_aspect('equal')
    #ax.patch.set_color([0.0,0.0,0.0])
    ax.set_xticks([])
    ax.set_yticks([])
    #ax.invert_yaxis() #match fine stack in ndviz
    #fig.colorbar(density)
    return density

def make_transform_patches(tilespecs):
    #getting tilespecs ready for plotting
    patches = []
    shearlist = []
    xscalelist = []
    yscalelist = []
    rotlist = []
    for ts in tilespecs:
        patches.append(make_patch(ts)) 
        shearlist.append(ts.tforms[1].shear)
        xscalelist.append(ts.tforms[1].scale[0])
        yscalelist.append(ts.tforms[1].scale[1])
        rotlist.append(ts.tforms[1].rotation)
    xscalelist = np.array(xscalelist)
    yscalelist = np.array(yscalelist)
    shearlist = fixpi(np.array(shearlist))
    rotlist = fixpi(np.array(rotlist))
    return [patches,shearlist,rotlist,xscalelist,yscalelist]

def make_transform_plot(fig,i,j,k,xlim,ylim,patches,value,bar=True,ax=None):
    #plot a map of the transform value
    cmap = plt.cm.plasma_r
    if ax==None:
        ax = fig.add_subplot(i,j,k,projection='scatter_density')
    ax.set_xlim(xlim)
    ax.set_ylim(ylim)
    LC = PatchCollection(patches,cmap=cmap)
    LC.set_array(value)
    LC.set_edgecolor('none')
    ax.add_collection(LC)
    if bar:
        fig.colorbar(LC)
    ax.set_aspect('equal')
    ax.patch.set_color([0.5,0.5,0.5])
    ax.set_xticks([])
    ax.set_yticks([])
    return ax

def compute_residuals(args):
    tids1 = args[0]
    tids2 = args[1]
    tforms1 = args[2]
    tforms2 = args[3]
    matches = args[4]
    nsub = args[5]
    threshold = args[6]
    xya = []
    xyd = [] 
    newmatches = []
    counts = [0,0]
    for match in matches:
        #cycle through each item, find the appropriate transforms, and apply the transform
        sind1 = np.argwhere(tids1==match['qId'])
        sind2 = np.argwhere(tids2==match['pId'])
        if (len(sind1)>0) & (len(sind2)>0):
            sind1 = sind1[0][0]
            sind2 = sind2[0][0]
            p = np.array(match['matches']['p'])
            q = np.array(match['matches']['q'])
            npts = p.shape[1]
            counts[0] = counts[0]+npts

            #filter the point matches, just to cut down the numbers
            subind = np.arange(npts)
            if (nsub!=-1)&(nsub<npts):
                #currently only random nsub chosen
                subind = np.random.choice(subind,nsub)
                #could add additional RANSAC here, like Khaled has
              
            pxy = transform(p[:,subind],tforms2[sind2])
            qxy = transform(q[:,subind],tforms1[sind1])

            #implement rss threshold
            newmatch = copy.copy(match)
            if newmatch.has_key('_id'):
                del newmatch['_id'] #render doesn't want this when we ingest it back in
            if threshold!=-1:
                rss = np.sqrt(np.power(pxy[0,:]-qxy[0,:],2.0)+np.power(pxy[1,:]-qxy[1,:],2.0))
                thind = np.argwhere(rss<threshold).flatten()
                newmatch['matches']['p'][0] = (np.array(newmatch['matches']['p'][0])[thind]).tolist()
                newmatch['matches']['p'][1] = (np.array(newmatch['matches']['p'][1])[thind]).tolist()
                newmatch['matches']['q'][0] = (np.array(newmatch['matches']['q'][0])[thind]).tolist()
                newmatch['matches']['q'][1] = (np.array(newmatch['matches']['q'][1])[thind]).tolist()
                newmatch['matches']['w'] = (np.array(newmatch['matches']['w'])[thind]).tolist()
            else:
                thind = np.arange(pxy.shape[1])
            #append onto the outputs
            if thind.size>0:
               xya.append(0.5*(pxy[:,thind]+qxy[:,thind]))
               xyd.append(pxy[:,thind]-qxy[:,thind])
               newmatches.append(newmatch) 
               counts[1] = counts[1]+thind.size

    return [np.block(xya),np.block(xyd),np.array(newmatches),counts] 

