# infra/gcs_frontend_lb.tf

# 1. Reserve a static IP for the frontend
resource "google_compute_global_address" "frontend_ip" {
  name    = "inu-dining-frontend-ip"
  project = var.project_id
}

# 2. Define the GCS bucket as a "Backend Bucket"
resource "google_compute_backend_bucket" "frontend" {
  name        = "inu-dining-frontend-backend"
  bucket_name = "inu-dining-frontend"
  enable_cdn  = true
  project     = var.project_id

  cdn_policy {
    default_ttl = 3600
    client_ttl  = 3600
    max_ttl     = 3600
    negative_caching = true
  }
}

# 3. Create an SSL certificate for the new domain
resource "google_compute_managed_ssl_certificate" "frontend_ssl" {
  name    = "inu-dining-frontend-ssl"
  project = var.project_id
  managed {
    domains = ["inu-dining-frontend.duckdns.org"]
  }
}

# 4. Create the URL map (This is the "magic" fix)
resource "google_compute_url_map" "frontend" {
  name            = "inu-dining-frontend-urlmap"
  default_service = google_compute_backend_bucket.frontend.id
  project         = var.project_id

  host_rule {
    hosts        = ["inu-dining-frontend.duckdns.org"]
    path_matcher = "nextjs-matcher"
  }

  path_matcher {
    name            = "nextjs-matcher"
    default_service = google_compute_backend_bucket.frontend.id
    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_bucket.frontend.id
    }
  }
}

# 5. Create the HTTPS proxy
resource "google_compute_target_https_proxy" "frontend" {
  name    = "inu-dining-frontend-proxy"
  url_map = google_compute_url_map.frontend.id
  ssl_certificates = [google_compute_managed_ssl_certificate.frontend_ssl.id]
  project = var.project_id
}

# 6. Create the final "front door"
resource "google_compute_global_forwarding_rule" "frontend" {
  name       = "inu-dining-frontend-fwd-rule"
  target     = google_compute_target_https_proxy.frontend.id
  port_range = "443"
  ip_address = google_compute_global_address.frontend_ip.address
  project    = var.project_id
}

# 7. Create a URL map for the HTTP redirect
resource "google_compute_url_map" "frontend_redirect" {
  name    = "inu-dining-frontend-redirect-urlmap"
  project = var.project_id

  default_url_redirect {
    https_redirect         = true
    strip_query            = false
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
  }
}

# 8. Create the HTTP proxy for the redirect
resource "google_compute_target_http_proxy" "frontend_redirect" {
  name    = "inu-dining-frontend-redirect-proxy"
  url_map = google_compute_url_map.frontend_redirect.id
  project = var.project_id
}

# 9. Create the port 80 "front door" for the redirect
resource "google_compute_global_forwarding_rule" "frontend_redirect" {
  name       = "inu-dining-frontend-redirect-fwd-rule"
  target     = google_compute_target_http_proxy.frontend_redirect.id
  port_range = "80"
  ip_address = google_compute_global_address.frontend_ip.address  # Use the SAME static IP
  project    = var.project_id
}

# Make the frontend bucket publicly readable so the load balancer can serve it
resource "google_storage_bucket_iam_member" "frontend_public" {
  bucket = "inu-dining-frontend"
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}
