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

#data formatting csv
echo "ResponseTime Throughput PowerConsumption" >> data.txt 

while true 
do

    echo "-----Cycle $i-----" >> datatop.txt
    #Response Time calculation
    content=$( curl -g 'http://localhost:9090/api/v1/query?query=rate(istio_request_duration_milliseconds_sum{app="frontend",source_app="loadgenerator",response_code="200"}[30s])/rate(istio_request_duration_milliseconds_count{app="frontend",source_app="loadgenerator",response_code="200"}[30s])' )
    value=$( jq '.data.result[].value[1]' <<< "${content}" )
    valuea=$(echo $value | cut -c 2-)
    valuefd=$(echo $valuea | awk '{printf "%d", $1}')
    toint=$(($valuefd+0))

    #Throughput calculation
    content=$( curl -g 'http://localhost:9090/api/v1/query?query=sum(rate(istio_request_duration_milliseconds_count{app="frontend"}[30s]))' )
    valuet=$( jq '.data.result[].value[1]' <<< "${content}" )
    valueta=$(echo $valuet | cut -c 2-)
    valuetfd=$(echo $valueta | awk '{printf "%d", $1}')
    ttoint=$(($valuetfd+0))

    #CPU power consumption
    totcpu=$( kubectl top pods | grep Mi | grep -v "loadgenerator" | awk 'NR > 1 {sum+=$2;}END{print sum;}' )
    totcpucomp=$((totcpu*84))
    totcpup=$( echo $(( $totcpu * 84 / 100 )) | sed -e 's/..$/.&/;t' -e 's/.$/.0&/' )
    totcpupscaled=$( echo $(( $totcpu * 84 / 10 )) | sed -e 's/..$/.&/;t' -e 's/.$/.0&/' )

    #data copied in the txt file
    kubectl top pods >> datatop.txt
    echo "-------" >> datatop.txt
    echo "Throughput: $ttoint rpm" >> datatop.txt
    echo "Response Time: $toint ms" >> datatop.txt
    echo "ExecutionMode: $execmode" >> datatop.txt
    echo "CPU power consumption: $totcpup" >> datatop.txt
    #formatted txt for csv
    echo "$toint $ttoint $totcpupscaled" >> data.txt

    #log on cmd 
    echo "Throughput: $ttoint rpm"
    echo "Latency value: $toint ms"
    echo "CPU power consumption: $totcpup"
    echo "Lock var: $lockvar, Lock: $lock"

    if [[ $toint -gt 100 && $execmode -eq 0 && $lock -eq 0 ]] || [[ $execmode -eq 0 && $totcpucomp -gt 70000 && $lock -eq 0 ]];
    then
        echo "Going into normal low power mode"
        bash normal-mode-lp.sh
        execmode=1
        lock=1
        echo "Waiting for pods to be re-deployed ..."
        sleep 25
    elif [[ $toint -gt 100 && $execmode -eq 1 && $lock -eq 0 ]] || [[ $execmode -eq 1 && $totcpucomp -gt 70000 && $lock -eq 0 ]];
     then    
        echo "Going into basic high performance mode"
        bash basichp-mode.sh
        execmode=2
        lock=1
        echo "Waiting for pods to be re-deployed ..."
        sleep 25
    elif [[ $toint -gt 100 && !($execmode -eq 3) && $execmode -eq 2 && $lock -eq 0 ]] || [[ $execmode -eq 2 && $totcpucomp -gt 70000 && !($execmode -eq 3) && $lock -eq 0 ]];
    then   
        echo "Going into basic low power mode"
        bash basiclp-mode.sh
        execmode=3
        lock=1
        echo "Waiting for pods to be re-deployed ..."
        sleep 25
    fi
    
    if [[ $toint -lt 50 && $execmode -eq 3 && $lock -eq 0 ]] || [[ $execmode -eq 3 && $totcpucomp -lt 48000 && $lock -eq 0 ]];
    then   
        echo "Going into basic high performance mode"
        bash basichp-mode.sh
        execmode=2
        lock=1
        echo "Waiting for pods to be re-deployed ..."
        sleep 25
    elif [[ $toint -lt 55 && $execmode -eq 2 && $lock -eq 0 ]] || [[ $execmode -eq 2 && $totcpucomp -lt 50000 && $lock -eq 0 ]];
    then   
        echo "Going into normal low power mode"
        bash normal-mode-lp.sh
        execmode=1
        lock=1
        echo "Waiting for pods to be re-deployed ..."
        sleep 25
    elif [[ $toint -lt 60 && $execmode -eq 1 && $lock -eq 0 ]] || [[ $execmode -eq 1 && $totcpucomp -lt 53000 && $lock -eq 0 ]];
    then   
        echo "Going into normal high performance mode"
        bash normal-mode-hp.sh
        execmode=0
        lock=1
        echo "Waiting for pods to be re-deployed ..."
        sleep 25
    fi

    if [[ $lock -eq 1 && $lockvar -lt 4 ]];
    then
        lockvar=lockvar+1
    elif [ $lock -eq 1 ]
    then
        lock=0
        lockvar=0
    fi

    i=i+1
    echo "Next data fetched in 30 seconds ... execute mode $execmode."
    echo "------------------"
    sleep 30

done

