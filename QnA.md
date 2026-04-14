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





