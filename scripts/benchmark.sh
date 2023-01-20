#!/bin/bash

set -eu;

terraform output -json | jq '.[].value'| sed 's/"//g' | sed 's/$/\//' > urls.txt;

for url in $(cat urls.txt); do
  echo "************ LATENCY TEST FOR $url ******************" >> benchmark$(date +"_%Y.%m.%d-%H.%M").txt;
  ab "$url" >> benchmark$(date +"_%Y.%m.%d-%H.%M").txt;
done