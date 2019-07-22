#!/usr/bin/env python
from __future__ import print_function

import netCDF4 as nc
import numpy   as np
import argparse
import os.path
import shutil
import sys
import datetime

def die(message,code=255) :
    """ print message and quit """
    parser.print_usage()
    print('Error :: '+message)
    exit(code)

def addHistory(dst, text):
    """ add given text to the history attribute of the dst file """
    if 'history' in dst.ncattrs() :
        history = '\n'+dst.history
    else:
        history = ''
    dst.history = text+history

def report(verbosity,message):
    """ print message if verbosity level is high enough """
    if (args.verb>=verbosity) : print(message)


# parse command line
parser = argparse.ArgumentParser(description='''
     Mask out points where area is below specified tolerance.
     Note that that the "area" variable itself is treated slightly differently:
     instead of masking out, the values below tolerance are set to zero.''')
parser.add_argument('src', help='input file')
parser.add_argument('dst', help='output file (must not exist)')
parser.add_argument(
    '--area-file', dest='afile', default=None,
    help='file containing area variable (defaults to src).')
parser.add_argument(
    '--area-var', dest='avar', default='area',
    help='name of the area variable (defaults to "area").')
parser.add_argument(
    '--tolerance', dest='tol', type=float, default=0.0,
    help='''
         area tolerance; values of variables are set ro missing values
         if area is less or equal than this number (defaults to 0.0)
         ''')
parser.add_argument(
    '--variables', dest='vars',
    help='''
         comma-separated list of variables to process (defaults to all variables
         in the input file that are of the same shape as area)''')
parser.add_argument(
    '--exclude', dest='excl',
    help='''
         comma-separated list of variables NOT to process. This takes priority over
         inclusion. That is, if a variable appears in both "to process" and "exclude"
         lists, it will NOT be processed''')
parser.add_argument(
    '-v','--verbose', dest='verb', action='count',
    help='increase verbosity')
args=parser.parse_args()



# open input file
src = nc.Dataset(args.src, mode='r')

# open are file and find area variable
if args.afile:
    afile = nc.Dataset(args.afile, mode='r')
else :
    afile = src
area = afile.variables[args.avar]
area_units = area.units if 'units' in area.ncattrs() else '' # for verbose reporting only

# find variables to process: if the list of variables is not provided on the
# command line, process all variables in the netcdf files that have the same
# shape as area
if args.vars:
    vars = args.vars.split(',')
else:
    vars = src.variables.keys()
    vars = [ v for v in vars if v not in src.dimensions ]
    vars = [ v for v in vars if src[v].shape == area.shape ]
# exclude variables that the user wants to leave alone
if args.excl:
    vars = [v for v in vars if v not in args.excl.split(',')]

# create output file
if os.path.exists(args.dst) :
    die('file "%s" already exists'%args.dst)
shutil.copy2(args.src, args.dst)
dst = nc.Dataset(args.dst, mode='a')
# add command time stamp and command line to history attribute
addHistory(dst,datetime.datetime.now().isoformat(' ')+' : '+' '.join(sys.argv))

# process all variables
for name in vars :
    var = dst.variables[name]
    if name == args.avar or name == 'fracLut':
        # zero out areas below tolerance
        report(1,'zeroing-out values of "{}" below {} {}...'.format(name,args.tol,area_units))
        # for some reason var[area[:]<=args.tol] does not work, so we have to create a
        # temporary masked array
        tmp = np.ma.array(data=var[:],copy=True)
        tmp[area[:]<=args.tol] = 0.0
        var[:] = tmp[:]
    else :
        # mask out non-area variables
        report(1,'masking out values of "{}" where "{}" below {} {}...'.format(name, args.avar,args.tol, area_units))
        var[:] = np.ma.array(data=var[:],mask=(area[:]<=args.tol))

# close all files
for f in dst,src :
    f.close()

