#!/bin/csh 
#----------------------------------
#PBS -l size=1
#PBS -l walltime=01:00:00
#PBS -r y
#PBS -j oe


#####################################################################
# Script to postprocess zg (AERmon) variable
# If present on half levels, average to regrid to full levels
set echo
# set fremodule
if ($?fremodule) then
   source $MODULESHOME/init/csh
   module use -a /home/fms/local/modulefiles
   module load $fremodule
endif

# make sure fre is loaded
if (`echo '$M="fre";@M=grep/^$M\/.*/,split/:/,$ENV{"LOADEDMODULES"};if($M[0]=~/^$M\/(.*)$/){print $1}'|perl` == "") then
   echo "ERROR: FRE not loaded"
   exit 1
endif

module load ncarg/6.2.1
module load gcp

set argv = (`getopt i:o:y: $*`)
 
while ("$argv[1]" != "--")
    switch ($argv[1])
        case -i:
            set in_dir = $argv[2]; shift argv; breaksw 
        case -o:
            set out_dir = $argv[2]; shift argv; breaksw
        case -y:
            set years = $argv[2]; shift argv; breaksw
    endsw
    shift argv
end
shift argv

# argument error checking

if (! $?in_dir) then
   echo "ERROR: no argument given for input directory."
   set help
endif

if (! $?out_dir) then
   echo "ERROR: no argument given for output directory."
   set help
endif

if ($?help) then
   echo
   echo "USAGE:  $0:t -i idir -o odir -p pdir -d desc -y yrs files...."
   echo
   exit 1
endif

if ($?years) then
   set yrs = `echo $years | sed -e "s/,/ /"`
   if ($#yrs != 2) then
      echo "ERROR: invalid entry for years."
      exit 1
   endif
endif


#####################################################################
set echo 

# make sure temp directory is defined
if ($?FTMPDIR) then
   set workdir = $FTMPDIR/pp_zg/$in_dir
   if (! -e $workdir) then
      mkdir -p $workdir
   endif
   cd $workdir
else
   echo 'ERROR: $FTMPDIR not defined - you may be on the incorrect platform'
   exit 1
endif

set var = zg

set infile = $in_dir/aerosol_cmip.$yrs[1]01-$yrs[2]12.$var.nc
if (-e $infile) then
   dmget $infile
   gcp $infile $workdir/
else
   echo File $infile not found, skipping
endif 
set staticfile = $in_dir/../../../aerosol_cmip.static.nc
gcp $staticfile $workdir/

set go_ncl = `which ncl`
set qq = '"'

ncdump -h $workdir/$infile:t | grep "${var}(" | grep lev,
if ($? == 0) then
   echo "${var} is already on full model levels, skipping regridding"
   exit
endif 
    
echo "Regrid ${var} from half levels to full levels"
#rename original file to ${var}_half
mv $infile ${infile:r}_half.nc
mv $workdir/$infile:t $workdir/${infile:t:r}_half.nc

# Run script to process zg
cat << EOF > gofile.ncl

begin

exptime       = $qq$yrs[1]01-$yrs[2]12$qq
work_dir      = $qq$workdir$qq

   varname = ${qq}zg$qq
   
   filename_in     = work_dir+$qq/aerosol_cmip.$qq+exptime+$qq.$qq+varname+${qq}_half.nc$qq
   filename_static = work_dir+$qq/aerosol_cmip.static.nc$qq
   filename_out    = work_dir+$qq/aerosol_cmip.$qq+exptime+$qq.$qq+varname+$qq.nc$qq
   fin = addfile(filename_in,${qq}r${qq})
   fstatic = addfile(filename_static,${qq}r${qq})
   lat = fin->lat
   nlat = dimsizes(lat)
   lat_bnds = fin->lat_bnds
   lon = fin->lon
   nlon = dimsizes(lon)
   lon_bnds = fin->lon_bnds
   lev = fin->lev
   nlev = dimsizes(lev)
   levhalf = fin->levhalf
   ap = fstatic->ap
   ap_bnds = fstatic->ap_bnds
   b  = fstatic->b
   b_bnds  = fstatic->b_bnds
   lev_bnds = fstatic->lev_bnds
   bnds = fstatic->bnds
   time = fin->time
   time_bnds = fin->time_bnds
   average_T1 = fin->average_T1
   average_T2 = fin->average_T2
   average_DT = fin->average_DT

   ap_bnds!1 = "bnds"
   ap_bnds&bnds = bnds
   b_bnds!1 = "bnds"
   b_bnds&bnds = bnds
   lat_bnds!1 = "bnds"
   lat_bnds&bnds = bnds
   lev_bnds!1 = "bnds"
   lev_bnds&bnds = bnds
   lon_bnds!1 = "bnds"
   lon_bnds&bnds = bnds
   time_bnds!1 = "bnds"
   time_bnds&bnds = bnds

   xvar_half = fin->\$varname\$
   xvar = 0.5*(xvar_half(time|:,levhalf|0:(nlev-1),lat|:,lon|:)+xvar_half(time|:,levhalf|1:nlev,lat|:,lon|:))
;  xvar = linint1_n(log(levhalf),xvar_half,False,log(lev),0,1)
   xvar!0 = "time"
   xvar!1 = "lev"
   xvar!2 = "lat"
   xvar!3 = "lon"
   xvar&time = time
   xvar&lev  = lev
   xvar&lat  = lat
   xvar&lon  = lon
   copy_VarAtts(xvar_half,xvar)
   xvar@comment = "vertically averaged from half levels"
;  xvar@comment = "interpolated from half levels, using log(lev)"

   system(${qq}rm -f $qq+filename_out)
   fout = addfile(filename_out,${qq}c$qq)

; Define dimensions
   dimNames = (/ ${qq}lon$qq, ${qq}lat$qq, ${qq}lev$qq,${qq}bnds$qq,${qq}time$qq /)
   dimSizes = (/ nlon,  nlat,  nlev, 2, -1 /)
   dimUnlim = (/ False, False, False, False, True/)
   filedimdef( fout, dimNames, dimSizes, dimUnlim )

   fout->ap = ap
   fout->ap_bnds = ap_bnds
   fout->b = b
   fout->b_bnds = b_bnds
   fout->lat = lat
   fout->lat_bnds = lat_bnds
   fout->lev = lev
   fout->lev_bnds = lev_bnds
   fout->lon = lon
   fout->lon_bnds = lon_bnds
   fout->time = time  
   fout->time_bnds = time_bnds
   fout->average_T1 = average_T1
   fout->average_T2 = average_T2
   fout->average_DT = average_DT
   fout->\$varname\$ = xvar

end
EOF

date
$go_ncl gofile.ncl
date

# output directory
set out_data_dir = $in_dir
if (! -e $out_data_dir ) then
   mkdir -p $out_data_dir
endif

# move files to the output directory
if (-e $workdir/aerosol_cmip.$yrs[1]01-$yrs[2]12.$var.nc) then
   gcp $workdir/aerosol_cmip.$yrs[1]01-$yrs[2]12.$var.nc $out_data_dir
else
   echo "ERROR: file not found in $workdir"
#  exit 1
endif 

