# infra/k8s_rbac.tf
resource "kubernetes_cluster_role_binding" "cloudbuild_admin" {
  metadata {
    name = "cloudbuild-cluster-admin"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "User"
    name      = google_service_account.cloudbuild_sa.email
    api_group = "rbac.authorization.k8s.io"
  }
}
