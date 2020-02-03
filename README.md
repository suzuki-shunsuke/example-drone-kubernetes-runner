Run Drone Kubernetes Runner at localhost

## Requirements

* [kind](https://github.com/kubernetes-sigs/kind)
* kubectl
* [Ngrok](https://ngrok.com/): to receive webhooks from GitHub
* GitHub account: to create a GitHub OAuth app
* [Helm](https://helm.sh/): to install MySQL
* (optional) [kubectx](https://github.com/ahmetb/kubectx) 
* (optoinal) [stern](https://github.com/wercker/stern)

## Note

Please be careful that temporarily we publish Drone with Ngrok.
We don't have any responsiblity.

We recommend to restrict users who can login Drone.

https://docs.drone.io/installation/security/registration/

Ngrok's URL is changed everytime `ngrok http`, so you have to reactivate repositories and remove old webhooks.

You can check the status of webhook and remove old webhooks from `https://github.com/<owner>/<repo>/settings/hooks` .

## Ngrok

Install Ngrok and create your account.

https://ngrok.com/

```
$ brew install cask ngrok
```

## Create a kubernetes cluster with kind

```
$ kind create cluster --name drone
$ kubectl create ns drone
$ kubens drone
```

## Watch logs with stern

It is useful for trouble shooting.

```
$ stern ".*"
```

## Install MySQL with Helm

https://github.com/helm/charts/tree/master/stable/mysql

```
$ bash scripts/install-mysql.sh
```

Connect MySQL.

```
$ kubectl exec -ti drone-mysql-??? mysql -- -u root -p drone
```

## Install Drone Server

* https://docs.drone.io/installation/providers/github/

### Create a GitHub OAuth App

Create a GitHub OAuth App from https://github.com/settings/applications/new

Homepage URL and Authorization callback URL are http://example.com . After we publish Drone with Ngrok, change these URLs.

### Create Kubernetes Secrets

* [DRONE_DATABASE_DATASOURDE](https://docs.drone.io/installation/reference/drone-database-datasource/)

```
$ echo -n '<GitHub OAuth App Client ID>' > secrets/drone-github-client-id
$ echo -n '<GitHub OAuth App Client Secret>' > secrets/drone-github-client-secret
$ echo -n '<Drone Database Datasource>' > secrets/drone-database-datasource
$ echo -n '<Drone RPC Secret>' > secrets/drone-rpc-secret
```

```
$ kubectl create secret generic drone-server \
  --from-file=secrets/drone-github-client-id \
  --from-file=secrets/drone-github-client-secret \
  --from-file=secrets/drone-database-datasource

$ kubectl create secret generic drone-server-rpc \
  --from-file=secrets/drone-rpc-secret
```

### Install Drone Server

Don't forget to update [DRONE_USER_FILTER](https://docs.drone.io/installation/reference/drone-user-filter/) of server.yaml before `kubectl apply`.
About the parameters, please see https://docs.drone.io/installation/reference/ .

```
$ kubectl apply -f server.yaml
```

You can confirm that database is migrated.

```
mysql> show tables;
+-------------------+
| Tables_in_drone   |
+-------------------+
| builds            |
| cron              |
| logs              |
| migrations        |
| nodes             |
| orgsecrets        |
| perms             |
| repos             |
| secrets           |
| stages            |
| stages_unfinished |
| steps             |
| users             |
+-------------------+
13 rows in set (0.00 sec)
```

## Install Drone Runner

* https://kube-runner.docs.drone.io/installation/installation/

About the parameters, please see https://kube-runner.docs.drone.io/installation/reference/ .

```
$ kubectl apply -f runner.yaml
```

## Publish Drone with Ngrok

```
$ kubectl port-forward svc/drone-server 4000:4000
```

```
$ ngrok http 4000
```

We recommend to use the URL not http but https.

Update the GitHub OAuth App's Homepage URL and Callback URL, and server.yaml's `DRONE_SERVER_HOST`.
The path of Callback URL is `/login`.

```
$ kubectl apply -f server.yaml
```

Note that you have to do these operations everytime you run `ngrok http` because Ngrok's URL is changed.

Then access to Drone from your web browser.

## Create a sample repository to run CI with Drone

https://kube-runner.docs.drone.io/configuration/overview/

.drone.yaml

Don't forget `type: kubernetes`.

```yaml
---
kind: pipeline
type: kubernetes
name: default
steps:
- name: hello
  image: alpine:3.10.3
  commands:
  - time 20
  - echo hello
```

You can confirm that the pod is running while the pipeline is running.

```
$ kubectl get pod
```
