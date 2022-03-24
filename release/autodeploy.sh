#!/bin/bash

echo "Deploying normal mode ..."
bash normal-mode-hp.sh
sleep 15


while true 
do

    #execmode: 0 -> normal high performance, 1 -> normal low power , 2 -> basic high performance, 3 -> basic low power
    declare -i execmode=0

    content=$( curl -g 'http://localhost:9090/api/v1/query?query=rate(istio_request_duration_milliseconds_sum{app="frontend",source_app="loadgenerator",response_code="200"}[1m])/rate(istio_request_duration_milliseconds_count{app="frontend",source_app="loadgenerator",response_code="200"}[1m])' )
    sleep 2
    value=$( jq '.data.result[].value[1]' <<< "${content}" )
    valuea=$(echo $value | cut -c 2-)
    valuefd=$(echo $valuea | awk '{printf "%d", $1}')
    toint=$(($valuefd+0))

    if [[ $toint -gt 100 && $execmode -eq 0 ]]
    then
        echo "Going into normal low power mode"
        bash normal-mode-lp.sh
        execmode=1
        echo "Waiting for pods to be re-deployed ..."
        sleep 15
    elif [[ $toint -gt 100 && $execmode -eq 1 ]]
     then    
        echo "Going into basic high performance mode"
        bash basichp-mode.sh
        execmode=2
        echo "Waiting for pods to be re-deployed ..."
        sleep 15
    elif [[ $toint -gt 100 && !($execmode -eq 3) && $execmode -eq 2 ]]
    then   
        echo "Going into basic low power mode"
        bash basiclp-mode.sh
        execmode=3
        echo "Waiting for pods to be re-deployed ..."
        sleep 15
    fi
    
    if [[ $toint -lt 100 && $execmode -eq 3 ]]
    then   
        echo "Going into basic high performance mode"
        bash basiclp-mode.sh
        execmode=2
        echo "Waiting for pods to be re-deployed ..."
        sleep 15
    elif [[ $toint -lt 100 && $execmode -eq 2 ]]
    then   
        echo "Going into normal low power mode"
        bash basiclp-mode.sh
        execmode=1
        echo "Waiting for pods to be re-deployed ..."
        sleep 15
    elif [[ $toint -lt 100 && $execmode -eq 1 ]]
    then   
        echo "Going into normal high performance mode"
        bash basiclp-mode.sh
        execmode=0
        echo "Waiting for pods to be re-deployed ..."
        sleep 15
    fi

    echo "Next data fetched in 30 seconds ... execute mode $execmode. Current latency $toint"
    sleep 30

done

