FROM python:3.10

# Tip from https://stackoverflow.com/questions/63892211
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive \
    apt-get install --no-install-recommends --assume-yes \
      jq

# Easiest to just do a `. ~/.bash_aliases to get handy shortcuts
COPY bash.bash_aliases .bash_aliases

WORKDIR /app
COPY ./src .

# Create storage directory for database
RUN mkdir /data
RUN mkdir /tesla
RUN mkdir /alexa_remote_control

CMD ["/bin/bash", "app.sh"]
