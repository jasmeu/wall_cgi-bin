#!/bin/bash

#LICENSE: https://github.com/jasmeu/wall_cgi-bin/blob/master/LICENSE
#Before using this script, consider: https://github.com/jasmeu/wall_cgi-bin/blob/master/README.md

#1. you create the list with the paths to all your photos by calling: 
#find "path/to/search/ie/the/root/folder/for/your/pics" -type f -iname "*.jpg" > list.txt
#2. in the call head -n $lineNumber ..., you adjust the path to list.txt to correspond to the pathrelevant for you
#3. you get the number below (i.e. the one instead 7681) by calling 
#wc -l list.txt

#4. you put the script in a folder called cgi-bin
#5. you make the script executable: chmod u+x getPic2.sh
#6. Read the preparation steps which are needed to make this work under: <TBD>
#7. you start a test server on your mac with the command 
#python -m CGIHTTPServer 8000 
#8. and then you may call the script on: http://localhost:8000/cgi-bin/getPic2.sh?950:123

function log {
    #echo "$1" >> ~/Documents/wall/cgi-bin/log.txt
    a="a"
} 

countPicz=7681-3

lineNumber=$(( ((RANDOM<<15)|RANDOM) % $countPicz + 1 ))

fileName=`head -n $lineNumber ~/Documents/wall/list.txt | tail -1`

maxHeight=${QUERY_STRING%:*}

if [ -f ~/Documents/wall/cgi-bin/log.txt ] ; then 
	rm ~/Documents/wall/cgi-bin/log.txt
fi

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
#echo $fileName $maxHeight

variant=$(( RANDOM % 5 + 1 ))

#variant=4

if [ $variant -eq 1 ] ; then
	#No frame around
	gm convert -size x$maxHeight "$fileName" -auto-orient -resize x$maxHeight -strip /tmp/$lineNumber.jpg
fi

if [ $variant -eq 2 ] ; then
	#coloured frame
	r=$(( RANDOM % 65534 ))
	g=$(( RANDOM % 65534 ))
	b=$(( RANDOM % 65534 ))
	gm convert -size x$maxHeight "$fileName" -auto-orient -resize x$maxHeight -strip -mattecolor "rgb($r,$g,$b)" -frame 10x10+5+5  /tmp/$lineNumber.jpg
fi

if [ $variant -eq 3 ] ; then
	#coloured frame + white space
	r=$(( RANDOM % 65534 ))
	g=$(( RANDOM % 65534 ))
	b=$(( RANDOM % 65534 ))
    border=$(( RANDOM % 15 + 10 ))
    h=$maxHeight-$border-$border
	gm convert -size x$maxHeight "$fileName" -auto-orient -resize x$h -strip -mattecolor "#dddddd" -frame 3x3+0+0  /tmp/"$lineNumber"_1.jpg
	gm convert /tmp/"$lineNumber"_1.jpg -bordercolor "#f0f0ff" -border $borderx$border -mattecolor "rgb($r,$g,$b)" -frame 10x10+4+4 /tmp/$lineNumber.jpg
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

	sizeStr=`gm identify -format "%w,%h_%[EXIF:Orientation]" "$fileName"`

	log "Photo size: "$sizeStr
	w=${sizeStr%,*}
	wow=${sizeStr#*,}
	h=${wow%_*}
	orientation=${sizeStr#*_}
	
	log "Photo size: "$w"_"$h"_"$orientation

	rf=`echo "scale=6 ; $pw / $ph" | bc`
	rp=`echo "scale=6 ; $w / $h" | bc`

	log "Ratio frame: "$rf" Ration Photo: "$rp
	
	nfh=$fh
	nfw=$fw
	nph=$ph
	npw=$pw
	nfx=$fx
	nfy=$fy

	compare=`echo $rp'>'$rf | bc`

	if [ $compare -eq 1 ] ; then
		log "Branch 1"
		nph=`echo "scale=6 ; $pw / $rp" | bc`
		dh=`echo "scale=6 ; $nph / $ph" | bc`
		log "dh: "$dh
		nfh=`echo "$fh * $dh" | bc`
		nfy=`echo "$fy * $dh" | bc`
	else
		log "Branch 2"
		npw=`echo "scale=6 ; $ph * $rp" | bc`
		dw=`echo "scale=6 ; $npw / $pw" | bc`
		log "dw: "$dw
		nfw=`echo "$fw * $dw" | bc`
		nfx=`echo "$fx * $dw" | bc`
	fi

	log "fw:"$nfw"_fh:"$nfh"_fx:"$nfx"_fy:"$nfy"_pw:"$npw"_ph:"$nph

	log "File Name: ""$fileName"	

	compare=`echo $nfh'>'$maxHeight | bc`
	
	if [ $compare -eq 1 ] ; then #if we can still resize down the frame
		rr=`echo "scale=6 ; $maxHeight / $nfh" | bc`
		log "Resize Ratio: "$rr
		nfh=$maxHeight
		myval=`echo "$nfw * $rr" | bc`
		nfw=$myval
		nph=`echo "$nph * $rr" | bc`
		npw=`echo "$npw * $rr" | bc`
		nfx=`echo "$nfx * $rr" | bc`
		nfy=`echo "$nfy * $rr" | bc`

		log "fw:"$nfw"_fh:"$nfh"_fx:"$nfx"_fy:"$nfy"_pw:"$npw"_ph:"$nph
		
		gm convert ~/Documents/wall/cgi-bin/frames/"$frIdx".jpg -sample "$nfw"x"$nfh"! -strip /tmp/"$lineNumber"_1.jpg
		
		if [ $variant -eq 4 ] ; then #full picture in frame
			gm convert "$fileName" -sample "$npw"x"$nph"! -strip /tmp/"$lineNumber"_2.jpg
		fi
		if [ $variant -eq 5 ] ; then #white border around the pic in frame
		    border=$(( RANDOM % 30 + 10 ))
		    npw2=`echo "$npw - $border - $border - 6" | bc`
		    nph2=`echo "$nph - $border - $border - 6" | bc`
		    log "Border: "$border" NPW: "$npw" NPH: "$nph" NPW2: "$npw2" NPH2: "$nph2
			gm convert "$fileName" -sample "$npw2"x"$nph2"! -strip -mattecolor "#dddddd" -frame 3x3+0+0 /tmp/"$lineNumber"_3.jpg
			gm convert /tmp/"$lineNumber"_3.jpg -bordercolor "#f0f0ff" -border $borderx$border /tmp/"$lineNumber"_2.jpg
			rm /tmp/"$lineNumber"_3.jpg
		fi
		gm composite -geometry +"$nfx"+"$nfy" /tmp/"$lineNumber"_2.jpg /tmp/"$lineNumber"_1.jpg /tmp/$lineNumber.jpg

		rm /tmp/"$lineNumber"_1.jpg
		rm /tmp/"$lineNumber"_2.jpg
		
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
			gm mogrify /tmp/$lineNumber.jpg -rotate $degree /tmp/$lineNumber.jpg
		fi
	else
	#No frame around; very easy and go away
		gm convert -size x$maxHeight "$fileName" -auto-orient -resize x$maxHeight -strip /tmp/$lineNumber.jpg
	fi	

fi #4 or 5

cat /tmp/$lineNumber.jpg
rm /tmp/$lineNumber.jpg
 