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