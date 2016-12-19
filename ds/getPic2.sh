#!/bin/bash

#LICENSE: https://github.com/jasmeu/wall_cgi-bin/blob/master/LICENSE
#Before using this script, consider: https://github.com/jasmeu/wall_cgi-bin/blob/master/README.md

#1. you create the list with the paths to all your photos by calling: 
#find "path/to/search/ie/the/root/folder/for/your/pics" -type f -iname "*.jpg" > list.txt
#2. in the call head -n $lineNumber ..., you adjust the path to list.txt to correspond to the path relevant for you. Best: use the absolute path.
#3. you get the number below (i.e. the one instead 10000) by calling 
#wc -l list.txt
#4. you put the script in a folder called cgi-bin
#5. you make the script executable: chmod a+x getPic2.sh
#6. Read the preparation steps which are needed to make this work under: http://www.jasm.eu/2016/12/19/photo-wall-with-wood-frames/
#7. and then you may call the script on: http://<synology_name>/cgi-bin/getPic2.sh?950:123

function log {
    #echo "$1" >> /tmp/getPic2_log.txt
    a="a"
} 

if [ -f /tmp/getPic2_log.txt ] ; then 
	rm /tmp/getPic2_log.txt
	touch /tmp/getPic2_log.txt
fi

countPicz=10000-3

lineNumber=$(( ((RANDOM<<15)|RANDOM) % $countPicz + 1 ))

fileName=`head -n $lineNumber ./list.txt | tail -1`


maxHeight=${QUERY_STRING%:*}
log "Desired Height: "$maxHeight
#maxHeight=461

fwidths=(1950 2945 1714 1920 1955)
fheigths=(1439 2221 1475 1357 1400)
fxs=(72 259 170 150 163)
fys=(70 270 170 149 163)
pws=(1808 2424 1370 1623 1619)
phs=(1308 1703 1125 1061 1072)

echo "Cache-Control: no-cache, no-store, must-revalidate";
echo "Pragma: no-cache";
echo "Expires: 0";
#echo "Content-type: text/plain"
echo "Content-type: image/jpg"
echo ""

variant=$(( RANDOM % 5 + 1 ))

#variant=4

if [ $variant -eq 1 ] ; then
	#No frame around
	convert -size x$maxHeight "$fileName" -auto-orient -sample x$maxHeight -strip /tmp/$lineNumber.jpg
fi

if [ $variant -eq 2 ] ; then
	#coloured frame
	r=$(( RANDOM % 256 ))
	g=$(( RANDOM % 256 ))
	b=$(( RANDOM % 256 ))
	convert -size x$maxHeight "$fileName" -auto-orient -sample x$maxHeight -strip -mattecolor "rgb($r,$g,$b)" -frame 10x10+5+5  /tmp/$lineNumber.jpg
fi

if [ $variant -eq 3 ] ; then
	#coloured frame + white space
	r=$(( RANDOM % 256 ))
	g=$(( RANDOM % 256 ))
	b=$(( RANDOM % 256 ))
    border=$(( RANDOM % 15 + 10 ))
    h=$maxHeight-$border-$border
	convert -size x$maxHeight "$fileName" -auto-orient -sample x$h -strip -mattecolor "#dddddd" -frame 3x3+0+0  /tmp/"$lineNumber"_1.jpg
	convert /tmp/"$lineNumber"_1.jpg -bordercolor "#f0f0ff" -border $borderx$border -mattecolor "rgb($r,$g,$b)" -frame 10x10+4+4 /tmp/$lineNumber.jpg
	rm /tmp/"$lineNumber"_1.jpg
fi

