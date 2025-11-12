resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  version          = "v1.14.5"

  set {
    name  = "installCRDs"
    value = "true"
  }

  depends_on = [
    kubernetes_cluster_role_binding.cloudbuild_admin
  ]
}

resource "time_sleep" "wait_for_cert_manager" {
  depends_on      = [helm_release.cert_manager]
  create_duration = "120s"
}
