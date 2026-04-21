## Explain CI/CD process.
We have a Git repository where our application’s source code is stored. In my case, this is a **Node.js frontend application**. As soon as a developer pushes code or raises a pull request to this repository, we have configured webhooks to trigger the Jenkins pipeline automatically.

We are using **declarative Jenkins pipelines**, and the pipeline runs on a **Kubernetes-based Jenkins agent**. Jenkins dynamically provisions a pod that contains multiple containers like Node, SonarQube scanner, Trivy, Kaniko, and Git tools. Each container is used for a specific stage of the pipeline, which makes the process efficient and isolated.

As part of this declarative pipeline, we run multiple stages.

The first stage is the **Checkout stage**, where Jenkins pulls the source code from the Git repository.

Next is the **Install Dependencies stage**. Inside the Node container, we install all the required dependencies using `npm ci` to ensure a clean and consistent setup.

After that, we have the **Unit Testing stage**, where we run `npm test` to validate that individual parts of the application are working correctly. This helps catch bugs early before moving forward.

If the tests pass, we move to the **Static Code Analysis stage using SonarQube**. Here, we scan the codebase to detect bugs, code smells, and maintainability issues.

Following this, we have a **Quality Gate stage**. Jenkins waits for the SonarQube result, and if the quality gate fails, the pipeline is immediately aborted. This ensures only high-quality code proceeds further.

Next, we perform a **Trivy File System Scan**. This scans the application source code and dependencies for vulnerabilities of HIGH and CRITICAL severity. A report is generated for visibility.

After that, we move to the **Build and Push stage using Kaniko**. Kaniko builds the Docker image from the Dockerfile inside the Kubernetes environment and pushes it to Docker Hub with both the build number tag and the latest tag.

Once the image is pushed, we run an **Image Scan using Trivy**. This scans the built container image for vulnerabilities. If any HIGH or CRITICAL vulnerabilities are found, the pipeline fails to prevent insecure images from being deployed.

After a successful image scan, we move to the **Update Helm Values stage**. Here, we update the image tag in the Helm values.yaml file using yq so that it points to the newly built image.

Finally, we have the **Git Commit and Push stage**, where we commit the updated Helm values file and push it back to the Git repository using stored credentials.

This completes our **Continuous Integration (CI)** process.

For the **Continuous Delivery (CD)** process, we are using a GitOps approach with Argo CD.

Here’s how it works:

* Once Jenkins updates the Helm values file with the new image tag and pushes it to Git, Argo CD continuously monitors this repository.
* As soon as it detects a change in the Helm values file, it pulls the updated manifests.
* Argo CD then deploys the new version of the application to the Kubernetes cluster automatically.


So in our setup, Jenkins is responsible for the entire CI pipeline — including build, test, security scanning, image creation, and updating deployment configuration — and Argo CD handles the deployment.

This is how we have implemented our **CI/CD pipeline using Jenkins and GitOps principles**.

To conclude, while my CI/CD pipeline is fully functional and follows a Kubernetes-native DevSecOps and GitOps approach, I understand that it is not yet fully production-grade.

There are a few improvements I would implement to make it enterprise-ready. For example, I currently use SonarQube and Trivy for code quality and vulnerability scanning, but I would extend this further by integrating dedicated SAST and DAST tools for deeper security coverage.

Right now, Jenkins is responsible for updating the Helm values file with the new image tag and pushing it to Git. While this works well, I could also introduce Argo Image Updater to decouple this responsibility from Jenkins and make the system more flexible and scalable.

Additionally, I would enhance the pipeline by adding centralized secrets management using HashiCorp Vault, along with proper monitoring and alerting mechanisms to improve observability and reliability.

## What is a Kubernetes-based Jenkins agent?
A Kubernetes-based Jenkins agent is a dynamic build environment where Jenkins creates a temporary pod in a Kubernetes cluster to run a pipeline, instead of using static build servers.

Each pipeline run gets its own isolated pod, which is automatically created at the start and deleted after the job finishes. This makes the system highly scalable, clean, and efficient.

In my project, I use a multi-container pod where different tools like Node, SonarQube scanner, Trivy, and Kaniko run in separate containers within the same pod, enabling a containerized and secure CI process.

## How does Jenkins create pods in Kubernetes?
Jenkins uses the Kubernetes plugin to communicate with the Kubernetes API server. When a pipeline starts, Jenkins reads the pod template defined in the Jenkinsfile and creates a pod accordingly. The pipeline stages then execute inside that pod, and once the job is complete, the pod is deleted.

## Why are you using Kaniko instead of Docker?
We use Kaniko instead of Docker because Docker requires a daemon that needs privileged access to the host system. In Kubernetes environments, this typically means running containers in privileged mode or mounting the Docker socket, both of which introduce serious security risks and break container isolation.

Kaniko solves this problem by building container images directly inside a container without requiring a Docker daemon or privileged access. It runs completely in user space, making it much more secure and suitable for Kubernetes-based CI pipelines.