if [ $variant -eq 4 ] || [ $variant -eq 5 ] ; then

	frIdx=$(( RANDOM % 5 ))

	fw=${fwidths[$frIdx]}
	fh=${fheigths[$frIdx]}
	fx=${fxs[$frIdx]}
	fy=${fys[$frIdx]}
	pw=${pws[$frIdx]}
	ph=${phs[$frIdx]}

	log "fw:"$fw"_fh:"$fh"_fx:"$fx"_fy:"$fy"_pw:"$pw"_ph:"$ph

	orientation=`exiv2 -g Exif.Image.Orientation -Pv "$fileName"`
	if [ "a""$orientation""b" == "ab" ];then
   		orientation=1
	fi
	sizeStr=`exiv2 pr "$fileName" | grep "Image size"`
	sizeStr2=${sizeStr#*: }
	log "$sizeStr2"
	w=${sizeStr2% x*}
	h=${sizeStr2#*x }
	
	log "Photo size: "$w"_"$h"_"$orientation

	rf=`awk "BEGIN {print $pw/$ph}"`
	rp=`awk "BEGIN {print $w/$h}"`

	log "Ratio frame: "$rf" Ration Photo: "$rp
	
	nfh=$fh
	nfw=$fw
	nph=$ph
	npw=$pw
	nfx=$fx
	nfy=$fy

	compare=`expr $rp '>' $rf`

	if [ $compare -eq 1 ] ; then
		log "Branch 1"
		nph=`awk "BEGIN {print $pw/$rp}"`
		dh=`awk "BEGIN {print $nph/$ph}"`
		log "dh: "$dh
		nfh=`awk "BEGIN {print $fh*$dh}"`
		nfy=`awk "BEGIN {print $fy*$dh}"`
	else
		log "Branch 2"
		npw=`awk "BEGIN {print $ph*$rp}"`
		dw=`awk "BEGIN {print $npw/$pw}"`
		log "dw: "$dw
		nfw=`awk "BEGIN {print $fw*$dw}"`
		nfx=`awk "BEGIN {print $fx*$dw}"`
	fi

	log "fw:"$nfw"_fh:"$nfh"_fx:"$nfx"_fy:"$nfy"_pw:"$npw"_ph:"$nph

	log "File Name: ""$fileName"	

	compare=`awk "BEGIN{print $nfh>=$maxHeight}"`
	
	log "Is "$nfh" > "$maxHeight" : "$compare
	
	if [ $compare -eq 1 ] ; then #if we can still resize down the frame
		rr=`awk "BEGIN {print $maxHeight/$nfh}"`
		log "Resize Ratio: "$rr
		nfh=$maxHeight
		myval=`awk "BEGIN {print $nfw*$rr}"`
		nfw=$myval
		nph=`awk "BEGIN {print $nph*$rr}"`
		npw=`awk "BEGIN {print $npw*$rr}"`
		nfx=`awk "BEGIN {print $nfx*$rr}"`
		nfy=`awk "BEGIN {print $nfy*$rr}"`

		log "fw:"$nfw"_fh:"$nfh"_fx:"$nfx"_fy:"$nfy"_pw:"$npw"_ph:"$nph
		
		convert ./frames/"$frIdx".jpg -sample "$nfw"x"$nfh"! -strip /tmp/"$lineNumber"_1.jpg
		
		if [ $variant -eq 4 ] ; then #full picture in frame
			convert "$fileName" -sample "$npw"x"$nph"! -strip /tmp/"$lineNumber"_2.jpg
		fi
		if [ $variant -eq 5 ] ; then #white border around the pic in frame
		    border=$(( RANDOM % 30 + 10 ))
		    npw2=`awk "BEGIN {print $npw-$border-$border}"`
		    nph2=`awk "BEGIN {print $nph-$border-$border}"`
		    log "Border: "$border" NPW: "$npw" NPH: "$nph" NPW2: "$npw2" NPH2: "$nph2
			convert "$fileName" -sample "$npw2"x"$nph2"! -strip -mattecolor "#dddddd" -frame 3x3+0+0 /tmp/"$lineNumber"_3.jpg
			convert /tmp/"$lineNumber"_3.jpg -bordercolor "#f0f0ff" -border $borderx$border /tmp/"$lineNumber"_2.jpg
			rm /tmp/"$lineNumber"_3.jpg
		fi
		composite -geometry +"$nfx"+"$nfy" /tmp/"$lineNumber"_2.jpg /tmp/"$lineNumber"_1.jpg /tmp/$lineNumber.jpg
		log "Temp file /tmp/$lineNumber.jpg"

		rm /tmp/"$lineNumber"_1.jpg
		rm /tmp/"$lineNumber"_2.jpg
		#exit
		
		if [ $orientation -eq 8 ] || [ $orientation -eq 3 ] || [ $orientation -eq 6 ] ; then
			degree="90"
			if [ $orientation -eq 8 ] ; then
				degree="-90"
			fi
			if [ $orientation -eq 3 ] ; then
				degree="180"
			fi
			if [ $orientation -eq 6 ] ; then
				degree="90"
			fi
			
			log "Orientation: "$orientation" Rotate with Degree: "$degree
			convert /tmp/$lineNumber.jpg -rotate $degree /tmp/$lineNumber.jpg
		fi
	else
	#No frame around; very easy and go away
		convert -size x$maxHeight "$fileName" -auto-orient -sample x$maxHeight -strip /tmp/$lineNumber.jpg
	fi	

fi #4 or 5

cat /tmp/$lineNumber.jpg
rm /tmp/$lineNumber.jpg
