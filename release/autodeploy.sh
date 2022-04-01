#!/bin/bash
#TO RUN
#prometheus deployment running on http://localhost:9090 and being inside /boutique-basic/release/ folder 

echo "Deploying normal mode ..."
bash normal-mode-hp.sh
echo "------------------"
sleep 15


#execmode: 0 -> normal high performance, 1 -> normal low power , 2 -> basic high performance, 3 -> basic low power
declare -i execmode=0
declare -i i=0
declare -i lock=0
declare -i lockvar=0

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
    echo "Throughput: $ttoint rpm" >> data.txt
    echo "Latency value: $toint ms" >> data.txt
    echo "ExecutionMode: $execmode" >> data.txt
    #log on cmd 
    echo "Throughput: $ttoint rpm"
    echo "Latency value: $toint ms"
    echo "Lock var: $lockvar, Lock: $lock"

    if [[ $toint -gt 100 && $execmode -eq 0 && lock -eq 0 ]]
    then
        echo "Going into normal low power mode"
        bash normal-mode-lp.sh
        execmode=1
        lock=1
        echo "Waiting for pods to be re-deployed ..."
        sleep 15
    elif [[ $toint -gt 100 && $execmode -eq 1 && lock -eq 0 ]]
     then    
        echo "Going into basic high performance mode"
        bash basichp-mode.sh
        execmode=2
        lock=1
        echo "Waiting for pods to be re-deployed ..."
        sleep 15
    elif [[ $toint -gt 100 && !($execmode -eq 3) && $execmode -eq 2 && lock -eq 0 ]]
    then   
        echo "Going into basic low power mode"
        bash basiclp-mode.sh
        execmode=3
        lock=1
        echo "Waiting for pods to be re-deployed ..."
        sleep 15
    fi
    
    if [[ $toint -lt 50 && $execmode -eq 3 && lock -eq 0 ]]
    then   
        echo "Going into basic high performance mode"
        bash basichp-mode.sh
        execmode=2
        lock=1
        echo "Waiting for pods to be re-deployed ..."
        sleep 15
    elif [[ $toint -lt 55 && $execmode -eq 2 && lock -eq 0 ]]
    then   
        echo "Going into normal low power mode"
        bash normal-mode-lp.sh
        execmode=1
        lock=1
        echo "Waiting for pods to be re-deployed ..."
        sleep 15
    elif [[ $toint -lt 60 && $execmode -eq 1 && lock -eq 0 ]]
    then   
        echo "Going into normal high performance mode"
        bash normal-mode-hp.sh
        execmode=0
        lock=1
        echo "Waiting for pods to be re-deployed ..."
        sleep 15
    fi

    if [ $lock -eq 1 && lockvar -lt 4 ]
    then
        lockvar=lockvar+1
    elif [ $lock -eq 1 ]
        lock=0
        lockvar=0
    fi

    i=i+1
    echo "Next data fetched in 30 seconds ... execute mode $execmode."
    echo "------------------"
    sleep 30

done

