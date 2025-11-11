# infra/ingress_class.tf
# Creates the IngressClass that GKE's broken addon failed to create

resource "kubernetes_ingress_class_v1" "gce" {
  metadata {
    name = "gce"
    annotations = {
      "ingressclass.kubernetes.io/is-default-class" = "true"
    }
  }

  spec {
    controller = "k8s.io/ingress-gce"
  }

  depends_on = [google_container_cluster.main]
}
