#!/bin/csh
#
# Authors:
#     Diagnostic script: Sergey Malyshev
#     Wrapper: Erik Mason
#
# Description:
# This script takes input from a CMIP experiment and remaps
# the GFDL land uses to those that correspond to the  CMIP
# land use tiles, as described by LUMIP
#
# For more information, please see:
# D. M. Lawrence, G. C. Hurtt, A. Arneth, V. Brovkin, K. V. Calvin, A. D. Jones, C. D. Jones,
#    P. J. Lawrence, N. de Noblet-Ducoudré, J. Pongratz, S. I. Seneviratne, and E. Shevliakova (2016):
#    The Land Use Model Intercomparison Project (LUMIP) contribution to CMIP6: rationale and experimental design.
#    Geoscientific Model Development, 9, No.9, 2973–2998, doi:10.5194/gmd-9-2973-2016.
#
#
# Required frepp variables:
# oname :: Start date of run
# refineDiagDir :: Directory that will contain the ensemble average
#
#
# -----------------------------------------------------------

#set python_version = `python -c "import sys; print sys.version.split()[0]"`
module unload python
module load python/2.7.12
echo `which python`

set diagnostic_script = "$rtsxml:h/awg_include/refineDiag/land_refine_scripts/combine-lumip-vars.py"
if ( ! -f ${diagnostic_script} ) then
    echo 'Error: The requested diagnostic script "$diagnostic_script" does not appear to exist.'
    exit 1
endif

set diagnostic_script_1 = "$rtsxml:h/awg_include/refineDiag/land_refine_scripts/calculate-fracLut.py"
if ( ! -f ${diagnostic_script_1} ) then
    echo 'Error: The requested diagnostic script "$diagnostic_script_1" does not appear to exist.'
    exit 1
endif

set diagnostic_script_2 = "$rtsxml:h/awg_include/refineDiag/land_refine_scripts/filter-lumip-by-area.py"
if ( ! -f ${diagnostic_script_2} ) then
    echo 'Error: The requested diagnostic script "$diagnostic_script_2" does not appear to exist.'
    exit 1
endif

if ( ! -d ${refineDiagDir} ) then
    echo "Error: refineDiagDir does not exist."
    exit 1
endif

set sample_psl_file = `echo ./*.lumip_Lmon_crp.*.nc | cut -d ' ' -f 1 `
if ( ! -f ${sample_psl_file} ) then
    echo "Error: No psl files were found for the diagnostic output."
    exit 1
endif

set tiled = `perl -e "'${sample_psl_file}' =~ /tile\d\.nc/ ? print '1' : print '0'"`

if ( ${tiled} ) then
    foreach tile ( 1 2 3 4 5 6 )
    # combine land use types along landuse dimension
    # Make sure that the input files are specified in the correct order ( psl pst crp )
    python ${diagnostic_script} -v -o ${refineDiagDir}/${oname}.lumip_refined_tmp.tile${tile}.nc \
        ${oname}.lumip_Lmon_psl.tile${tile}.nc \
        ${oname}.lumip_Lmon_pst.tile${tile}.nc \
        ${oname}.lumip_Lmon_crp.tile${tile}.nc
    # calculate fracLut
    python ${diagnostic_script_1} -v --cell-area-file ${oname}.land_static_sg.tile${tile}.nc \
        ${refineDiagDir}/${oname}.lumip_refined_tmp.tile${tile}.nc
    # filter out points with zero or missing areas
    python ${diagnostic_script_2} -v --tolerance 1.0 \
        ${refineDiagDir}/${oname}.lumip_refined_tmp.tile${tile}.nc \
        ${refineDiagDir}/${oname}.lumip_refined.tile${tile}.nc
    # remove temporary file
    rm ${refineDiagDir}/${oname}.lumip_refined_tmp.tile${tile}.nc
    end
else
    # combine land use types along landuse dimension
    # Make sure that the input files are specified in the correct order ( psl pst crp )
    python ${diagnostic_script} -v -o ${refineDiagDir}/${oname}.lumip_refined_tmp.nc \
        ${oname}.lumip_Lmon_psl.nc \
        ${oname}.lumip_Lmon_pst.nc \
        ${oname}.lumip_Lmon_crp.nc
    # calculate fracLut
    python ${diagnostic_script_1} -v --cell-area-file ${oname}.land_static_sg.nc \
        ${refineDiagDir}/${oname}.lumip_refined_tmp.nc
    # filter out points with zero or missing areas
    python ${diagnostic_script_2} -v --tolerance 1.0 \
        ${refineDiagDir}/${oname}.lumip_refined_tmp.nc \
        ${refineDiagDir}/${oname}.lumip_refined.nc
    # remove temporary file
    ${refineDiagDir}/${oname}.lumip_refined_tmp.nc
endif

echo "--------- Diagnostic Script complete ---------"
exit 0

