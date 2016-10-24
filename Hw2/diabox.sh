#!/bin/sh 

export LC_CTYPE='zh_TW.UTF-8'
[ -d ~/.mybrowser/ ]
if [ $? == 1 ] ; then
    mkdir ~/.mybrowser/ 
fi

touch ~/.mybrowser/bookmark 
touch ~/.mybrowser/error 
touch ~/.mybrowser/userterm 
touch ~/.mybrowser/help 

{
echo "Do you like to play CTF?" > ~/.mybrowser/userterm 
echo "URL => go to the URL
/S => show the current page source code
/L => show all links in current page
/B => add or delete bookmark
/H => Help
/P => previous page
/N => next page" > ~/.mybrowser/help 

# build prev_page and next_page
touch ~/.mybrowser/prev_page 
touch ~/.mybrowser/next_page


dialog --title "Terms and conditions of Use" --yesno "`cat ~/.mybrowser/userterm`" 200 100

response=$?

leave_msg="Sorry, you can't use nae browser if you don't like CTF."

homepage="https://www.google.co.uk/" 
current_url=""

src () { # dump source to the dialog msgbox
    curl -sL $current_url > tmp
    if [ $(file -b --mime-encoding tmp) == "iso-8859-1" ] ; then
        echo $(iconv -f BIG-5 -t UTF-8 tmp) > tmp
    fi
    dialog --title "Nae browser" --msgbox "$(cat tmp)" 200 100
    rm -f tmp
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
    idx=$(dialog --title "Nae browser" --output-fd 1 --menu "Downloads:" 200 100 200 `echo $link`)
    # if canceled, back to current page
    if [ "$idx" = "" ] ; then
        dialog --title "Nae browser" --msgbox "$(w3m -dump "$current_url")" 200 100
        return
    fi
    wget "$(echo "$link" | grep "^$idx " | gawk -F '\n' '{sub(/^[1-9]\s/, "", $1) ; print $1}')" -P ~/Downloads/
}

bookmark () {
    while : 
    do
        # clean empty line
        grep -v '^$' ~/.mybrowser/bookmark > tmp
        cat tmp > ~/.mybrowser/bookmark
        rm -f tmp
        menu=$(echo "Add_a_bookmark"; echo "Delete_a_bookmark"; cat ~/.mybrowser/bookmark)
        menu=$(echo "$menu" | gawk '{print NR " " $1}') 
        idx=$(dialog --title "Nae browser" --output-fd 1 --menu "Bookmarks:" 200 100 200 `echo $menu`)
        if [ "$idx" = "" ] ; then
            dialog --title "Nae browser" --msgbox "$(w3m -dump "$current_url")" 200 100
            return
        elif [ "$idx" -gt 2 ] ; then
            echo "$current_url" >> ~/.mybrowser/prev_page
            idx=$(( $idx-2 ))
            current_url=$(sed -n "$idx p" ~/.mybrowser/bookmark)
            dialog --title "Nae browser" --msgbox "$(w3m -dump "$current_url")" 200 100
            return
        else
            # add
            if [ $idx = 1 ] ; then
                rep=""
                rep=$(cat ~/.mybrowser/bookmark | gawk -v cur_link="$current_url" '{if(cur_link == $1) print $1}')
                if [ "$rep" != "" ] ; then
                    dialog --title "Nae browser" --msgbox "This webpage is already in your bookmark." 20 100
                    continue
                fi
                echo "$current_url" >> ~/.mybrowser/bookmark
            # delete
            else
                menu=$(cat ~/.mybrowser/bookmark | gawk '{print NR " " $1}')
                idx=$(dialog --title "Nae browser" --output-fd 1 --menu "Bookmarks:" 200 100 200 `echo $menu`)
                if [ "$idx" = "" ] ; then
                    dialog --title "Nae browser" --msgbox "$(w3m -dump "$current_url")" 200 100
                else
                    line=$(( $line+1 ))
                    echo "$(sed "$idx d" ~/.mybrowser/bookmark)" > ~/.mybrowser/bookmark
                fi
            fi
        fi
    done
}

prevp () {
    idx=$(awk 'END{print NR}' ~/.mybrowser/prev_page)
    if [ "$idx" = 0 ] ; then
        dialog --title "Nae browser" --msgbox "Nope" 20 100
        return
    fi
    echo "$current_url" >> ~/.mybrowser/next_page
    # change page to previous page
    current_url=$(tail -1 ~/.mybrowser/prev_page)
    dialog --title "Nae browser" --msgbox "$(w3m -dump $current_url)" 200 100

    # refresh file prev_page
    idx=$(awk 'END{print NR}' ~/.mybrowser/prev_page)
    if [ "$idx" = 1 ] ; then
        cp /dev/null ~/.mybrowser/prev_page
        return
    fi
    echo "$(sed "$idx d" ~/.mybrowser/prev_page)" > ~/.mybrowser/prev_page 
}

nextp () {
    idx=$(awk 'END{print NR}' ~/.mybrowser/next_page)
    if [ "$idx" = 0 ] ; then
        dialog --title "Nae browser" --msgbox "Nope" 20 100
        return
    fi
    echo "$current_url" >> ~/.mybrowser/prev_page 
    # change page to next page
    current_url=$(tail -1 ~/.mybrowser/next_page)
    dialog --title "Nae browser" --msgbox "$(w3m -dump $current_url)" 200 100

    # refresh file next_page
    idx=$(awk 'END{print NR}' ~/.mybrowser/next_page)
    if [ "$idx" = 1 ] ; then
        cp /dev/null ~/.mybrowser/next_page 
        return
    fi
    echo "$(sed "$idx d" ~/.mybrowser/next_page)" > ~/.mybrowser/next_page 
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
        user_input=$(dialog --title "Nae browser" --output-fd 1 --inputbox "$current_url" 20 100)
        
        # if canceled, break
        if [ $? == 1 ] ; then
            break
        fi
        # shell cmd judge 
        sh_cmd="$(echo "$user_input" | gawk -F '\n' '{if(sub(/^!/, "", $1)) print $1}')"
        if [ "$sh_cmd" != "" ] ; then
            result=""
            result=$(eval $sh_cmd)
            if [ "$result" != "" ] ; then 
                dialog --title "Nae browser" --msgbox "$(printf "%s" "$result")" 200 100 # use format to prevent misunderstand about '-'
            else 
                dialog --title "Nae browser" --msgbox "Wrong command" 200 100
            fi
            dialog --title "Nae browser" --msgbox "$(w3m -dump "$current_url")" 200 100 
            continue
        fi

        # judge url if it's url, output to variable judge
        judge=$(echo "$user_input" |\
            gawk '{match($1,/(https?:\/\/)?([\da-z\.-]+)\.[a-z\.]{2,6}[-A-Za-z0-9\+&@#\/%=~_|\?\.]*/, a); if(length($1) == length(a[0])) print a[0]; else print "False"}')
        
        # dubble check
        curl --head $judge -s > /dev/null 
        
        if [ $? = 0 ] ; then
            echo "$current_url" >> ~/.mybrowser/prev_page
            current_url=$(curl -sL -o /dev/null -w '%{url_effective}' $user_input)
            dialog --title "Nae browser" --msgbox "$(w3m -dump "$current_url")" 200 100
        elif [ "$user_input"  = "/S" -o "$user_input" = "/source" ] ; then
            src
        elif [ "$user_input" = "/H" -o "$user_input" = "/help" ] ; then
            help
        elif [ "$user_input" = "/L" -o "$user_input" = "/link" ] ; then
            link
            # extract link number
            idx=$(dialog --title "Nae browser" --output-fd 1 --menu "Links:" 200 100 200 `echo $link`)

            # if choosing cancel, back to inputbox
            if [ "$idx" = "" ] ; then
                dialog --title "Nae browser" --msgbox "$(w3m -dump "$current_url")" 200 100
                continue
            fi
            
            # change current page
            echo "$current_url" >> ~/.mybrowser/prev_page
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
        elif [ "$user_input" = "/P" -o "$user_input" = "/previous" ] ; then
            prevp
        elif [ "$user_input" = "/N" -o "$user_input" = "/next" ] ; then
            nextp
        else
            dialog --title "Nae browser" --msgbox "Unknown command or wrong url!" 20 100
        fi

        # reset variable
        user_input=""
        judge=""
    done
    
fi

# delete page record
rm ~/.mybrowser/next_page
rm ~/.mybrowser/prev_page 
} 2> ~/.mybrowser/error
