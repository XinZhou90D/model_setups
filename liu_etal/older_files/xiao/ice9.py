import netCDF4 as nc
import numpy as np
import hashlib
import matplotlib.pyplot as plt

def ice9it(i,j,depth,shallow=0.0):
    # Iterative implementation of "ice 9"
    wetMask = 0*depth
    (nj,ni) = wetMask.shape
    stack = set()
    stack.add( (j,i) )
    while stack:
        (j,i) = stack.pop()
        if wetMask[j,i] or depth[j,i] <= shallow: continue
        wetMask[j,i] = 1
        if i>0: stack.add( (j,i-1) )
        else: stack.add( (j,ni-1) )
        if i<ni-1: stack.add( (j,i+1) )
        else: stack.add( (0,j) )
        if j>0: stack.add( (j-1,i) )
        if j<nj-1: stack.add( (j+1,i) )
        else: stack.add( (j,ni-1-i) )
    return wetMask
    
def error(note):
    print note

def applyIce9(depth, shallow=0.0,seedDepth=3000.0):

    origDepth = depth*np.where(depth > shallow, 1, 0)
    numOrigWet = np.count_nonzero(origDepth)
    print '# of wet points deeper than %f = %i'%(shallow,numOrigWet)    
    res=np.argwhere(depth>seedDepth)
    j0,i0= res[0][0],res[0][1]
    notLand = ice9it(i0,j0,depth,shallow)
    print 'Analyzing...'
    numNotLand = np.count_nonzero(notLand)
    print '# of wet points after Ice 9 = %i'%(numNotLand)
    newDepth = depth*np.where(depth*notLand > shallow, 1, 0)
    numNewWet = np.count_nonzero(newDepth)
    print '# of wet points deeper than %f = %i'%(shallow,numNewWet)
    print '%i - %i = %i fewer points left'%(numOrigWet,numNewWet,numOrigWet-numNewWet)
    newWet = ice9it(i0,j0,newDepth)
    numNewDeep = np.count_nonzero(newWet)
    print '# of wet deep points after Ice 9 = %i'%(numNewDeep)
    print '%i - %i = %i fewer points left'%(numNewWet,numNewDeep,numNewWet-numNewDeep)
    return newDepth


D=nc.Dataset('topog.nc').variables['depth'][:]

newDepth = applyIce9(D,shallow=0.0)


h1=hashlib.md5(D)
h2=hashlib.md5(newDepth)

f=nc.Dataset('topog.nc','a')
f.variables['depth'][:]=newDepth

f.sync()
f.close()

D_msk=np.ma.masked_where(newDepth==0.,newDepth)
plt.pcolormesh(D_msk)
plt.show()

