#!/bin/bash
# Script to switch from an extended display to a cloned or mirrored display.
# Can also switch workspaces at the same time, so one workspace is used in clone mode and the other in extended mode.
# Requires xrandr and wmctrl. Written for Gnome on Fedora 19.
#
# Author: Katie Miller (codemiller)

# Internal output
INT=LVDS1
# External output
EXT=DP1
# Extend direction
EXD_DIR=right
# Extended workspace 
EXD_WSPACE=1
# Cloned/mirrored workspace
CLONE_WSPACE=2

hash xrandr 2>/dev/null || { echo >&2 "Error: xrandr not found"; exit 1; }
hash wmctrl 2>/dev/null || { echo >&2 "Error: wmctrl not found"; exit 1; }

if [[ $EXD_DIR != "left" && $EXD_DIR != "right" &&
      $EXD_DIR != "above" && $EXD_DIR != "below" ]]; then
    echo "Error: Extend direction must be left, right, above or below"
    exit 1 
fi
         
get_state() {
    local OUTPUT=$1
    local STATE=$(xrandr | grep $OUTPUT)

    if [[ $STATE =~ [0-9]+x[0-9]+\+0\+0 ]]; then 
        echo on_clone
    elif [[ $STATE =~ [0-9]+x[0-9]+ ]]; then 
        echo on_exd
    else
        echo off
    fi
}

get_workspace() {
    local DESKTOP_STRING=$(xprop -root -notype _NET_CURRENT_DESKTOP)
    local DESKTOP_NUM=$([[ $DESKTOP_STRING =~ ([0-9]+)$ ]] && echo $BASH_REMATCH)  
    if [[ ! $DESKTOP_NUM =~ [0-9]+ ]]; then
        echo "Current workspace could not be detected"
        exit 1
    fi
    # Desktop numbers are zero-indexed, whereas workspaces are not
    echo $(($DESKTOP_NUM + 1))
}

switch_workspace() {
    local CURRENT=$1
    local TARGET_WSPACE=$2
    
    if [[ $CURRENT -ne $TARGET_WSPACE ]]; then
        echo "$TARGET"
        wmctrl -s $(($TARGET_WSPACE - 1)) 
    fi
}

EXT_STATE=$(get_state $EXT)
CURRENT_WSPACE=$(get_workspace)

if [[ $EXT_STATE = "on_clone" ]]; then
    # Toggle to extended mode    
    switch_workspace $CURRENT_WSPACE $EXD_WSPACE   
    if [[ $EXD_DIR = "left" || $EXD_DIR = "right" ]]; then
        xrandr --output $INT --auto --output $EXT --auto --$EXD_DIR-of $INT
    else
        xrandr --output $INT --auto --output $EXT --auto --$EXD_DIR $INT
    fi
elif [[ $EXT_STATE = "on_exd" ]]; then
    # Toggle to clone mode
    switch_workspace $CURRENT_WSPACE $CLONE_WSPACE
    xrandr --output $INT --auto --output $EXT --auto --same-as $INT 
else 
    echo "No external display detected"
fi

exit 0
