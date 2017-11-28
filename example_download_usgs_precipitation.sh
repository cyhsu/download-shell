#!/bin/bash
#- 
#- Target : Download USGS precipitation data within TX
#- 	
#-		Period : 2017-08-20 to 2017-09-05
#-----------------------------------------------------------
#-
#-	2017-09-06
#-	@C.Y. Hsu at TAMU (revised : 2017-11-08)
#-----------------------------------------------------------
date_start='2017-08-20'
date_end='2017-09-05'

#----  obtain the TX USGS stations  ----
slink='https://waterdata.usgs.gov/tx/nwis/current/?type=precip'
wget -O sinfo $slink
grep "00045" sinfo| sed -s 's/.*site_no=//'| sed -s 's/\&amp.*//'|head -n -1 > sites

while read site_no  #-- read-in USGS site and save into variable "site_no"
do
	output_file=site_"$site_no"
	#- Create a file header for each station
	download_link=https://waterdata.usgs.gov/nwis/inventory/?site_no=$site_no
	wget -O index --quiet $download_link
	
	site_info=`grep "<title>" index |sed -s "s/<title>//g" |sed -s "s/<.*$//"`
	lat=`grep Latitude index |awk '{print $2}'` 
	lat_d=`echo $lat| awk -F "&#176;" '{print $1}'`
	lat_m=`echo $lat| awk -F "&#176;" '{print $2}'| sed -s "s/'.*//g"`
	lat_s=`echo $lat| awk -F "&#176;" '{print $2}'| sed -s "s/.*'//g"| sed 's/".//'`
	lat=`awk '{print $1+$2/60+$3/3600}' <<< "$lat_d $lat_m $lat_s"`
	
	lon=`grep Latitude index |awk '{print $5}'` 
	lon_d=`echo $lon| awk -F "&#176;" '{print $1}'`
	lon_m=`echo $lon| awk -F "&#176;" '{print $2}'| sed -s "s/'.*//g"`
	lon_s=`echo $lon| awk -F "&#176;" '{print $2}'| sed -s "s/.*'//g"| sed 's/".//'`
	lon=`awk '{print -1*($1+$2/60+$3/3600)}' <<< "$lon_d $lon_m $lon_s"`
	echo "#- site: $site_info" > $output_file
	echo "#- Latitude $lat" >> $output_file
	echo "#- Longitude $lon" >> $output_file
	echo "#-----------------------------------" >> $output_file

	#- retrieve data for each station
	data_head='https://waterdata.usgs.gov/tx/nwis/uv?cb_00045=on&format=rdb&'
	#data_time="period=&begin_date=$begin_date&end_date=$end_date"
	data_time="period=&begin_date=$date_start&end_date=$date_end"
	data_link="$data_head"site_no="$site_no"'&'"$data_time"
	wget -O data --quiet $data_link
	tail -n +19 data | sed -s 's/#/#- /g' | sed -s 's/agency/#- agency/' |sed -s 's/5s.*/#-/g' >> $output_file
	rm index data
done < sites
