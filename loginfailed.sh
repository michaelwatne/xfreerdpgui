#!/bin/bash

#FUNCTIONS

#SHOW LOGIN BOX WHEN SESSION DISCONNECTS (EXIT STATUS 1,2,3,11)
showlogin() {
case "$exitstatus3" in
1|2|3|11)
. ./index.sh
 ;;
esac
}

#SHOW LOGIN BOX
logindetails=$(zenity --forms --title="Thin Client Login" --text="Incorrect Login Details or Login is Required\nTo access the RDP Server, enter your login details." --add-entry=Username --add-password=Password --ok-label=connect --window-icon=info --separator=",")
#IF EXTRANET CONNECTION FAILED, RETURN 1
loginfailed() {
. ./loginfailed.sh
}

#IF USER PRESSED CANCEL INSTEAD OF LOGGING IN
if [[ $? == 1 ]];
then
zenity --info --text "Click the computer icon on the top bar to reload the login dialog any time you want to access the remote desktop. If this is a secured session (restricted to RDP use only), it is highly recommended to click that icon." --width "300"
exit
fi

#GET LOGIN DETAILS
username=$(awk -F, '{print $1}' <<<$logindetails)
password=$(awk -F, '{print $2}' <<<$logindetails)

#CHECK FOR WORKING CREDENTIALS USING /auth-only (INTRANET CHECK)
xfreerdp /auth-only /v:192.168.1.113 /u:$username /p:$password
exitstatus=$?
echo
echo $exitstatus

case $exitstatus in
	0)
		#REQUEST VIEW TYPE
		view=$(zenity --list --radiolist --text "Select a view" --hide-header --column "" --column "" TRUE "Intranet Connection (Connect while on the network)" FALSE "Multi-Monitor Intranet Connection (Connect while on the network)" --width=500)
		case $view in
			#CHECK IF VIEWTYPE IS 1
			"Intranet Connection (Connect while on the network)")
				xfreerdp /f /v:192.168.1.113 /u:$username /p:$password
				exitstatus3=$?
				echo $exitstatus3
				showlogin
			;;
			#CHECK IF VIEWTYPE IS 2
			"Multi-Monitor Intranet Connection (Connect while on the network)")
				xfreerdp /multimon /f /v:192.168.1.113 /u:$username /p:$password
				exitstatus3=$?
				showlogin
			;;
		esac
	;;
	131)
		#IF INTRANET CONNECTION FAILED, TRY EXTRANET
		xfreerdp /auth-only /v:192.168.1.113 /u:$username /p:$password
		exitstatus2=$?
		#IF EXTRANET CONNNECTION PASSED, REQUEST VIEWTYPE FOR EXTRANET
		case $exitstatus2 in
			0)
				#REQUEST VIEW TYPE
				view=$(zenity --list --radiolist --text "Select a view" --hide-header --column "" --column "" TRUE "Internet Connection (Connect while outside the network)" --width=500)
					xfreerdp /f /v:47.226.78.191 /u:$username /p:$password
					exitstatus3=$?
					showlogin
			;;
			131)
			loginfailed
			;;
		esac
	;;
	esac
