#!/bin/sh 

dialog --title "Terms and conditions of Use" --yesno "`cat ~/.mybrowser/userterm`" 200 100

response=$?

leave_msg="Sorry, you can't use nae browser if you don't like CTF."

if [ $response = 1 -o $response = 255 ] ; then
    dialog --title "Apology" --msgbox "$leave_msg" 20 100
fi

