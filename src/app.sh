#!/bin/bash

. ./env

#$ALEXARC -e textcommand:"Turn off the bistro lights"

IP="$(grep 'IP=' $TESLA/secrets |cut -d'=' -f2)"

LOGINCMD=(curl -s -k -i
          -c $TESLA/cookie.txt
          -X POST
          -H "Content-Type: application/json"
          -d @$TESLA/creds.json
          https://$IP/api/login/Basic )

GSCMD="curl -s -k \
       -b $TESLA/cookie.txt \
        https://$IP/api/system_status/grid_status"

TIMESTAMP="$(TZ='America/New_York' date -I'seconds')"
# Note explicit conversion of numbers to base 10; otherwise
# they are interpreted as octal numbers, causing errors
# with '08' and '09'.
# Found fix at: https://stackoverflow.com/questions/24777597
HOUR=$((10#$(TZ="America/New_York" date "+%H")))
MIN=$((10#$(TZ="America/New_York" date "+%M")))

# Changed on 2021-12-15 - get new token every time.
# echo "Logging in..."
max_retry=5
counter=0
until "${LOGINCMD[@]}" |grep token >/dev/null
do
    sleep 5
    [[ counter -eq $max_retry ]] && echo "Failed!" && break
    #echo "Trying again. Try #$counter"
    ((counter++))
done

GSTATUS="$($GSCMD | jq -r '.grid_status')"

echo "$TIMESTAMP,$GSTATUS" >> $OUTFILE

if [[ "$GSTATUS" == "null" ]]  # Bad cookie? Or can't reach?
then
    # echo "$TIMESTAMP: Got a 'null'"
    sleep 10
    continue
fi

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
