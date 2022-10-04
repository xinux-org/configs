#!/usr/bin/zsh

INSTALLED=$(pacman -Q linux)
UPGRADE=$(pacman -Qu linux)

updates=$(paru -Qu > /dev/null | wc -l)

if [ $UPGRADE ]
then
    LEN=$(echo `expr $(echo $INSTALLED | wc -c) + 4`)
    OLD_VERSION=`echo $INSTALLED | cut -c 7-`
    NEW_VERSION=`echo $UPGRADE | cut -c $LEN-`

    if [[ $(echo $OLD_VERSION | cut -c -4) == $(echo $NEW_VERSION | cut -c -4) ]]
    then
        kernel_update="%{F#ffca28}$NEW_VERSION"  # linux 5.19.x
    else
        if [ $(echo $OLD_VERSION | cut -c -1) = $(echo $NEW_VERSION | cut -c -1) ]
        then
            kernel_update="%{F#ff9800}$NEW_VERSION"  # linux 5.x.x
        else
            kernel_update="%{F#A54242}$NEW_VERSION"  # major update, in case of linux kernel 6.x.x
        fi
    fi

    if [[ $updates == "0" ]]
    then
        update=" $kernel_update"
    else
        update=" $updates  $kernel_update"
    fi
else
    kernel_update=""
    if [[ $updates == "0" ]]
    then
        update=""
    else
        update=" $updates"
    fi
fi

echo $update
