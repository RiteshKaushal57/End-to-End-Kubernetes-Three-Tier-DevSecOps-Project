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