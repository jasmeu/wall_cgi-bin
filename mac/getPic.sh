#!/bin/bash

#LICENSE: https://github.com/jasmeu/wall_cgi-bin/blob/master/LICENSE
#Before using this script, consider: https://github.com/jasmeu/wall_cgi-bin/blob/master/README.md

#1. you create the list with the paths to all your photos by calling: 
#find "path/to/search/ie/the/root/folder/for/your/pics" -type f -iname "*.jpg" > list.txt
#2. in the call head -n $lineNumber ..., you adjust the path to list.txt to correspond to the pathrelevant for you
#3. you get the number below (i.e. the one instead 7681) by calling 
#wc -l list.txt

#4. you put the script in a folder called cgi-bin
#5. you make the script executable: chmod u+x getPic.sh
#6. you start a test server on your mac with the command 
#python -m CGIHTTPServer 8000 
#7. and then you may call the script on: http://localhost:8000/cgi-bin/getPic.sh?950:123


countPicz=7681-3

lineNumber=$(( ((RANDOM<<15)|RANDOM) % $countPicz + 1 ))

fileName=`head -n $lineNumber ~/Documents/wall/list.txt | tail -1`

maxHeight=${QUERY_STRING%:*}

echo "Cache-Control: no-cache, no-store, must-revalidate";
echo "Pragma: no-cache";
echo "Expires: 0";
#echo "Content-type: text/plain"
echo "Content-type: image/jpg"
echo ""
#echo $fileName $maxHeight

variant=$(( RANDOM % 3 + 1 ))

#variant=3

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

cat /tmp/$lineNumber.jpg
rm /tmp/$lineNumber.jpg
