#!/bin/bash

# Copyright (C) 2009-2015, 2017  PISM authors
##################################################################################
# Coarse grid spinup of Antarctic ice sheet model using data from Anne Le Brocq
# (see SeaRISE wiki).  Uses PIK physics and enthalpy model
# and modified configuration parameters with constant climate.  Uses constant
# and precip and a parameterization for artm as in Martin et al (2011).
# WARNING: at finer resolutions (e.g. under 15 km), output is large!
##################################################################################

SCRIPTNAME="#(antspin-coarse.sh)"

echo "$SCRIPTNAME   run preprocess.sh before this..."
# needed inputs generated by preprocess.sh: pism_Antarctica_5km.nc

set -e  # exit on error

echo "$SCRIPTNAME   Coarse grid, constant-climate spinup script using SeaRISE-Antarctica data"
echo "$SCRIPTNAME      and -stress_balance ssa+sia and -pik"
echo "$SCRIPTNAME   Run as './antspinCC.sh NN' for NN procs and 30km grid"

# naming files, directories, executables
RESDIR=
BOOTDIR=
PISM_EXEC=pismr
PISM_MPIDO="mpiexec -n "

# input data:
export PISM_INDATANAME=${BOOTDIR}albmap_bedmap2_1km_thwaites_clean.nc

source set-physics.sh

NN=4  # default number of processors
if [ $# -gt 0 ] ; then  # if user says "antspinCC.sh 8" then NN = 8
  NN="$1"
fi
echo "$SCRIPTNAME              NN = $NN"
set -e  # exit on error

# check if env var PISM_DO was set (i.e. PISM_DO=echo for a 'dry' run)
if [ -n "${PISM_DO:+1}" ] ; then  # check if env var is already set
  echo "$SCRIPTNAME         PISM_DO = $PISM_DO  (already set)"
else
  PISM_DO=""
fi
DO=$PISM_DO

# these coarse grid defaults are for development/regression runs, not
# "production" or science
GRID=$THIRTYKMGRID
SKIP=$SKIPTHIRTYKM
GRIDNAME=30km

echo "$SCRIPTNAME             PISM = $PISM_EXEC"
echo "$SCRIPTNAME         FULLPHYS = $FULLPHYS"
echo "$SCRIPTNAME          PIKPHYS = $PIKPHYS"
echo "$SCRIPTNAME PIKPHYS_COUPLING = $PIKPHYS_COUPLING"


# #######################################
# bootstrap and SHORT smoothing run to 100 years
# #######################################
stage=earlyone
INNAME=$PISM_INDATANAME
RESNAMEONE=${RESDIR}${stage}_${GRIDNAME}.nc
RUNTIME=1
echo
echo "$SCRIPTNAME  bootstrapping on $GRIDNAME grid plus SIA run for $RUNTIME a"
cmd="$PISM_MPIDO $NN $PISM_EXEC -skip -skip_max $SKIP -i ${INNAME} -bootstrap $GRID \
	$SIA_ENHANCEMENT $PIKPHYS_COUPLING -calving ocean_kill -ocean_kill_file ${INNAME} \
	-y $RUNTIME -o $RESNAMEONE"
$DO $cmd
#exit # <-- uncomment to stop here

stage=smoothing
RESNAME=${RESDIR}${stage}_${GRIDNAME}.nc
RUNTIME=100
echo
echo "$SCRIPTNAME  short SIA run for $RUNTIME a"
cmd="$PISM_MPIDO $NN $PISM_EXEC -skip -skip_max $SKIP -i $RESNAMEONE \
	$SIA_ENHANCEMENT $PIKPHYS_COUPLING -calving ocean_kill -ocean_kill_file $RESNAMEONE \
	-y $RUNTIME -o $RESNAME"
$DO $cmd

# #######################################
# run with -no_mass (no surface change) on coarse grid for 100ka
# #######################################
stage=nomass
INNAME=$RESNAME
RESNAME=${RESDIR}${stage}_${GRIDNAME}.nc
TSNAME=${RESDIR}ts_${stage}_${GRIDNAME}.nc
RUNTIME=100000
EXTRANAME=${RESDIR}extra_${stage}_${GRIDNAME}.nc
expackage="-extra_times 0:1000:$RUNTIME -extra_vars bmelt,tillwat,velsurf_mag,temppabase,diffusivity,hardav"
echo
echo "$SCRIPTNAME  -no_mass (no surface change) SIA for $RUNTIME a"
cmd="$PISM_MPIDO $NN $PISM_EXEC -i $INNAME $PIKPHYS_COUPLING  \
    $SIA_ENHANCEMENT -no_mass \
    -ys 0 -y $RUNTIME \
    -extra_file $EXTRANAME $expackage \
    -o $RESNAME"
$DO $cmd
#exit # <-- uncomment to stop here


# #######################################
# run into steady state with constant climate forcing
# #######################################
stage=run
INNAME=$RESNAME
RESNAME=${RESDIR}${stage}_${GRIDNAME}.nc
TSNAME=${RESDIR}ts_${stage}_${GRIDNAME}.nc
RUNTIME=25000
EXTRANAME=${RESDIR}extra_${stage}_${GRIDNAME}.nc
exvars="thk,usurf,velbase_mag,velbar_mag,mask,diffusivity,tauc,bmelt,tillwat,temppabase,hardav,cell_grounded_fraction,ice_area_specific_volume,amount_fluxes,basal_mass_flux_grounded,basal_mass_flux_floating"
expackage="-extra_times 0:1000:$RUNTIME -extra_vars $exvars"

echo
echo "$SCRIPTNAME  run into steady state with constant climate forcing for $RUNTIME a"
cmd="$PISM_MPIDO $NN $PISM_EXEC -skip -skip_max $SKIP -i $INNAME \
    $SIA_ENHANCEMENT $PIKPHYS_COUPLING $PIKPHYS $FULLPHYS \
    -ys 0 -y $RUNTIME \
    -ts_file $TSNAME -ts_times 0:1:$RUNTIME \
    -extra_file $EXTRANAME $expackage \
    -o $RESNAME -o_size big"
$DO $cmd

echo
echo "$SCRIPTNAME  coarse-grid part of spinup done"

