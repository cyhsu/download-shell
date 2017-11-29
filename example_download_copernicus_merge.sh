#!/bin/bash
#-	Followed by example_download_copernicus.sh
#-	Conbining all of the downloading copernicus data to a single file.
#-	
#-		USAGE:
#-				./example_download_copernicus_merge.sh year
#-  
#-    NOTICE:
#-        - the downloaded netcdf files are moving to a new directory "year"
#-        - output file is named by "year"_merge.nc
#-
#-		REQUIREMENT : nco
#-
#--- @C.Y. Hsu (Texas A&M Univ., 2017-09-20)
#--- 2017-11-29, modified to an example for copernicus user.
#===========================================================================

#- SET UP YOUR NCO !!!!
#- if your nco is installed in /usr/bin, you can commend out the lines.
#- example : load nco from ada.tamu.edu
module purge
module load NCO/4.6.0-intel-2016b-Python-2.7.12

#- MAIN PROGRAM
year=$1
list=`ls $year*nc`
while read file
do
  if [ ! -d "$year" ]; then mkdir "$year"; fi
	nfile=`echo $file | sed -s 's/.nc/_um.nc/'`
	ncks --mk_rec_dmn time  $file $nfile
  mv $file ./"$year"/.
done <<< "$list"
ncrcat -O -h *um.nc "$year"_merge.nc
rm *um.nc
