resource "helm_release" "staging" {
  name             = "inu-dining-staging"
  chart            = "../charts/inu-dining-backend"
  namespace        = kubernetes_namespace.staging.metadata[0].name
  create_namespace = false
  atomic           = true
  cleanup_on_fail  = true
  timeout          = 900
  wait             = true

  set {
    name  = "image.repository"
    value = "${google_artifact_registry_repository.app_repo.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.app_repo.repository_id}/dining-backend"
  }
  set {
    name  = "image.tag"
    value = var.image_tag
  }
  set {
    name  = "serviceAccount.name"
    value = "inu-dining-ksa"
  }

  values = [
    yamlencode({
      ingress = {
        enabled     = true
        className   = "nginx"
        annotations = {
          "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
        }
        tls = [
          {
            secretName = "inu-dining-api-tls"
            hosts      = [var.staging_hostname]
          }
        ]
        hosts = [
          {
            host = var.staging_hostname
            paths = [
              {
                path     = "/"
                pathType = "ImplementationSpecific"
              }
            ]
          }
        ]
      }
    })
  ]

  depends_on = [
    kubernetes_secret.db_secret_staging,
    helm_release.nginx_ingress,
    kubectl_manifest.letsencrypt_issuer
  ]
}

resource "helm_release" "production" {
  name             = "inu-dining-prod"
  chart            = "../charts/inu-dining-backend"
  namespace        = kubernetes_namespace.prod.metadata[0].name
  create_namespace = false
  atomic           = true
  cleanup_on_fail  = true
  timeout          = 900
  wait             = true

  set {
    name  = "image.repository"
    value = "${google_artifact_registry_repository.app_repo.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.app_repo.repository_id}/dining-backend"
  }
  set {
    name  = "image.tag"
    value = var.image_tag
  }
  set {
    name  = "serviceAccount.name"
    value = "inu-dining-ksa"
  }

  values = [
    yamlencode({
      ingress = {
        enabled     = true
        className   = "nginx"
        annotations = {
          "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
        }
        tls = [
          {
            secretName = "api-prod-tls"
            hosts      = [var.prod_hostname]
          }
        ]
        hosts = [
          {
            host = var.prod_hostname
            paths = [
              {
                path     = "/"
                pathType = "ImplementationSpecific"
              }
            ]
          }
        ]
      }
    })
  ]

  depends_on = [
    kubernetes_secret.db_secret_prod,
    helm_release.nginx_ingress,
    kubectl_manifest.letsencrypt_issuer
  ]
}
