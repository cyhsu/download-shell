#!/bin/bash
#- NDBC ADCP updates (real-time)
#- 
#-	This script attempts to archieve the information of the NDBC ADCP data
#- whether it is "activate" or "inactivate". 
#- 
#- please record the time after each run.
#- Time Performance:
#- 	1. 2018-01-20
#-		2. 2018-01-22
#-
#--- 
#---  Copyright: C.Y. Hsu@TAMU 2018-01-18
#--------------------------------------------------------------
wget -O index.html -q http://www.ndbc.noaa.gov/to_station.shtml
grep 'station_page.php?station=' index.html > index
awk 'BEGIN{FS="</a>"}{for(i=1;i<=NF;i++) print $i}' index |sed 's/.*">//'>station_id
Linfo='http://www.ndbc.noaa.gov/station_page.php?station='
Lreal='http://www.ndbc.noaa.gov/data/realtime2/'
L17_1='http://www.ndbc.noaa.gov/data/adcp/'
L17_2='http://www.ndbc.noaa.gov/data/adcp2/'
Lhis1='http://www.ndbc.noaa.gov/data/historical/adcp/'
Lhis2='http://www.ndbc.noaa.gov/data/historical/adcp2/'
CurYr=`date +%Y%m%d`
PreYr=`date -d '1 year ago' +%Y`
#---
#---   Default set up : remove the records
if [ -f "adcp_status.$CurYr" ]; then rm adcp_status.$CurYr; fi
touch adcp_status.$CurYr

echo '*- NDBC : ADCP status update' >> adcp_status.$CurYr
echo '*- Column 01 : Station id' >> adcp_status.$CurYr
echo '*- Column 02 : Longitude (degrees)' >> adcp_status.$CurYr
echo '*- Column 03 : Latitude (degrees)' >> adcp_status.$CurYr
echo '*- Column 04 : ADCP status' >> adcp_status.$CurYr
echo '*- Column 05 : Final updated date' >> adcp_status.$CurYr
echo '*- Column 06 : indicator - whether the station is in GCOOS Data Portal ' >> adcp_status.$CurYr
echo '*-' >> adcp_status.$CurYr
#echo '' >> adcp_status.$CurYr

