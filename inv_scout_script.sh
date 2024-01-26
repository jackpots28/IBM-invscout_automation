#!/bin/bash

# Aug 2023
# Script for quickly running invscout command on VIOs(s)
# format is to run script with 1 arg "host" - you can run this in a loop as well
# make sure dest dirs are correct for where file needs to be scp'd to / from

# Dependencies required to run: sshpass and curl
# Built on Ubuntu 18.04

# Change this to directory you want
local_save_path="/home/<USERID>/<DIR>"
remote_save_path="/<DIR>"

curl --insecure https://public.dhe.ibm.com/software/server/firmware/catalog.mic > $local_save_path/catalog.mic;

host="$1"
ping -c1 -W1 $host;

if [[ $? -ne 0 ]]
then
        echo "--- Error ---";
        echo "--- Is the host name provided correct and up? ---";
        exit 1;
else
        echo "--- Ping success. Continuing. ---";
fi

if [[ $host =~ .*"vio".* ]]
then
        echo "--- $host is a VIO ---";
        echo "---  Using PADMIN  ---";
        read -sp 'Please enter PADMIN Password: ' passvar;
        temp_arch=$(sshpass -p $passvar ssh padmin@$host \
        "echo "uname -a" | oem_setup_env" | awk '{print $1}');
        echo $temp_arch;
        sshpass -p $passvar scp $local_save_path/catalog.mic padmin@$host:$remote_save_path;
        if [[ $? -ne 0 ]]
        then
                echo "--- SCP FAILED ---";
        else
                echo "--- SCP Complete, Running Invscout and collecting .mup file";
                sshpass -p $passvar ssh padmin@$host \
                "echo "mv $remote_save_path/catalog.mic /var/adm/invscout/microcode/catalog.mic" | oem_setup_env; \
                echo "invscout" | oem_setup_env;";
                sshpass -p $passvar scp padmin@$host:/var/adm/invscout/$host.mup $local_save_path/;

                ls -ld $local_save_path/*$host*.mup
                echo "--- Script Complete ---";
                echo "--- Upload data to: ---";
                echo "http://www14.software.ibm.com/webapp/set2/mds/fetch?page=mdsUpload.html";
                exit 0;
        fi
else
        echo "--- $host is NOT a VIO ---";
fi

printf "\n";
echo "--- SCP'ing catalog.mic file to $host";
scp $local_save_path/catalog.mic $host:$remote_save_path;

if [[ $? -ne 0 ]]
then
        echo "--- SCP FAILED ---";
else
        echo "--- SCP Complete, Running Invscout and collecting .mup file";
        ssh $host "sudo mv $remote_save_path/catalog.mic /var/adm/invscout/microcode/catalog.mic; sudo invscout";
        scp $host:/var/adm/invscout/$host.mup $local_save_path/;

        ls -ld $local_save_path/*$host*.mup
        echo "--- Script Complete ---";
        echo "--- Upload data to: ---";
        echo "http://www14.software.ibm.com/webapp/set2/mds/fetch?page=mdsUpload.html";
        exit 0;
fi
