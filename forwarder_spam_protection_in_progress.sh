#!/bin/bash

server=$(hostname)
echo "Server: $server"

while getopts "r" opt; do
	case $opt in
		r)
			echo "Reverting changes made by this script."
			rm -f /etc/global_spamassassin_enable
			sed -i 's/globalspamassassin=1/globalspamassassin=0/' /etc/exim.conf.localopts
			sed -i 's/no_forward_outbound_spam_over_int=5/no_forward_outbound_spam_over_int/' /etc/exim.conf.localopts
			echo "Changes reverted. Rebuilding and restarting Exim."
			/scripts/buildeximconf
			/scripts/restartsrv_exim
		 	exit 1	
			;;
		?)
			echo "Please use -r to revert changes made by this script."
			exit 1
			;;
	esac
done

#Check if global_spamassassin_enable exists and if not create it
if [ -f /etc/global_spamassassin_enable ];
	then
		echo "File: /etc/global_spamassassin_enable already exists. Nothing to do"	
 	else
		echo "global_spamassassin_enable file does not exist. Creating it"
                touch /etc/global_spamassassin_enable
		echo "File created" 	
fi

#Check value of globalspamassassin in /etc/exim.conf.localopts and change it to 1 if it is 0
globalspamassassin_check=$(grep 'globalspamassassin' /etc/exim.conf.localopts)
localopts_bkp=$(cp -vpf /etc/exim.conf.localopts /etc/exim.conf.localopts-bkp)
echo "Creating backup of exim.conf.localopts: $localopts_bkp"

if [ "$globalspamassassin_check" == "globalspamassassin=0"  ];
	then
		echo "Value for globalspamassassin is 0. Changing to 1"
		sed -i 's/globalspamassassin=0/globalspamassassin=1/' /etc/exim.conf.localopts
	       	echo "Value changed to 1"	
	else
		echo "Value for globalspamassassin is: $globalspamassassin_check" 
fi

#Check if no_forward_outbound_spam_over_int has any value set in /etc/exim.conf.localopts and change it to 5
no_forward_outbound_spam_over_int_check=$(grep 'no_forward_outbound_spam_over_int' /etc/exim.conf.localopts)
if [ "$no_forward_outbound_spam_over_int_check" == "no_forward_outbound_spam_over_int=5" ];
        then
                echo "Value of no_forward_outbound_spam_over_int is already 5: grep result: $no_forward_outbound_spam_over_int_check. Nothing to do"

        elif [ "$no_forward_outbound_spam_over_int_check" == "no_forward_outbound_spam_over_int" ];
        then
                echo "no_forward_outbound_spam_over_int does not have any value. Changing it to 5"
                sed -i 's/no_forward_outbound_spam_over_int/no_forward_outbound_spam_over_int=5/' /etc/exim.conf.localopts
                echo "Value changed to 5"
        else
                echo "no_forward_outbound_spam_over_int missing from exim.conf file. Adding it."
                echo 'no_forward_outbound_spam_over_int=5' >> /etc/exim.conf.localopts
                echo "Value set to 5."  
fi

#Rebuild Exim, check if conf is valid and restart service.
echo "Rebuilding and Restarting Exim"
exim_restart=$(/scripts/restartsrv_exim | grep 'exim restarted successfully.')
exim_rebuild=$(/scripts/buildeximconf | grep 'Configuration file passes test!  New configuration file was installed.')
exim_rebuild_restart_not_required=$("$no_forward_outbound_spam_over_int_check" == "no_forward_outbound_spam_over_int=5" && -f /etc/global_spamassassin_enable && "$globalspamassassin_check" == "globalspamassassin_check=1")

if [ "$exim_rebuild_restart_not_required" == 1 ];
	then
 		echo "Rebuild and restart not required."
   	elif [ "$exim_rebuild" == 1 ];
    	then
     		$exim_restart
       	else
		echo "Exim rebuild failed. Please check server log"
  fi

#if [[ "$no_forward_outbound_spam_over_int_check" == "no_forward_outbound_spam_over_int=5" && -f /etc/global_spamassassin_enable && "$globalspamassassin_check" == "globalspamassassin_check=1" ]]
#	then
 #		echo ""

#if [ "$exim_rebuild" == "Configuration file passes test!  New configuration file was installed." ];
#	then
#		echo "Exim rebuilt successfully. Proceeding with restart"
#		echo "$exim_restart"
#	else
#		echo "Exim rebuild failed. Please check server log"
#fi
