#!/bin/bash
#TO RUN
#prometheus deployment running on http://localhost:9090 and being inside /boutique-basic/release/ folder 

echo "Deploying normal mode ..."
bash normal-mode-hp.sh
sleep 15


#execmode: 0 -> normal high performance, 1 -> normal low power , 2 -> basic high performance, 3 -> basic low power
declare -i execmode=0
declare -i i=0

while true 
do

    echo "-----Cycle $i-----" >> data.txt
    #Response Time calculation
    content=$( curl -g 'http://localhost:9090/api/v1/query?query=rate(istio_request_duration_milliseconds_sum{app="frontend",source_app="loadgenerator",response_code="200"}[1m])/rate(istio_request_duration_milliseconds_count{app="frontend",source_app="loadgenerator",response_code="200"}[1m])' )
    value=$( jq '.data.result[].value[1]' <<< "${content}" )
    valuea=$(echo $value | cut -c 2-)
    valuefd=$(echo $valuea | awk '{printf "%d", $1}')
    toint=$(($valuefd+0))

    #Throughput calculation
    content=$( curl -g 'http://localhost:9090/api/v1/query?query=sum(rate(istio_request_duration_milliseconds_count{app="frontend"}[1m]))' )
    valuet=$( jq '.data.result[].value[1]' <<< "${content}" )
    valueta=$(echo $valuet | cut -c 2-)
    valuetfd=$(echo $valueta | awk '{printf "%d", $1}')
    ttoint=$(($valuetfd+0))

    #data copied in the txt file
    kubectl top pods >> data.txt
    echo "Throughput (kps - kilobit per sec): $ttoint" >> data.txt
    echo "Latency value: $toint" >> data.txt
    echo "------------------" >> data.txt
    #log on cmd 
    echo "Throughput (kps - kilobit per sec): $ttoint"
    echo "Latency value: $toint"

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
        bash basichp-mode.sh
        execmode=2
        echo "Waiting for pods to be re-deployed ..."
        sleep 15
    elif [[ $toint -lt 100 && $execmode -eq 2 ]]
    then   
        echo "Going into normal low power mode"
        bash normal-mode-lp.sh
        execmode=1
        echo "Waiting for pods to be re-deployed ..."
        sleep 15
    elif [[ $toint -lt 100 && $execmode -eq 1 ]]
    then   
        echo "Going into normal high performance mode"
        bash normal-mode-hp.sh
        execmode=0
        echo "Waiting for pods to be re-deployed ..."
        sleep 15
    fi

    i=$($i+1)
    echo "Next data fetched in 30 seconds ... execute mode $execmode."
    sleep 30

done

