#!/bin/bash
set -x -e
# this script assumes you have albmap_bedmap2_1km.nc in this directory

nccopy -d 5 albmap_bedmap2_1km.nc albmap_bedmap2_1km_thwaites.nc
# Create a mask with the Thwaites Glacier basin outline as GeoTiff
gdalwarp -overwrite  -s_srs EPSG:3031 -t_srs EPSG:3031 -cutline basins/thwaites.shp NETCDF:albmap_bedmap2_1km.nc:mask thwaites.tif
# Convert to netCDF
gdal_translate -of netCDF thwaites.tif thwaites.nc
# Change variable name to fft_mask
ncrename -v mask,fft_mask thwaites.nc
# Add mask to clean input file
ncks -A -v fft_mask thwaites.nc albmap_bedmap2_1km_thwaites.nc

# Now remove "missing" values
cdo setrtomiss,1e4,1e38 albmap_bedmap2_1km_thwaites.nc foo.nc
cdo -f nc4 -z zip_5 setmisstoc,0 foo.nc albmap_bedmap2_1km_thwaites_clean.nc
# remove unused file
rm -rf foo.nc
# convert precipitation from m/year to kg/m2/year
ncap2 -O -s "precipitation=precipitation*1e3;"  albmap_bedmap2_1km_thwaites_clean.nc  albmap_bedmap2_1km_thwaites_clean.nc
ncatted -a units,precipitation,o,c,"kg m-2 year-1" albmap_bedmap2_1km_thwaites_clean.nc
