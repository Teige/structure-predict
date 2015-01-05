E_BADARGS=85

if [ -z $2 ]
then
	niceness=10
else 
	if [ $2 != "-n" ]
	then
		echo "Usage: bash `basename $0` seqname -n [niceness]"
        	exit $E_BADARGS
		#echo "arg2 IS NOT -n"
	else
		#echo "arg2 is -n"
		if [ -z $3 ]
		then
			echo "Usage: bash `basename $0` seqname -n [niceness]"
			printf "~~~~~~~~~~~~~~~~~\nprovide niceness [-20 to 19]\nor run without -n flag to use default [10]\n"
			exit $E_BADARGS
			#echo "arg3 doesn't exist"
		elif [ -n "`echo $3 | sed -e 's/[0-9]//g' -e 's/-//g'`" ] 
		then
			echo "Usage: bash `basename $0` seqname -n [niceness]"
			printf "~~~~~~~~~~~~~~~~~\nprovide niceness [-20 to 19]\nor run without -n flag to use default [10]\n"
			exit $E_BADARGS
			#echo "arg3 is not a number" 
		elif (($3>=-20 && $3<=19))
		then
			niceness=$3
			#echo "opt is within range"
		else
			echo "Usage: bash `basename $0` seqname -n [niceness]"
			printf "~~~~~~~~~~~~~~~~~\nniceness must be a number from -20 (least nice) to 19 (most nice)\n"
			exit $E_BADARGS
		fi
	fi
fi

if [ -z "$1"  ]
then
	echo "Usage: bash `basename $0` seqname -n [niceness]"
	exit $E_BADARGS
else
	printf "seqname is $1\nniceness is $niceness\n"
fi

read -p "Continue? [y/n]" -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
	exit 1
fi
#echo "through"

seqname=$1
mkdir -p ~/film3/$seqname
seqdir=~/seq/campy/
datadir=~/film3/$seqname/

grep -A1 $(awk 'NR==1 {print $1}' $seqdir$seqname.seed|cut --complement -c 1) $seqdir$seqname.fasta | sed '1d' > $datadir$seqname.target #search for seed accession in fasta alignment, take the line beneath the matching accession, which should be the corresponding sequence - this is the target, save it as temp.

cut --complement -c $(grep -o . $datadir$seqname.target | grep -n '-'| tr -d ':-'|tr '\n' ',' | sed 's/,$//') $seqdir$seqname.raw | sort | uniq > $datadir$seqname.temp #use a comma-separated list of the positions of - gaps in the target seq (counting from 1), as positions for cut to remove in all lines of the raw sequence alignment. Remove duplicate lines with uniq. Save final alignment as .temp

seqlen=$(awk '{print length}' $datadir$seqname.temp | uniq) #measure length of sequences in MSA
eval $(echo "grep -v '[-]\{$((seqlen/2)),\}' $datadir$seqname.temp > $datadir$seqname.temp2") #remove poorly aligned seqs whose length is half or more made up of gaps

echo $seqname > $datadir$seqname.aln 
wc -l $datadir$seqname.temp2 | awk '{print $1}' >> $datadir$seqname.aln 
awk 'NR==3{print;exit}' $datadir$seqname.ess >> $datadir$seqname.aln
tr -d '-' < $datadir$seqname.target >> $datadir$seqname.aln
grep -vx $(tr -d '-' < $datadir$seqname.target) $datadir$seqname.temp2 >> $datadir$seqname.aln
#alnfile written, now the parameter file

#uncomment to remove target seq, otherwise keep for later troubleshooting or checking.
#rm $datadir$seqname.target #remove target file (of target seq as it sits in the alignment). Next we need to prepend info from the .ess to the .temp alignment to create .aln. Then write an nfpar file for film3 to read.
#rm $datadir$seqname.temp
#rm $datadir$seqname.temp2

echo -e "ALNFILE $seqname.aln\nINITEMP 0.6\nMAXSTEPS 20000000\nPOOLSIZE 9\nTRATIO 0.6\nMAXFRAGS 5\nMAXFRAGS2 25\nCONFILE $seqname.con\n\n# Uncomment line below to apply Z-coordinate constraints\n#ZFILE $seqname.zcoord" > $datadir$seqname.nfpar

cd $datadir
mkdir -p output
printf "${datadir}output/fold%03d.pdb_-_" {1..100}| parallel --nice $niceness -S :,tpalmer@moscow --progress -d _-_ film3 $datadir$seqname.nfpar ${stdin} #GNU parallel splits jobs film3 input fold{001-100} to multiple cores. Pass stdin, an array of output file names delimited by unique underscores to parallel to construct (film3) command line, set argument delimiter to underscore-dash-underscore with '-d _-_'.

#REMAINING HURDLE: film3 progresses with nan (not a number) values for all important parameters.