In my project, since I’m using Kubernetes-based Jenkins agents, Kaniko allows me to build and push images securely within the pod itself without compromising cluster security.

## How does Kaniko build images without Docker?
Kaniko reads the Dockerfile and executes each instruction in user space. It creates filesystem layers by taking snapshots of changes after each step, without using a Docker daemon. Finally, it pushes the built image directly to a container registry.

## Where does Kaniko store image layers during build?
Kaniko stores intermediate layers inside the container’s filesystem while building. It uses a snapshotting mechanism to track file changes between Dockerfile steps and then pushes the final image layers to the registry.







### Step 1: Create OIDC Provider in Terraform
*Inside modules/eks/main.tf.*  
```
data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.eks_cluster.name
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.eks_cluster.name
}

resource "aws_iam_openid_connect_provider" "eks_oidc" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da0ecd2b6c3"]
}
```
*But when we will install Jenkins using Terraform, above two (data) will be shifted to root main.tf file.*   
*Also, if data is shifted to root main.tf file, then url will change to "url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer"*


### Step2: Create IAM Policy for ALB Controller
*Create a new file modules/eks/alb_iam.tf*  
```
resource "aws_iam_policy" "alb_controller_policy" {
  name = "${var.cluster_name}-AWSLoadBalancerControllerIAMPolicy"

  policy = file("${path.module}/iam_policy.json")
}
```

**Now download official policy file from inside modules/eks:**
```
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.11.0/docs/install/iam_policy.json
```

### Step3: Create IAM Role for Service Account (inside alb_iam.tf)
```
data "aws_iam_policy_document" "alb_assume_role_policy" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks_oidc.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub"

      values = [
        "system:serviceaccount:kube-system:aws-load-balancer-controller"
      ]
    }
  }
}

resource "aws_iam_role" "alb_controller_role" {
  name = "${var.cluster_name}-AmazonEKSLoadBalancerControllerRole"

  assume_role_policy = data.aws_iam_policy_document.alb_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "alb_attach" {
  role       = aws_iam_role.alb_controller_role.name
  policy_arn = aws_iam_policy.alb_controller_policy.arn
}
```

*If data is shifted to root main.tf file, then variable will change to -: variable = "${replace(aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer, "https://", "")}:sub"*

### Step4: Add Output (inside module/eks/outputs.tf)
```
output "alb_controller_role_arn" {
  value = aws_iam_role.alb_controller_role.arn
}
```

### Step 5: Add Output (inside EKS/outputs.tf)
```
output "alb_controller_role_arn" {
  value = module.eks.alb_controller_role_arn
}
```

### Step 6: Apply terraform

## Now bind this IAM role to Kubenetes using IRSA

### Step 1: Get the IAM Role ARN
```
terraform output alb_controller_role_arn
```

## Create Kubernetes Service Account (IIRSA Binding)
**Create a file in project root folder under k8/platform/aws-load-balancer-controller/serviceaccount.yaml**
```
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aws-load-balancer-controller
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: <IAM_ROLE_ARN>
```
*Now run*
```
kubectl apply -f k8/platform/aws-load-balancer-controller/serviceaccount.yaml
```

## Install AWS Load Balancer Controller

### Step 1: Add Helm Repo
```
helm repo add eks https://aws.github.io/eks-charts
helm repo update
```

### Step 2: Install AWS Load Balancer Controller
```
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=devsecops-eks-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=ap-south-1 \
  --set vpcId=<your-vpc-id>


```
arn:aws:iam::202749265471:role/devsecops-eks-cluster-AmazonEKSLoadBalancerControllerRole

## PHASE: Deploy your applications

### Step 1: Create Namespace
```
kubectl create ns argocd
kubectl create ns dev 
```
*This namespace should match the destination namespace of application.yaml files.*

### Step 2: Install Argocd
```
kubectl apply -n argocd   -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Step 2: Apply your Yamls
```
kubectl apply -f mongodb/application.yaml
kubectl apply -f backend/application.yaml
kubectl apply -f frontend/application.yaml
kubectl apply -f ingress.yaml
```

## Phase Install Jenkins using Terraform

### Step 1: Add Helm + Kubernetes Providers in Root providers.tf
```
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes = {
    host = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token = data.aws_eks_cluster_auth.cluster.token
  }
}
```

### Step 3: Create Jenkins Namespace via Terraform and Add Helm Release for Jenkins inside modules/jenkins/main.tf
```
resource "kubernetes_namespace_v1" "jenkins" {
  metadata {
    name = "jenkins"
  }
}

resource "helm_release" "jenkins" {
  name       = "jenkins"
  namespace  = kubernetes_namespace_v1.jenkins.metadata[0].name
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"

  values = [
    file("${path.module}/values.yaml")
  ]
}

```

### Step 4: Add this values.yaml in module/jenkins
```
controller:
  admin:
    createSecret: true
    username: admin
    password: admin123

  serviceType: ClusterIP

  resources:
    requests:
      cpu: "500m"
      memory: "512Mi"
    limits:
      cpu: "1"
      memory: "1Gi"

  installPlugins:
    - kubernetes
    - workflow-aggregator
    - git
    - configuration-as-code
    - credentials
    - sonar
    - docker-workflow

