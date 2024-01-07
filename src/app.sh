#!/bin/bash

. ./env

#$ALEXARC -e textcommand:"Turn off the bistro lights"

# Settings for the machine that's getting and storing the
# Tesla gateway data
TESLADATAIP="192.168.1.10"
TESLADATAPATH="/home/pi/Tesla-docker/data/energy.sqlite"
TESLAQUERY="SELECT GridStatus FROM energy_data ORDER BY ROWID DESC LIMIT 1;"
TIMERFILE=_timer.tmp

TIMESTAMP="$(TZ='America/New_York' date -I'seconds')"

# Note explicit conversion of numbers to base 10; otherwise
# they are interpreted as octal numbers, causing errors
# with '08' and '09'.
# Found fix at: https://stackoverflow.com/questions/24777597
HOUR=$((10#$(TZ="America/New_York" date "+%H")))
MIN=$((10#$(TZ="America/New_York" date "+%M")))

cmd="ssh -q -i /app/id_rsa_rpi \
         -o StrictHostKeyChecking=no \
         -l pi \
         $TESLADATAIP \
            sqlite3 -readonly $TESLADATAPATH '$TESLAQUERY' \
    "

GSTATUS=$($cmd)

#echo "$TIMESTAMP,$GSTATUS" >> $OUTFILE

# Make sure we got a response from the Tesla Gateway.
if [[ "$GSTATUS" == "" ]]
then
    # echo "$TIMESTAMP: Announcing network drop..."
    $ALEXARC -e "speak: \
        'It looks like the Tesla gateway has dropped off \
        the network. I'll try again in a few minutes, or \
        you can go out on the porch, open the large cover, \
        and push the reset button with a pencil'"
fi

if [[ $HOUR -eq 19 && $MIN -eq 13 ]]
then
    # echo "$TIMESTAMP: Announcing test..."
    $ALEXARC -e "speak: \
        'This is your daily test of the Clowder Cove gridwatcherPEYE system.'"
fi

if [ -d '/dev/usb/' ]; then SILENCER=true; else SILENCER=false; fi

# Negate sense for test
if [[ "$GSTATUS" == "SystemGridConnected" ]]; then GRID=true; else GRID=false; fi
#if [[ "$GSTATUS" != "SystemGridConnected" ]]; then GRID=true; else GRID=false; fi

if [ -f $TIMERFILE ]
then
    now=$(date '+%s')
    age=$(date '+%s' -r $TIMERFILE)
    let AGEOFTIMERFILE=$now-$age
else
    AGEOFTIMERFILE=0
fi

# echo "AGEOFTIMERFILE: $AGEOFTIMERFILE"
# echo "SILENCER: $SILENCER"

if ! $GRID
then
    if [[ $SILENCER = false && ( $AGEOFTIMERFILE -eq 0 || $AGEOFTIMERFILE -gt 5 ) ]]
    then
        # echo "$TIMESTAMP: Announcing grid down..."
        $ALEXARC -e "speak: \
            'Clowder Cove grid is down. SAAAAAD. Unplug the car if \
            its charging and turn off the heatpump and any space \
            heaters to conserve the Powerwall. \
            You can turn on the gas heater if it \
            gets too cold. You can silence this message by plugging \
            any USB device into any USB port on the gridwatcherpeye.'"
    # else
    #     echo "$TIMESTAMP: Waiting for timeout..."
    fi

    # Touch a flag file to use as a 5-minute timer
    # to allow for reboot time after a 'blip'.
    if [ ! -f $TIMERFILE ]
    then
        touch $TIMERFILE
    fi

else
    # Remove timer file if present
    if [ -f $TIMERFILE ]
    then
        rm -f $TIMERFILE
    fi

    if $SILENCER
    then
        # echo "$TIMESTAMP: Announcing silencer reminder..."
        $ALEXARC -e "speak: \
            'This is a reminder. Clowder Cove grid is up. Remove the USB \
            silencer dongle from the gridwatcherpeye.'"
    # else
    #     echo "$TIMESTAMP: Grid is up (no announcement)..."
    fi
fi
