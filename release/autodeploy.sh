#!/bin/bash

while true 
do

    #execmode: 0 -> normal high performance, 1 -> normal low power , 2 -> basic high performance, 3 -> basic low power
    declare -i execmode=0

    content=$( curl -g 'http://localhost:9090/api/v1/query?query=rate(istio_request_duration_milliseconds_sum{app="frontend",source_app="loadgenerator",response_code="200"}[2m])/rate(istio_request_duration_milliseconds_count{app="frontend",source_app="loadgenerator",response_code="200"}[2m])' )
    value=$( jq '.data.result[].value[1]' <<< "${content}" )
    valuea=$(echo $value | cut -c 2-)
    valuefd=$(echo $valuef | awk '{printf "%d", $1}')
    toint=$(($valuefd+0))

    if [ $toint -gt 100 && execmode==0 ]
    then
        bash normal-mode-lp.sh
        execmode=1
    else if [ $toint -gt 100 && execmode==1]
        then    
            bash basichp-mode.sh
            execmode=2
        else if [ $toint -gt 100 ]
            then   
                bash basiclp-mode.sh
                execmode=3
            fi
        fi
    fi

    echo "Next data fetched in 30 seconds ... execute mode %v"
    sleep 30

done

