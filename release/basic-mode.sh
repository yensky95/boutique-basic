#!/bin/bash

adservice=$(kubectl get deployment adservice)
recommendationservice=$(kubectl get deployment recommendationservice)

if [ -n "$adservice" ]
then
    kubectl delete deployment adservice 
    kubectl delete svc adservice
fi

if [ -n "$recommendationservice" ]
then
    kubectl delete deployment recommendationservice 
    kubectl delete svc recommendationservice
fi

kubectl apply -f kubernetes-manifests-basic.yaml