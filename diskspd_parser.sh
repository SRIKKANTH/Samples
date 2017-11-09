csv_file=$1
csv_file_tmp=output_tmp.csv

echo $csv_file
dos2unix x* 2> /dev/null

echo "Iteration,TestType,BlockSize,Threads,Jobs,TotalIOPS,ReadIOPS,WriteIOPS,TotalBw(MBps),ReadBw(MBps),WriteBw(MBps),TotalAvgLat,ReadAvgLat,WriteAvgLat,TotalLatStdDev,ReadLatStdDev,WriteLatStdDev,SoftwareCache,HardwareCache" > $csv_file

#out_list=(`ls *.out`)
json_list=(`ls x*`)
count=0
while [ "x${json_list[$count]}" != "x" ]
do
	file_name=${json_list[$count]}

	Iteration=`echo $file_name|sed 's/xx//'`
	Jobs=`cat $file_name| grep "number of outstanding"|awk '{print $6}'|head -1`
	
	ReadIOPS=`cat $file_name| grep "total:"|awk '{print $8}'|head -2 |tail -1`
	ReadAvgLat=`cat $file_name| grep "total:"|awk '{print $10}'|head -2 |tail -1`
	ReadLatStdDev=`cat $file_name| grep "total:"|awk '{print $12}'|head -2 |tail -1`
	ReadBw=`cat $file_name| grep "total:"|awk '{print $6}'|head -2 |tail -1`
	
	WriteIOPS=`cat $file_name| grep "total:"|awk '{print $8}'|tail -1`
	WriteAvgLat=`cat $file_name| grep "total:"|awk '{print $10}'|tail -1`
	WriteLatStdDev=`cat $file_name| grep "total:"|awk '{print $12}'|tail -1`
	WriteBw=`cat $file_name| grep "total:"|awk '{print $6}'|tail -1`
	
	BlockSize=`cat $file_name| grep "block size:"|awk '{print $3}'| awk '{printf "%d\n", $1/1024}'| head -1`K
	TestType=`cat $file_name| grep "using.*:"|awk '{print $2}'| head -1`-`cat $file_name| grep "performing"|awk '{print $2}'| head -1`
	Threads=`cat $file_name| grep "threads"|awk '{print $4}'| head -1`
	
	TotalIOPS=`cat $file_name| grep "total:"|awk '{print $8}'|head -1`
	TotalAvgLat=`cat $file_name| grep "total:"|awk '{print $10}'|head -1`
	TotalLatStdDev=`cat $file_name| grep "total:"|awk '{print $12}'|head -1`
	TotalBw=`cat $file_name| grep "total:"|awk '{print $6}'|head -1`
	
	SoftwareCache=`cat $file_name| grep "software cache"| awk '{print $3}'|head -1`
	HardwareCache=`cat $file_name| grep "hardware write cache"| sed "s/,//"|awk '{print $4}'| sed 's/[^a-z]*//'|head -1`
	echo "$Iteration,$TestType,$BlockSize,$Threads,$Jobs,$TotalIOPS,$ReadIOPS,$WriteIOPS,$TotalBw,$ReadBw,$WriteBw,$TotalAvgLat,$ReadAvgLat,$WriteAvgLat,$TotalLatStdDev,$ReadLatStdDev,$WriteLatStdDev,$SoftwareCache,$HardwareCache,$file_name" >> $csv_file

	#echo "$Iteration,$TestType,$BlockSize,$Threads,$Jobs,$TotalIOPS,$ReadIOPS,$ReadBw,$WriteIOPS,$WriteBw,$HardwareCache,$SoftwareCache" >> $csv_file
	#echo "$Iteration,$TestType,$BlockSize,$Threads,$Jobs,$TotalIOPS,$ReadIOPS,$ReadBw,$WriteIOPS,$WriteBw,$SoftwareCache,'$HardwareCache'" >> $csv_file
	((count++))
done
cat $csv_file | sort -n| sed 's/^,,.*//' > temp.txt
mv temp.txt $csv_file
echo "Parsing completed!" 

