 #!/bin/sh


export allow_helper_functions=true
command_name=$(echo $(basename $1))




# Display help
# Usage: display_help
display_help() {
	echo " \
		Send a mail from command line.

		Options: 
		-i, --install <server> <port> <source address> <source password> <destination address> <object> <content>    create automation to send mail on regular basis.
		-o, --oneshot <server> <port> <source address> <source password> <destination address> <object> <content>    send a single oneshot mail.

		Example:
		$NAME_ALIAS mail -o 'smtps://mail.server.com' '465' 'username@sender.com' 'vEryStr0ngP4SsW0rd' 'desination@destination.com' 'notification of the day' 'content of the mail'
		
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
# Usage: send_mail <server> <port> <source address> <source password> <destination address> <object> <content>
send_mail() {

	if [ "$($HELPER exists_command "curl")" = "exists" ]; then

		local server="$1"
		local port="$2"

		local source_address="$3"
		local source_password="$4"

		local destination_address="$5"

		local mail_object="$6"
		local mail_content="$7"


		# Curl must use a file to send a valid mail
		local file_mail_tmp="/tmp/$NAME_LOWERCASE-mail-header"



		if [ "$(echo $server | grep 'smtp' | grep '://')" ] && [ $port != "" ] && [ $source_address != "" ] && [ $source_password != "" ] && [ $destination_address != "" ]; then

			echo "From: $source_address\nTo: $destination_address\nSubject: $mail_object\n\n$mail_content" > $file_mail_tmp

			curl -s --url "$server:$port" --ssl-reqd \
				--mail-from "$source_address" \
				--mail-rcpt "$destination_address" \
				--user "$source_address:$source_password" \
				-T $file_mail_tmp

			# Delete tmp content file
			rm -rf $file_mail_tmp

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
	local mail_content="$7"

	$HELPER create_automation "$command_name -o '$server' '$port' '$source_address' '$source_password' '$destination_address' '$mail_object' '$mail_content'"
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