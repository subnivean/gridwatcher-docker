#!/bin/bash

. ./env

#$ALEXARC -e textcommand:"Turn off the bistro lights"

# Settings for the machine that's getting and storing the
# Tesla gateway data
TESLADATAIP="192.168.1.10"
TESLADATAPATH="/home/pi/Tesla-docker/data/energy.sqlite"
TESLAQUERY="SELECT GridStatus FROM energy_data ORDER BY ROWID DESC LIMIT 1;"

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
        'This is your daily test of the Clowder Cove gridwatcherPEYE \
        system. This is only a test.'"
fi

if [ -d '/dev/usb/' ]; then SILENCER=true; else SILENCER=false; fi
if [[ "$GSTATUS" == "SystemGridConnected" ]]; then GRID=true; else GRID=false; fi

if ! $GRID
then
    if ! $SILENCER
    then
        # echo "$TIMESTAMP: Announcing grid down..."
        $ALEXARC -e "speak: \
            'Clowder Cove grid is down. SAAAAAD. Unplug the car if \
            its charging and turn off the heatpump to conserve the \
            Powerwall. You can turn on the gas heater if your ass \
            gets too cold. You can silence this message by plugging \
            any USB device into any USB port on the gridwatcherpeye.'"
    fi
else
    if $SILENCER
    then
        # echo "$TIMESTAMP: Announcing silencer reminder..."
        $ALEXARC -e "speak: \
            'This is a reminder. Clowder Cove grid is up. Remove the USB \
            silencer dongle from the gridwatcherpeye.'"
    fi
fi
