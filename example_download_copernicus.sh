#!/bin/bash
#-   Downloading the Marine Copernicus analysis and forecast data example 
#-       - horizontal resolution : 0.083 x 0.083
#-       - temporal resolution : daily-mean
#-       - vertical resolution : 75 layers
#-       - from today to 9 days after
#-
#-		USAGE:
#-			
#-			$> ./example_download_copernicus.sh "time_begins" "time_ends"
#-				example:
#-						./example_download_copernicus.sh "2017-08-23" "2017-08-30"
#-				notice:
#-						- time format: "2017-08-23"
#-						- time format "yyyy-mm-dd HH:MM:SS" is aceptable,
#-						  but please keep the quotation marks
#---
#--- @C.Y. Hsu (Texas A&M Univ., 2017-09-20)
#--- 2017-11-28, modified to an example for copernicus user.
#===================================================================

#--  B4 INITIAL THE CODE  --
##--  PARAMETERS  --
DEFU_DIR=`pwd`                #-- Current Directory
username={your_user_name}     #-- Copernicus username
password={your_user_passwd}   #-- Copernicus password
##--  ENVIRONMENTAL SET UP : Load your python code  --
##--  EXAMPLE FOR ada.tamu.edu
module purge
module load intel/2015a netCDF-Fortran/4.4.0-intel-2015a Anaconda/2-4.0.0 

##--  PARAMETER SET UP : ..DOWNLOAD PROCESS.. --
motu_dir={the_path_of_copernicus_python_toolbox_you_installed} 
motu_py=$motu_dir"motu-client.py"
http_m='http://nrtcmems.mercator-ocean.fr/motu-web/Motu'    #-- depends on the interested product
http_s='GLOBAL_ANALYSIS_FORECAST_PHY_001_024-TDS'           #-- depends on the interested product
http_d='global-analysis-forecast-phy-001-024'               #-- depends on the interested product
leftlow_corner_lon=-101        #-- interested domain size, {min_lat}
leftlow_corner_lat=10          #-- interested domain size, {min_lat}
rightup_corner_lon=-75         #-- interested domain size, {max_lon}
rightup_corner_lat=35          #-- interested domain size, {max_lat}
z0=0.494                       #-- interested domain size, {top_z_layer}
z1=5727.9171                   #-- interested domain size, {bottom_z_layer}
var1='thetao'                  #-- download variable 01, sea surface height {varied by products} 
odir=$DEFU_DIR                 #-- the destination path of downloaded file

##--  TIME SET UP  --
tstart=$1                      #-- file begins on time : tstart
tend=$2                        #-- file ends on time : tend
total_days=$(( (`date -d "$tend" +%s` - `date -d "$tstart" +%s`)/86400 ))
total_loops=$((total_days/15))
if [ $((total_loops%15)) -ne 0 ]; then ((total_loops++)); fi
count=1
days=0
t0=$tstart

usr_info="-u $username -p $password"
svr_info="-m $http_m -s $http_s -d $http_d" 
dom_info="-x $leftlow_corner_lon -X $rightup_corner_lon"
dom_info="$dom_info -y $leftlow_corner_lat -Y $rightup_corner_lat"
dom_info="$dom_info -z $z0 -Z $z1"
var_info="-v $var1"
loc_info="-o $odir -f $ofile"

echo " "
echo " "
echo "The donwload process is divided into $total_loops subprocesses"
while [ $days -lt $total_days ]
do  
	t1=`date -d "$t0 15 days" +"%F %H:%M:%S"`
	days=$(( (`date -d "$t1" +%s` - `date -d "$tstart" +%s`)/86400 ))
	ofile=`echo $t0"_"$t1".nc"| sed -s 's/ ..:00:00//g'| sed -s 's/-//g'`
	echo "...     subprocess : $count/$total_loops "
	echo "...     time begins: $t0"
	echo "...     time ends  : $t1"
	echo "...     days       : $days"
	echo "  "
	(( count++ ))
	##-- DOWNLOAD : ..Copernicus analysis/forecast data.. --
	python $motu_py -q $usr_info $svr_info $dom_info -t $t0 -T $t1 $var_info -o $odir -f $ofile
	t0=$t1
	if [ $((total_days - days)) -lt 15 ]; then
		t1=$tend
		days=$(( (`date -d "$t1" +%s` - `date -d "$tstart" +%s`)/86400 ))
		ofile=`echo $t0"_"$t1".nc"| sed -s 's/ ..:00:00//g'| sed -s 's/-//g'`
		echo "...     subprocess : $count/$total_loops "
		echo "...     time begins: $t0"
		echo "...     time ends  : $t1"
		echo "...     days       : $days"
		echo "  "
		##-- DOWNLOAD : ..Copernicus analysis/forecast data.. --
		python $motu_py -q $usr_info $svr_info $dom_info -t $t0 -T $t1 $var_info -o $odir -f $ofile
	fi
	sleep 1
done
