#!/bin/bash

#setup shell script for funannotate databases

#likely run some checks here
command -v hmmpress >/dev/null 2>&1 || { echo "Funannotate requires HMMer 3.1 but it's not in PATH.  Aborting." >&2; exit 1; }
command -v wget >/dev/null 2>&1 || { echo "Funannotate requires wget but it's not in PATH.  Aborting." >&2; exit 1; }
command -v makeblastdb >/dev/null 2>&1 || { echo "Funannotate requires BLAST+ but it's not in PATH.  Aborting." >&2; exit 1; }


#start downloading databases
mkdir -p DB
cd DB

#Do MEROPS first as need to download manually, wait for download to apear before moving on
echo "Okay, starting downloading of databases...."

#check if Merops is already downloaded
if [ ! -f merops_formatted.fa ]; then
    echo "You need to manually download the MEROPS protease database as it requires a log in"
    echo "download: merops_scan.lib.txt   from here: https://merops.sanger.ac.uk/download/"
    echo "then move the file into the funnanotate DB folder, once the file is in the folder the script will proceed."
    until [ -f merops_scan.lib.txt ]
    do
         sleep 5
    done
    tr -d '\r' < merops_scan.lib.txt | sed 's/ - /#/g' | while read line; do set -- "$line"; IFS="#"; declare -a Array=($*); if [[ "${Array[0]}" == ">"* ]]; then echo ${Array[0]} ${Array[2]}; else echo $line; fi; done > merops_formatted.fa
    makeblastdb -in merops_formatted.fa -input_type fasta -dbtype prot -title MEROPS -parse_seqids -out MEROPS
else
    echo "MEROPS DB found, skipping download"
fi

#get uniprot and format database
if [ ! -f uniprot_sprot.fasta ]; then
    echo "Now downloading/formatting UniProt DB"
    wget -c --tries=0 --read-timeout=20 ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.fasta.gz
    gunzip uniprot_sprot.fasta.gz
    makeblastdb -in uniprot_sprot.fasta -input_type fasta -dbtype prot -title uniprot -parse_seqids -out uniprot
else
    echo "UniProt DB found, skipping download"
fi

#get PFAM database and associated mapping file
if [ ! -f Pfam-A.hmm ]; then
    echo "Now downloading/formatting PFam-A DB"
    wget -c --tries=0 --read-timeout=20 ftp://ftp.ebi.ac.uk/pub/databases/Pfam//current_release/Pfam-A.hmm.gz
    gunzip Pfam-A.hmm.gz
    hmmpress Pfam-A.hmm
else
    echo "Pfam-A DB found, skipping download"
fi

#get pFAM mapping tsv vile
if [ ! -f Pfam-A.clans.tsv ]; then
    echo "Now downloading PFAM mapping file"
    wget -c --tries=0 --read-timeout=20 ftp://ftp.ebi.ac.uk/pub/databases/Pfam//current_release/Pfam-A.clans.tsv.gz
    gunzip Pfam-A.clans.tsv.gz
else
    echo "PFAM mapping found, skipping download"
fi

#get dbCAN database
if [ ! -f dbCAN.hmm ]; then
    echo "Now downloading/formatting dbCAN CAZyme DB"
    wget -c --tries=0 --read-timeout=20 http://csbl.bmb.uga.edu/dbCAN/download/dbCAN-fam-HMMs.txt
    wget -c --tries=0 --read-timeout=20 http://csbl.bmb.uga.edu/dbCAN/download/FamInfo.txt
    mv FamInfo.txt dbCAN.info.txt
    sed 's/\.hmm$//g' dbCAN-fam-HMMs.txt > dbCAN.hmm
    hmmpress dbCAN.hmm
else
    echo "dbCAN DB found, skipping download"
fi

#download Eggnog
if [ ! -f fuNOG_4.5.hmm ]; then
    echo "Now downloading/formatting EggNog 4.5 DB"
    wget -c --tries=0 --read-timeout=20 http://eggnogdb.embl.de/download/eggnog_4.5/data/fuNOG/fuNOG.hmm.tar.gz
    wget -c --tries=0 --read-timeout=20 http://eggnogdb.embl.de/download/eggnog_4.5/data/fuNOG/fuNOG.annotations.tsv.gz
    gunzip FuNOG.annotations.tsv.gz
    tar -zxf fuNOG.hmm.tar.gz
    find fuNOG_hmm/ -name '*.hmm' -type f -maxdepth 1 -exec cat '{}' \; > fuNOG_4.5.hmm
    hmmpress fuNOG_4.5.hmm
    rm fuNOG.hmm.tar.gz
    rm -R fuNOG_hmm/

else
    echo "EggNog 4.5 DB found, skipping download"
fi

#get BUSCO and fungi models
if [ ! -d fungi ]; then
    echo "Downloading BUSCO fungi models"
    wget -c --tries=0 --read-timeout=20 http://busco.ezlab.org/files/fungi_buscos.tar.gz
    tar -zxf fungi_buscos.tar.gz
else
    echo "BUSCO fungi DB found, skipping download"
fi
    
if [ ! -f go.obo ]; then
    echo "Downloading Gene Ontology"
    wget -c --tries=0 --read-timeout=20 http://geneontology.org/ontology/go.obo
else
    echo "Gene Ontology already exists, if you want to update it, delete go.obo first and re-run setup.sh script"
fi

#download MiBIG database for getting best SM hit from curated database.
if [ ! -f MIBiG_prot_seqs.fa ]; then
    echo "Downloading MIBiG protein fasta files"
    wget -c --tries=0 --read-timeout=20 http://mibig.secondarymetabolites.org/MIBiG_prot_seqs_1.2.fasta
    mv MIBiG_prot_seqs_1.2.fasta MIBiG_prot_seqs.fa
    makeblastdb -in MIBiG_prot_seqs.fa -input_type fasta -dbtype prot -title MIBiG -out MIBiG
else
    echo "MIBiG database already exists, skipping download"
fi

#download InterProScan xml mapping file
if [ ! -f interpro.xml ]; then
    echo "Downloading InterPro mapping xml file"
    wget -c --tries=0 --read-timeout=20 ftp://ftp.ebi.ac.uk/pub/databases/interpro/interpro.xml.gz
    gunzip interpro.xml.gz
else
    echo "InterPro mapping file already exists, skipping download"
fi

#wrap up
echo "Script complete, funannotate is ready to roll!"
