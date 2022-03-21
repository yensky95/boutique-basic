adservice=$(kubectl get deployment adservice)
recommendationservice=$(kubectl get deployment recommendationservice)

if [ -z "$adservice"]
then
    kubectl delete deployment adservice 
    kubectl delete svc adservice
else
fi

if [ -z "$recommendationservice"]
then
    kubectl delete deployment recommendationservice 
    kubectl delete svc recommendationservice
else
fi

kubectl apply -f kubernetes-manifest-basic