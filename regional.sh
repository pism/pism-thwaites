#!/bin/bash

set -e                          # stop on error
set -u                          # stop if a variable is not set
set -x                          # print commands before running them

N=4

input_file=albmap_bedmap2_1km_thwaites_clean.nc

mpiexec -n $N pismr \
        -i ${input_file} \
        -bootstrap \
        -regional  \
        -regional.zero_gradient \
        -no_model_strip 3 \
        -x_range -1669041.,-1007348. \
        -y_range -839369.,-179882 \
        -calving thickness_calving \
        -calving.thickness_calving.threshold 50 \
        -y 10 \
        -skip -skip_max 5 \
        -regrid_file run_30km.nc \
        -atmosphere given \
        -atmosphere_given_file ${input_file} \
        -surface simple,forcing \
        -force_to_thickness_file ${input_file} \
        -o thwaites_regional_smoothing.nc \
        -extra_vars diffusivity,thk,taud_mag,velbase_mag,velbar_mag,h_x,h_y \
        -extra_file ex_thwaites_regional.nc \
        -extra_times 1
