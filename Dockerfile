FROM alpine:3.19

# -----------------------------
# Base utilities
# -----------------------------
RUN apk add --no-cache \
    git \
    openssh \
    ca-certificates \
    curl \
    bash \
    nodejs \
    npm \
    openjdk17-jre \
    docker-cli

# -----------------------------
# yq
# -----------------------------
RUN wget -q https://github.com/mikefarah/yq/releases/download/v4.44.3/yq_linux_amd64 \
    -O /usr/local/bin/yq && chmod +x /usr/local/bin/yq

# -----------------------------
# Helm
# -----------------------------
RUN wget -q https://get.helm.sh/helm-v3.14.2-linux-amd64.tar.gz && \
    tar -xzf helm-v3.14.2-linux-amd64.tar.gz && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    rm -rf helm-v3.14.2-linux-amd64.tar.gz linux-amd64

# -----------------------------
# Trivy
# -----------------------------
RUN wget -q https://github.com/aquasecurity/trivy/releases/download/v0.49.1/trivy_0.49.1_Linux-64bit.tar.gz && \
    tar -xzf trivy_0.49.1_Linux-64bit.tar.gz && \
    mv trivy /usr/local/bin/trivy && \
    rm trivy_0.49.1_Linux-64bit.tar.gz

# -----------------------------
# Sonar Scanner
# -----------------------------
RUN wget -q https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip && \
    unzip sonar-scanner-cli-5.0.1.3006-linux.zip && \
    mv sonar-scanner-5.0.1.3006-linux /opt/sonar-scanner && \
    ln -s /opt/sonar-scanner/bin/sonar-scanner /usr/local/bin/sonar-scanner && \
    rm sonar-scanner-cli-5.0.1.3006-linux.zip

ENV JAVA_HOME=/usr/lib/jvm/default-jvm
ENV PATH="$PATH:/opt/sonar-scanner/bin"

ENTRYPOINT ["/bin/bash"]
