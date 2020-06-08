[![Build Status](https://travis-ci.org/desainis/simplek8s.svg?branch=master)](https://travis-ci.org/desainis/simplek8s)

- Credits: https://github.com/StephenGrider
- Check out his Awesome course on [Udemy](https://www.udemy.com/course/docker-and-kubernetes-the-complete-guide)!

# An Example of a Docker / Kubernetes Workflow

![Alt Text](demo.gif)

### Working with Docker
- Create seperate folders for your microservices (In this example, `client`=frontend, `server`=backend, `worker`=intermediary)
- Create your development Dockerfile (`Dockerfile.dev`)
- Create your production Dockerfile (`Dockerfile`)
  - In this case we use an nginx webserver in productio but not in development

### What about Docker Compose?
- Create a `docker-compose.yml` file that captures all of the different images needed for your application
- Specify build contexts in respective directions
- Specify environment variables
- Ensure you specify your volumes based on your project directory
- Ensure your application is restarted when changes to the source code are made. ([#nodemonIsAwesome](https://www.npmjs.com/package/nodemon))

<details>

```yaml
version: '3'
services:
  postgres:
    image: 'postgres:latest'
  redis:
    image: 'redis:latest'
  nginx:
    restart: always
    build:
      dockerfile: Dockerfile.dev
      context: ./nginx
    ports:
      - '3050:80'
  api:
    build:
      dockerfile: Dockerfile.dev
      context: ./server
    volumes:
      - /app/node_modules
      - ./server:/app
    environment:
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - PGUSER=postgres
      - PGHOST=postgres
      - PGDATABASE=postgres
      - PGPASSWORD=postgres_password
      - PGPORT=5432
  client:
    build:
      dockerfile: Dockerfile.dev
      context: ./client
    volumes:
      - /app/node_modules
      - ./client:/app
  worker:
    environment:
      - REDIS_HOST=redis
      - REDIS_PORT=6379
    build:
      dockerfile: Dockerfile.dev
      context: ./worker
    volumes:
      - /app/node_modules
      - ./worker:/app
```

</details>

### Test your Application
- When you're ready write your unit / functional tests

<details>

```js
import React from 'react';
import ReactDOM from 'react-dom';
import App from './App';

it('renders without crashing', () => {});

```

</details>


### Onwards to CI / CD (Travis)
- Create a travis account
- Download the travis CLI (Will be required for deployment to major cloud providers)
- Build your images and push to docker hub upon successful testing. 
- Optionally deploy your application to a cloud provider

<details>

```yaml
sudo: required
services:
  - docker

before_install:
  - docker build -t stephengrider/docker-react -f Dockerfile.dev .

script:
  - docker run stephengrider/docker-react npm run test -- --coverage

deploy:
  provider: elasticbeanstalk
  region: "us-west-2"
  app: "docker"
  env: "Docker-env"
  bucket_name: "elasticbeanstalk-us-west-2-306476627547"
  bucket_path: "docker"
  on:
    branch: master
  access_key_id: $AWS_ACCESS_KEY
  secret_access_key:
    secure: "$AWS_SECRET_KEY"
```

</details>

### Onwards to Kubernetes
- Install our handy dandy [Minikube](https://minikube.sigs.k8s.io/docs/start/)
- Run your first k8s commands
  - `kubectl get pods`
- Learn your kubernetes object basics
  - [Pods](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/)
  - [Services](https://kubernetes.io/docs/concepts/services-networking/service/)
  - [Volumes](https://kubernetes.io/docs/concepts/storage/volumes/)
  - [Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
  - [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- Learn about how to handle outside traffic using [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)

#### Write Some (Probably a lot) YAML
- For examples see the `k8s` folder. 

### Road to Production
- Choose a cloud provider (I prefer GKE). [Learn More](https://cloud.google.com/kubernetes-engine/) 
- Create your kubernetes cluster
- Create a service account for your kubernetes cluster and provide it admin permissions. [Learn More](https://cloud.google.com/kubernetes-engine/docs/tutorials/authenticating-to-cloud-platform)
- Encrypt this service account credentials and upload them to travis 
  - `travis encrypt-file <service-account-creds>.json -r <githubUserName>/<repo>`
  - Add command provided to your build (e.g. `openssl aes-256-cbc -K $encrypted_0c35eebf403c_key -iv $encrypted_0c35eebf403c_iv -in service-account.json.enc -out service-account.json -d`)
- Install [helm](https://helm.sh/) (Optional, but makes life much easier)
- Install ingress-nginx from helm
- Update your `.travis.yml` with a deploy script

<details>

```sh
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
```

</details>

- Commit some changes to your code and walk away. 
- If you're wondering what `$SHA` is, it is neat trick to tag your build images with the latest commit's SHA signature. (i.e. what you see when you run `git log`) It is used to identify when a new image is built and pushed to docker hub. The `latest` tag will not work from each push as it is not unique and kubernetes will not pick up any changes. (Neat right !?)

