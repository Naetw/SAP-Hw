#!/bin/sh 
export LC_CTYPE='zh_TW.UTF-8'
touch ~/.mybrowser/bookmark 

dialog --title "Terms and conditions of Use" --yesno "`cat ~/.mybrowser/userterm`" 200 100

response=$?

leave_msg="Sorry, you can't use nae browser if you don't like CTF."

homepage="https://www.google.co.uk/" 
current_url=""

src () { # dump source to the dialog msgbox
    dialog --title "Nae browser" --msgbox "$(curl -sL $current_url)" 200 100
}

help () {
    dialog --title "Help manual" --msgbox "$(cat ~/.mybrowser/help)" 20 100
}

link () {
    # catch <a href="[link]"... 
    link=$(curl -sL $current_url | grep "<a" | gawk -F "\n" '{if(match($1,/.*<a\shref="(.*)".*<\/a>/,lk)) print lk[1]}')
    
    # make path plus url (use -v option to use shell variable)
    link=$(echo "$link" | gawk -v cur_link="$current_url" '{if(/^https?.*/) print NR " " $1 ; else print NR " " cur_link $1 }')
}

download () {
    link
    # extract link number
    idx=$(dialog --title "Nae browser" --menu "Downloads:" 200 100 200 `echo $link` \
        3>&1 1>&2 2>&3 3>&-)
    # if canceled, back to current page
    if [ "$idx" = "" ] ; then
        dialog --title "Nae browser" --msgbox "$(w3m -dump "$current_url")" 200 100
        return
    fi
    wget "$(echo "$link" | grep "^$idx " | gawk -F '\n' '{sub(/^[1-9]\s/, "", $1) ; print $1}')" -P ~/Downloads/
}

bookmark () {
    menu=$(echo "Add_a_bookmark"; echo "Delete_a_bookmark"; cat ~/.mybrowser/bookmark)
    menu=$(echo "$menu" | gawk '{print NR " " $1}') 
    idx=$(dialog --title "Nae browser" --menu "Bookmarks:" 200 100 200 `echo $menu` \
        3>&1 1>&2 2>&3 3>&-)
    if [ "$idx" = "" ] ; then
        dialog --title "Nae browser" --msgbox "$(w3m -dump "$current_url")" 200 100
        return
    fi
    if [ "$idx" -gt 2 ] ; then
        idx=$(( $idx-2 ))
        current_url=$(sed -n "$idx p" ~/.mybrowser/bookmark)
        dialog --title "Nae browser" --msgbox "$(w3m -dump "$current_url")" 200 100
        return
    else
        # add
        if [ $idx = 1 ] ; then
            rep=$(cat ~/.mybrowser/bookmark | gawk -v cur_link="$current_url" '{if(cur_link == $1) print $1}')
            if [ "$rep" != "" ] ; then
                dialog --title "Nae browser" --msgbox "This webpage is already in your bookmark." 20 100
                return
            fi
            echo "$current_url" >> ~/.mybrowser/bookmark
        # delete
        else
            menu=$(cat ~/.mybrowser/bookmark | gawk '{print NR " " $1}')
            idx=$(dialog --title "Nae browser" --menu "Bookmarks:" 200 100 200 `echo $menu` \
                3>&1 1>&2 2>&3 3>&-)
            if [ "$idx" = "" ] ; then
                dialog --title "Nae browser" --msgbox "$(w3m -dump "$current_url")" 200 100
            else
                echo "$(sed "$idx d" ~/.mybrowser/bookmark)" > ~/.mybrowser/bookmark 
            fi
        fi
    fi
}


# if the response is no or esc, give the leaving message
if [ $response = 1 -o $response = 255 ] ; then
    dialog --title "Apology" --msgbox "$leave_msg" 20 100

# if the response is yes, go to homepage
elif [ $response = 0 ] ; then 
    dialog --title "Nae browser" --msgbox "$(w3m -dump $homepage)" 200 100
    current_url=$homepage
    
    while : 
    do    
        user_input=$(dialog --title "Nae browser" --inputbox "$current_url" 20 100 \
            3>&1 1>&2 2>&3 3>&-) # if we do not include this command,
                                 # since the update of screen is by command output,
                                 # it will redirect in to $var, therefore the screen will be empty.

        # judge url if it's url, output to variable judge
        judge=$(echo "$user_input" |\
            gawk '{if(match($1,/(https?|ftp|file):\/\/([\da-z\.-]+)\.[a-z\.]{2,6}[-A-Za-z0-9\+&@#\/%=~_|\?\.]*/, a)) print a[0]; else print "False"}')
        
        # dubble check
        curl --head $judge -s > /dev/null 
        
        if [ $? = 0 ] ; then
            current_url=$(curl -sL -o /dev/null -w '%{url_effective}' $user_input)
            dialog --title "Nae browser" --msgbox "$(w3m -dump "$current_url")" 200 100
        elif [ "$user_input"  = "/S" -o "$user_input" = "/source" ] ; then
            src
        elif [ "$user_input" = "/H" -o "$user_input" = "/help" ] ; then
            help
        elif [ "$user_input" = "/L" -o "$user_input" = "/link" ] ; then
            link
            # extract link number
            idx=$(dialog --title "Nae browser" --menu "Links:" 200 100 200 `echo $link` \
                3>&1 1>&2 2>&3 3>&-)

            # if choosing cancel, back to inputbox
            if [ "$idx" = "" ] ; then
                dialog --title "Nae browser" --msgbox "$(w3m -dump "$current_url")" 200 100
                continue
            fi

            # change current page
            current_url=$(echo "$link" | grep "^$idx" | gawk -F '\n' '{sub(/^[1-9]\s/, "", $1) ; print $1}')
            current_url=$(echo "$current_url" | gawk '{if(!/.*\/$/) print $1 "/"; else print $1}')
            
            # deal with redirective url 
            current_url=$(curl -Ls -o /dev/null -w '%{url_effective}' $current_url)

            # open the changed page
            dialog --title "Nae browser" --msgbox "$(w3m -dump "$current_url")" 200 100
        elif [ "$user_input" = "/D" -o "$user_input" = "/download" ] ; then
            download
        elif [ "$user_input" = "/B" -o "$user_input" = "/bookmark" ] ; then
            bookmark
        elif [ "$user_input" = "" ] ; then
            break
        else
            dialog --title "Nae browser" --msgbox "Unknown command or wrong url!" 20 100
        fi

        # reset variable
        user_input=""
        judge=""
    done
    
fi
