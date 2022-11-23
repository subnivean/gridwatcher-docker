#!/bin/bash

SCRIPT_PATH=$(dirname $(realpath -s $0))

# Note that we need `--privileged` below to check for 
# the silencer dongle at `/dev/usb/` from inside 
# the container.
docker run --rm -it \
  --privileged \
  -v $SCRIPT_PATH/data:/data \
  -v $SCRIPT_PATH/src:/app \
  -v $SCRIPT_PATH/tesla:/tesla \
  -v $SCRIPT_PATH/alexa_remote_control:/alexa_remote_control \
   allinone-py311 /bin/bash

