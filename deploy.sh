docker build -t desainis/multi-client:latest -t desainis/multi-client:$SHA -f ./client/Dockerfile ./client
docker build -t desainis/multi-server:latest -t desainis/multi-server:$SHA -f ./server/Dockerfile ./server
docker build -t desainis/multi-worker:latest -t desainis/multi-worker:$SHA -f ./worker/Dockerfile ./worker
docker push desainis/multi-client:latest
docker push desainis/multi-server:latest
docker push desainis/multi-worker:latest

docker push desainis/multi-client:$SHA
docker push desainis/multi-server:$SHA
docker push desainis/multi-worker:$SHA

kubectl apply -f k8s
kubectl set image deployments/server-deployment server=desainis/multi-server:$SHA
kubectl set image deployments/client-deployment client=desainis/multi-client:$SHA
kubectl set image deployments/worker-deployment worker=desainis/multi-worker:$SHA