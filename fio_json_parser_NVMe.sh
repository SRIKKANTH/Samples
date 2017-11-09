#Sri matrenamaha
#
#

#csv_file=`hostname`_fio.csv
csv_file=$1
csv_file_tmp=output_tmp.csv
echo $file_name
echo $csv_file

json_list=(`ls *.json`)
count=0
while [ "x${json_list[$count]}" != "x" ]
do
	file_name=${json_list[$count]}
	Iteration=`echo -e $file_name |gawk -f JSON.awk|grep '"jobname"'| tail -1| sed 's/.*]//'| sed 's/[[:blank:]]//g'| sed 's/"iteration\(.*\)"/\1/'`
	Jobs=`echo -e $file_name |awk -f JSON.awk|grep '"jobname"'| wc -l`
	ReadIOPS=`echo -e $file_name |awk -f JSON.awk|grep '"read","iops"'| sed 's/.*]//' | paste -sd+ - | bc`
	MaxOfReadMeanLatency=`echo -e $file_name |awk -f JSON.awk|grep '"read","lat","mean"'| sed 's/.*]//'| sed 's/[[:blank:]]//g'|sort -g|tail -1`
	if  [ "x$MaxOfReadMeanLatency" == "x" ]
	then
		MaxOfReadMeanLatency=`echo -e $file_name |awk -f JSON.awk|grep 'read.*"lat.*mean'| sed 's/.*]//'| sed 's/[[:blank:]]//g'|sort -g|tail -1`
	fi	
	ReadMaxLatency=`echo -e $file_name |awk -f JSON.awk|grep '"read","lat","max"'| sed 's/.*]//'| sed 's/[[:blank:]]//g'|sort -g|tail -1`
	if  [ "x$ReadMaxLatency" == "x" ]
	then
		ReadMaxLatency=`echo -e $file_name |awk -f JSON.awk|grep 'read.*"lat.*max'| sed 's/.*]//'| sed 's/[[:blank:]]//g'|sort -g|tail -1`
	fi
	ReadBw=`echo -e $file_name |awk -f JSON.awk|grep '"read","bw"'| sed 's/.*]//'| sed 's/[[:blank:]]//g'| paste -sd+ - | bc`
	WriteIOPS=`echo -e $file_name |awk -f JSON.awk|grep '"write","iops"'| sed 's/.*]//' | paste -sd+ - | bc`
	MaxOfWriteMeanLatency=`echo -e $file_name |awk -f JSON.awk|grep '"write","lat","mean"'| sed 's/.*]//'| sed 's/[[:blank:]]//g'|sort -g|tail -1`
	if  [ "x$MaxOfWriteMeanLatency" == "x" ]
	then
		MaxOfWriteMeanLatency=`echo -e $file_name |awk -f JSON.awk|grep 'write.*"lat.*mean'| sed 's/.*]//'| sed 's/[[:blank:]]//g'|sort -g|tail -1`
	fi	
	WriteMaxLatency=`echo -e $file_name |awk -f JSON.awk|grep '"write","lat","max"'| sed 's/.*]//'| sed 's/[[:blank:]]//g'|sort -g|tail -1`
	
	if  [ "x$WriteMaxLatency" == "x" ]
	then
		WriteMaxLatency=`echo -e $file_name |awk -f JSON.awk|grep 'write.*"lat.*max'| sed 's/.*]//'| sed 's/[[:blank:]]//g'|sort -g|tail -1`		
	fi
	WriteBw=`echo -e $file_name |awk -f JSON.awk|grep '"write","bw"'| sed 's/.*]//'| sed 's/[[:blank:]]//g'| paste -sd+ - | bc`
	BlockSize=`echo -e $file_name |awk -f JSON.awk|grep \"bs\"| awk '{print $3}'| sed s/\"//g`
	TestType=`echo -e $file_name |awk -f JSON.awk|grep \"rw\"| awk '{print $3}'| sed s/\"//g`
	Threads=`echo -e $file_name |awk -f JSON.awk|grep \"iodepth\"| awk '{print $3}'| sed s/\"//g`
	IFS='-' read -r -a array <<< "$file_name"
	TotalIOPS=`echo $ReadIOPS $WriteIOPS	| awk '{printf "%d\n", $1+$2}'`
	echo "$Iteration,$TestType,$BlockSize,$Threads,$Jobs,$TotalIOPS,$ReadIOPS,$MaxOfReadMeanLatency,$ReadMaxLatency,$ReadBw,$WriteIOPS,$MaxOfWriteMeanLatency,$WriteMaxLatency,$WriteBw" >> $csv_file_tmp
	((count++))
done

cat $csv_file_tmp | sort -n | grep -v "^$" > temp.txt
mv temp.txt $csv_file_tmp

echo "" > $csv_file
echo ",Max IOPS of each mode," >> $csv_file
echo ",Test Mode,Max IOPS (BSize-iodepth)," >> $csv_file
modes='randread randwrite read write' 
for testmode in $modes 
do
	max_iops=`cat $csv_file_tmp | grep ",$testmode" | awk '{split($0,arr,","); print arr[6]}'| sort -g|tail -1`
	max_bs=`cat $csv_file_tmp | grep ",$testmode"| grep ",$max_iops" | awk '{split($0,arr,","); print arr[3]}'`
	max_iodepth=`cat $csv_file_tmp | grep ",$testmode"| grep ",$max_iops" | awk '{split($0,arr,","); print arr[4]}'`
	if  [ "x$max_iops" != "x" ]
	then
		echo ",$testmode,$max_iops ($max_bs-$max_iodepth)," >> $csv_file
	fi
done

echo "" >> $csv_file
echo ",Max IOPS of each BlockSize," >> $csv_file
modes='randread randwrite read write'
block_sizes='1K 2K 4K 8K 16K 32K 64K 128K 256K 512K 1024K 2048K'
echo ",Test Mode,Block Size,iodepth,Max IOPS (BSize-iodepth)," >> $csv_file
for testmode in $modes 
do
	for block in $block_sizes 
	do
		max_iops=`cat $csv_file_tmp | grep ",$testmode" | grep ",$block" | awk '{split($0,arr,","); print arr[6]}'| sort -g|tail -1`

		max_bs=`cat $csv_file_tmp | grep ",$testmode"| grep ",$block"| grep ",$max_iops" | awk '{split($0,arr,","); print arr[3]}'`
		max_iodepth=`cat $csv_file_tmp | grep ",$testmode"| grep ",$block"| grep ",$max_iops" | awk '{split($0,arr,","); print arr[4]}'`

		if  [ "x$max_iops" != "x" ]
		then
		echo ",$testmode,$block,$iodepth,$max_iops ($max_bs-$max_iodepth)," >> $csv_file
		fi
	done
done
echo "" >> $csv_file
echo "Iteration,TestType,BlockSize,Threads,Jobs,TotalIOPS,ReadIOPS,MaxOfReadMeanLatency,ReadMaxLatency,ReadBw,WriteIOPS,MaxOfWriteMeanLatency,WriteMaxLatency,WriteBw" >> $csv_file
cat $csv_file_tmp >> $csv_file
rm -rf $csv_file_tmp
echo "Parsing completed!" 
