#!/bin/bash
set -x -e
# this script assumes you have albmap_bedmap2_1km.nc in this directory

ncks -O -d x,-2800000.,3200000. -d y,-2800000.,3200000.  albmap_bedmap2_1km.nc albmap_bedmap2_1km_thwaites.nc
# convert precipitation from m/year to kg/m2/year
ncap2 -O -s "precipitation=precipitation*1e3;"  albmap_bedmap2_1km_thwaites.nc  albmap_bedmap2_1km_thwaites.nc
ncatted -a units,precipitation,o,c,"kg m-2 year-1" albmap_bedmap2_1km_thwaites.nc

# Create a mask with the Thwaites Glacier basin outline as GeoTiff
gdalwarp -overwrite  -s_srs EPSG:3031 -t_srs EPSG:3031 -cutline basins/thwaites.shp NETCDF:albmap_bedmap2_1km_thwaites.nc:mask thwaites.tif
# Convert to netCDF
gdal_translate -of netCDF thwaites.tif thwaites.nc
# Change variable name to ftt_mask
ncrename -v mask,ftt_mask thwaites.nc
ncap2 -s "ftt_mask*=0" -O thwaites.nc thwaites.nc
cdo setmisstoc,1 thwaites.nc thwaites-filled.nc
# Add mask to clean input file
ncks -A -v ftt_mask thwaites-filled.nc albmap_bedmap2_1km_thwaites.nc

# Now remove "missing" values
cdo setrtomiss,1e4,1e38 albmap_bedmap2_1km_thwaites.nc foo.nc
cdo setmisstoc,0 foo.nc albmap_bedmap2_1km_thwaites_clean.nc
# remove unused file
rm -rf foo.nc thwaites.nc
