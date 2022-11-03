#!/bin/bash

SCRIPT_PATH=$(dirname $(realpath -s $0))

docker run --rm \
  -v $SCRIPT_PATH/data:/data \
  -v $SCRIPT_PATH/src:/app \
  -v $SCRIPT_PATH/tesla:/tesla \
  -v $SCRIPT_PATH/alexa_remote_control:/alexa_remote_control \
   gridwatcher

