#!/bin/sh

for i in $(seq 1 100); do
    cat /dev/sockn | awk 'BEGIN{output=""}
                          {if(NR>1){output=output "," $0}
                           else {output=output $0}
                          }
                          END{print output}'
    sleep 1
done