nums=`wc -l station_id | tr ' ' '\n' |head -1`; num=1
while read sid 
do
	echo "$num >> $nums, station $sid"
	num=$((num+1))
	#---
	#---   Clear up the temporary files and variables
	if [ -f adcp_real ]; then rm adcp_real; fi
	if [ -f adcp_hist ]; then rm adcp_hist; fi
	if [ -f adcp_hist.gz ]; then rm adcp_hist.gz; fi
	if [ -f index.html ]; then rm index.html; fi
	lon='';lat='';stus='';tim=''

	if [ ! -z $sid ]; then 
		link=$Linfo$sid
		wget -q -O index.html -q $link
		#- 1st check : if the page existed "ADCP"
		if (grep -Fq "Ocean Current Data" index.html) || (grep -Fq "ADCP" index.html); then
			echo "        KEYWORD: : ADCP is found for this station ($sid)"
			stus='  active'
			lat=`grep "&#176;" index.html | sed 's/<b>//' | awk '{print $1}'`
			tmp=`grep "&#176;" index.html | sed 's/<b>//' | awk '{print $2}'`
			if [ "$tmp" == 'S' ]; then lat=`bc <<< $lat*-1.0`; fi
			lon=`grep "&#176;" index.html | sed 's/<b>//' | awk '{print $3}'`
			tmp=`grep "&#176;" index.html | sed 's/<b>//' | awk '{print $4}'`
			if [ "$tmp" == 'W' ]; then lon=`bc <<< $lon*-1.0`; fi
			#- 2nd check : if station are located in the Gulf of Mexico.
			if (( $(bc <<< "$lon <= - 78") && \
					$(bc <<< "$lon >= -100") && \
					$(bc <<< "$lat >=   18") && \
					$(bc <<< "$lat <=   31") )); then 
	
				echo "        Oops!!! This station is in the Gulf of Mexico Yeah!!!!!"
				#- 3rd check : if the page existed "Real Time Data" or "Ocean Current Data"
			#	if grep -Fq "Real Time Data" index.html; then 
				if grep -Fq "Ocean Current Data" index.html; then 
					if [[ $(wget $Lreal$sid".adcp" -O-) ]] 2>/dev/null; then
						wget -q -O adcp_real $Lreal$sid".adcp"
					elif [[ $(wget $Lreal$sid".adcp2" -O-) ]] 2>/dev/null; then
						wget -q -O adcp_real $Lreal$sid".adcp2"
					fi
					line_count=`wc -l adcp_real | tr ' ' '\n' |head -1`
					if (( $(bc <<< "$line_count > 2") )); then 
						tim=`awk 'NR==3' adcp_real | awk '{printf $1"-"$2"-"$3"T"$4}'`	
					else
						echo "Error: Station $sid" >> error.log
						echo "   script shows the station has the real time data," >> error.log
						echo "   real time data missing." >> error.log
						echo "  " >> error.log
					fi
				else
					stus='inactive'
					if [[ $(wget $Lreal$sid".adcp" -O-) ]] 2>/dev/null; then
						wget -q -O adcp_hist $Lreal$sid".adcp"
					elif [[ $(wget $Lreal$sid".adcp2" -O-) ]] 2>/dev/null; then
						wget -q -O adcp_hist $Lreal$sid".adcp2"
					else
						for (( yr=$PreYr; yr>=2010; yr--))
						do
							###- if (( $(bc <<< "$yr == 2017") )); then
							###- 	for mm in Dec Nov Oct Sep Aug Jul Jun May Apr Mar Feb Jan
							###- 	do
							###- 		if [[ $(wget $L17_1$mm$sid$yr".txt.gz"  -O-) ]] 2>/dev/null; then
							###- 			wget -q -O adcp_hist.gz $L17_1$mm$sid$yr".txt.gz"
							###- 			break
							###- 		elif [[ $(wget $L17_2$mm$sid$yr".txt.gz"  -O-) ]] 2>/dev/null; then
							###- 			wget -q -O adcp_hist.gz $L17_2$mm$sid$yr".txt.gz"
							###- 			break
							###- 		fi
							###- 	done
							###- else
								if [[ $(wget $Lhis1$sid"a"$yr".txt.gz"  -O-) ]] 2>/dev/null; then
									wget -q -O adcp_hist.gz $Lhis1$sid"a"$yr".txt.gz"
									break
								elif [[ $(wget $Lhis2$sid"b"$yr".txt.gz"  -O-) ]] 2>/dev/null; then
									wget -q -O adcp_hist.gz $Lhis2$sid"b"$yr".txt.gz"
									break
								fi
							###- fi
						done
							gunzip adcp_hist.gz
					fi
					if [ -f adcp_hist ]; then 
						tim=`tail -n 1 adcp_hist | awk '{printf $1"-"$2"-"$3"T"$4}'`	
					else
						echo 'Raise Error : adcp_hist is not found.'
						tim='Need additional care'
					fi
				fi
				echo "$sid $lon $lat $stus $tim" >> adcp_status.$CurYr
				echo "        $sid $lon $lat $stus $tim "
			fi
		else
			echo "        KEYWORD: : ADCP is not found for this station ($sid) "
		fi
	fi
	echo " "
done < station_id
if [ -f adcp_real ]; then rm adcp_real; fi
if [ -f adcp_hist ]; then rm adcp_hist; fi
if [ -f adcp_hist.gz ]; then rm adcp_hist.gz; fi
if [ -f index.html ]; then rm index.html; fi


while read previous
do
	if grep -Fq "In" adcp_status.2018 ; then 
	#if grep -Fq "In" adcp_status.$PreYr ; then 
		sid=`awk '{printf $1}' $previous`
		tmp=`grep "$sid" adcp_status.$CurYr`
		ntmp=$tmp" In"
		sed -i "s/$tmp/$ntmp/" adcp_status.$CurYr
	fi
done < adcp_status.2018
#done < adcp_status.$PreYr
