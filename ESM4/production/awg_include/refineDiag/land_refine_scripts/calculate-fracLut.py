#!/usr/bin/env python
from __future__ import print_function

import netCDF4 as nc
import numpy   as np
import argparse
import sys
import datetime


def cloneAttrs(src,dst):
    '''
    Copies all attributes from src to dst. Returns dst.
    '''
    # it may be more efficient to use dst.setncatts(src.__dict__),
    # except I am not absolutely sure __dict__ doesn't contain something
    # else besides netcdf attributes
    for att in src.ncattrs() :
        dst.setncattr(att,src.getncattr(att))
    return dst

def cloneVar(src,varname,dst,name=None):
    '''
    Clones a variable definition from src to dst with all dimensions and
    attributes, possibly renaming it. Variable data are not copied.
    Returns new variable.
    src     -- netcdf dataset
    varname -- name of the variable
    dst     -- destination netcdf dataset
    name    -- new name of the variable
    Note that if dimensions in dst are of different size, the size of the
    variable will match them.
    '''
    if name is None:
        name=varname
    srcVar=src.variables[varname]
    # what about fill_value, etc?
    dstVar=dst.createVariable(name,srcVar.dtype,srcVar.dimensions)
    cloneAttrs(srcVar,dstVar)
    return dstVar

def addHistory(dst, text):
    """ add given text to the history attribute of the dst file """
    if 'history' in dst.ncattrs() :
        history = '\n'+dst.history
    else:
        history = ''
    dst.history = text+history

def report(message,verbosity=0):
    """ print message if verbosity level is high enough """
    if (args.verb>verbosity) : print(message)

def die(message,code=255) :
    """ print message and quit """
    parser.print_usage()
    print('Error :: '+message)
    exit(code)



# parse command line
parser = argparse.ArgumentParser(description='''
     if fracLut does not exist, calculate it from land use area and cell area.
     WARNING: it updates the file.''')
parser.add_argument('file', help='input/output file')
parser.add_argument(
    '--cell-area-file', dest='afile', default=None, required=True,
    help='file containing cell area variable.')
parser.add_argument(
    '-v','--verbose', dest='verb', action='count',
    help='increase verbosity')
args=parser.parse_args()


# open input file
src = nc.Dataset(args.file, mode='a')
if 'fracLut' in src.variables:
    report('"fracLut" variable already exists, not touching file')
    exit(0)
area = src.variables['area']

# open area file and find area variable
afile = nc.Dataset(args.afile, mode='r')
cell_area = afile.variables['cell_area']

# add command time stamp and command line to history attribute
addHistory(src,datetime.datetime.now().isoformat(' ')+' : '+' '.join(sys.argv))

# create fracLut variable
fracLut = cloneVar(src,'area',src,'fracLut')
fracLut.long_name = "Fraction of Grid Cell for Each Land Use Tile" ;
fracLut.units = "%" ;
fracLut.cell_methods = "area: mean time: mean" ;
fracLut.cell_measures = "area: cell_area" ;
fracLut.standard_name = "area_fraction" ;

# calculate the values
fracLut[:] = np.minimum(area[:]/cell_area[:]*100.0,100.0)

# clone cell_area variable
cellArea = cloneVar(afile,'cell_area',src)
cellArea[:] = cell_area[:]

# close input/output file
src.close()