persistence:
  enabled: true
  size: 8Gi
  storageClass: gp2
```

### Step 5: Add this to root main.tf file
```
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

module "jenkins" {
  source = "./modules/jenkins"

  depends_on = [ module.eks ]
}
```

### Step 6: Run
```
terraform init
terraform apply
kubectl get pods -n jenkins
```

### Step 7: Expose jenkins using ingress. Create jenkins-ingress.yaml inside k8/jenkins
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: jenkins-ingress
  namespace: jenkins
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  ingressClassName: alb
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: jenkins
                port:
                  number: 8080
```

### Step 8: Run
```
kubectl apply -f jenkins-ingress.yaml
kubectl get ingress jenkins-ingress -n jenkins
kubectl get svc -n jenkins
```
*you will get a link like this "http://k8s-jenkins-jenkinsi-c237ef4fb5-316841084.ap-south-1.elb.amazonaws.com/" open in browser.*

## Add Sonarqube 

### Step 1: Create Sonarqube Namespace via Terraform and Add Helm Release for Sonarqube inside modules/sonarqube/main.tf
```
resource "kubernetes_namespace_v1" "sonarqube" {
  metadata {
    name = "sonarqube"
  }
}

resource "kubernetes_secret_v1" "sonarqube_monitoring" {
  metadata {
    name      = "sonarqube-monitoring"
    namespace = kubernetes_namespace_v1.sonarqube.metadata[0].name
  }

  data = {
    monitoringPasscode = base64encode("sonar123")
  }
}

resource "helm_release" "sonarqube" {
  name       = "sonarqube"
  namespace  = kubernetes_namespace_v1.sonarqube.metadata[0].name
  repository = "https://SonarSource.github.io/helm-chart-sonarqube"
  chart      = "sonarqube"

  values = [
    file("${path.module}/values.yaml")
  ]

  depends_on = [ kubernetes_secret_v1.sonarqube_monitoring ]
}

```

### Step 2: Add this values.yaml in module/sonarqube
```
community:
  enabled: true

image:
  repository: sonarqube
  tag: 25.12.0.117093-community
  pullPolicy: IfNotPresent

postgresql:
  enabled: true
  auth:
    username: sonar
    password: sonar
    database: sonarqube

persistence:
  enabled: true
  size: 10Gi
  storageClass: gp2

monitoringPasscodeSecretName: sonarqube-monitoring
monitoringPasscodeSecretKey: monitoringPasscode

resources:
  requests:
    cpu: "500m"
    memory: "1Gi"
  limits:
    cpu: "1"
    memory: "2Gi"
```

### Step 3: Add this to root main.tf file
```
module "sonarqube" {
  source = "./modules/sonarqube"

  depends_on = [ module.eks ]
}
```

### Step 4: Run
```
terraform init
terraform apply
kubectl get pods -n sonarqube
```

### Step 5: Expose sonarqube using ingress. Create sonarqube-ingress.yaml inside k8/sonarqube
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: sonarqube-ingress
  namespace: sonarqube
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  ingressClassName: alb
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: sonarqube-sonarqube
                port:
                  number: 9000

```

### Step 6: Run
```
kubectl apply sonarqube-ingress.yaml
kubectl get ingress sonarqube-ingress -n sonarqube
kubectl get svc -n sonarqube
```
*you will get a link like this "http://k8s-jenkins-jenkinsi-c237ef4fb5-316841084.ap-south-1.elb.amazonaws.com/" open in browser.*


### Step 7: Create Dockerhub secret for Kaniko
```
kubectl create secret docker-registry dockerhub-secret \
  --docker-username=<your-username> \
  --docker-password=<your-password> \
  --docker-email=<your-email> \
  -n jenkins

```

### Step 8: Run the pipeline

## Phase : Argocd application

### Create Argocd ingress under k8/argocd/argocd-ingress.yaml
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-ingress
  namespace: argocd
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/backend-protocol: HTTP
spec:
  ingressClassName: alb
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 80
```
kubectl apply argocd-ingress.yaml
kubectl get ingress -n argocd
kubectl get svc -n argocd

*this yaml is wrong. i used port forward here instead.*
```
kubectl port-forward svc/argocd-server -n argocd 8080:80
```


### Q. Why did i choose node as base image for 1st FROM stage and nginx for 2nd FROM stage?
I used **Node 16** in the first `FROM` stage because that stage’s purpose was to **build the application**, and Node images include the build tools, npm, and everything required to compile or bundle the app. The reason I don’t use that same image in production is because once the app is built, those tools are no longer needed — keeping them would only make the final image larger and increase the security surface.

Then in the second `FROM` stage, I used **`nginx:alpine`** because the purpose of that stage is only to **serve the built static files**, not to build anything. Nginx is lightweight and optimized for serving static content, and Alpine makes the image small and efficient. Since the build already happened in the first stage, the final image only needs a web server to run the compiled output.
