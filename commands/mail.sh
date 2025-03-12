 #!/bin/sh


export allow_helper_functions=true
command_name=$(echo $(basename $1))




# Display help
# Usage: display_help
display_help() {
	echo " \
		Send a mail from command line.
		This command will send a mail according to the content stored in in the file '/tmp/$NAME_LOWERCASE-mail-content'.
		WARNING: this file will be deleted after the mail has been sent.

		Options: 
		-i, --install <server> <port> <source address> <source password> <destination address> <object>    create automation to send mail on regular basis.
		-o, --oneshot <server> <port> <source address> <source password> <destination address> <object>    send a single oneshot mail.

		Example:
		$NAME_ALIAS mail -o 'smtps://mail.server.com' '465' 'username@sender.com' 'vEryStr0ngP4SsW0rd' 'destination@destination.com' 'notification of the day'
		
	" | sed 's/^[ \t]*//'

}




# Install requirements of the subcommand
# This function is intended to be used from $CURRENT_CLI with this syntax: $CURRENT_CLI $command init_command
# (it will only work if init_command is available as an argument with the others options)
# Usage: $CURRENT_CLI $subcommand init_command
init_command() {
	# $HELPER create_automation $command_name


	$HELPER create_completion $command_name
}




# Send a mail
# Usage: send_mail <server> <port> <source address> <source password> <destination address> <object>
send_mail() {

	if [ "$($HELPER exists_command "curl")" = "exists" ]; then

		local server="$1"
		local port="$2"
		local source_address="$3"
		local source_password="$4"
		local destination_address="$5"
		local mail_object="$6"


		# Curl must use a file to send a valid mail
		local file_mail_tmp="/tmp/$NAME_LOWERCASE-mail"
		local file_mail_content_tmp="/tmp/$NAME_LOWERCASE-mail-content"



		if [ "$(echo $server | grep 'smtp' | grep '://')" ] && [ $port != "" ] && [ $source_address != "" ] && [ $source_password != "" ] && [ $destination_address != "" ]; then

			echo "From: $source_address"			> $file_mail_tmp
			echo "To: $destination_address"			>> $file_mail_tmp
			echo "Subject: $mail_object"			>> $file_mail_tmp
			echo "\n"								>> $file_mail_tmp
			cat "$file_mail_content_tmp"			>> $file_mail_tmp

			curl -s --url "$server:$port" --ssl-reqd \
				--mail-from "$source_address" \
				--mail-rcpt "$destination_address" \
				--user "$source_address:$source_password" \
				--upload-file $file_mail_tmp

			# Delete tmp content file
			rm -rf $file_mail_tmp
			rm -rf $file_mail_content_tmp

		else
			$HELPER log_error "invalid options"
		fi

	fi
}




# Install the automation based on given user data
# Usage: install_automation <server> <port> <source address> <source password> <destination address> <object> <content>
install_automation() {
	
	local server="$1"
	local port="$2"
	local source_address="$3"
	local source_password="$4"
	local destination_address="$5"
	local mail_object="$6"

	$HELPER create_automation "$command_name -o '$server' '$port' '$source_address' '$source_password' '$destination_address' '$mail_object'"
}





if [ ! -z $2 ]; then
	case $2 in
		init_command)		init_command ;;
		--help)				display_help ;;
		-i|--install)		install_automation "$3" "$4" "$5" "$6" "$7" "$8" "$9" ;;
		-o|--oneshot)		send_mail "$3" "$4" "$5" "$6" "$7" "$8" "$9" ;;
		*)					$HELPER log_error "unknown option $2 from $1 command.'\n'$USAGE" && exit ;;
	esac
else
	display_help
fi




# Properly exit
exit

#EOF