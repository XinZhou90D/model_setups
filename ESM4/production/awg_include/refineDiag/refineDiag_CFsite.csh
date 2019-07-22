#!/bin/csh -fx
#
# Background:
# For CMIP6, CFMIP requests instantaneous high-frequency output at 126 specific sites.
# The output for all sites should be saved in a single file, with a "site" dimension
# that indicates the site number. See http://clipc-services.ceda.ac.uk/dreq/u/MIPtable::CFsubhr.html
# The FMS diag manager can save out site-data, but each site is saved to a different diagfile.
#
# Inputs:
# 126 history files of this pattern: CFsite_XXX*, where XXX corresponds to the 126 sites
#
# Output:
# One file, CFsite.nc, that contains the output from the 126 sites in CMIP-compliant format.
#
# Description:
# 1. The degenerate FMS lat/lon dimensions (e.g. grid_yt_sub01, grid_xt_sub01) are removed using ncwa.
# 2. The 126 files from step 1 are combined using ncecat, which creates a new "site" dimension
#    that represents the 126 files.
# 3. The record dimension is returned to "time" from "site" using ncpdq.
#
# Usage:
# Designed to be source'd by the refineDiag step in frepp.
# Required frepp variables: $oname, $refineDiagDir

setenv NC_BLKSZ 64K
alias ncwa "ncwa --overwrite --header_pad 16384"
alias ncecat "ncecat --overwrite --header_pad 16384"
alias ncpdq "ncpdq --overwrite --header_pad 16384"
alias ncatted "ncatted --overwrite --header_pad 16384"

# Verify there are 126 site files
set files = (`ls *.CFsite_???.tile?.nc`)
if ($#files != 126) then
    echo "ERROR: Expected 126 site files but found only $#files"
    exit 1
endif

# Combine files into a single file with dimension "site"
# NOTE: output file must be named "CFsites" (plural) to avoid frepp using the CFsite_XXX for statics
set output = "$oname.CFsites.nc"
ncecat -u site $files $output
if ($status) then
    echo "ERROR: ncecat error"
    exit 1
endif

# Remove degenerate lat/lon dimensions and coordinate vars
ncwa -x -v grid_xt_sub01,grid_yt_sub01 -a grid_xt_sub01,grid_yt_sub01 $output $output.tmp
if ($status) then
    echo "ERROR: ncwa error"
    exit 1
endif
mv $output.tmp $output

# Make the "time" dimension the record dimension again
ncpdq -a time,site $output $output.tmp
if ($status) then
    echo "ERROR: ncpdq error"
    exit 1
endif
mv $output.tmp $output

# Modify attributes
# 1. Remove cell_measures, as point data doesn't need it
# 2. Correct cell_methods to "area: point time: point"
ncatted -a cell_measures,,d,, -a cell_methods,,o,c,"area: point time: point" $output $output.tmp
if ($status) then
    echo "ERROR: ncatted error"
    exit 1
endif
mv $output.tmp $refineDiagDir/$output

echo "Done"
exit 0
