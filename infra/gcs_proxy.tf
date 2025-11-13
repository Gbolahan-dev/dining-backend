resource "google_compute_backend_bucket" "frontend" {
  name        = "inu-dining-frontend-backend"
  bucket_name = "inu-dining-frontend"
  enable_cdn  = true
}

resource "google_compute_url_map" "frontend" {
  name            = "inu-dining-frontend-urlmap"
  default_service = google_compute_backend_bucket.frontend.id
  
  host_rule {
    hosts        = ["inu-dining-frontend.duckdns.org"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_bucket.frontend.id
  }
}

resource "google_compute_managed_ssl_certificate" "frontend_ssl" {
  name = "inu-dining-frontend-ssl"
  managed {
    domains = ["inu-dining-frontend.duckdns.org"]
  }
}

resource "google_compute_target_https_proxy" "frontend" {
  name             = "inu-dining-frontend-proxy"
  url_map          = google_compute_url_map.frontend.id
  ssl_certificates = [google_compute_managed_ssl_certificate.frontend_ssl.id]
}

resource "google_compute_global_forwarding_rule" "frontend" {
  name       = "inu-dining-frontend-fwd-rule"
  target     = google_compute_target_https_proxy.frontend.id
  port_range = "443"
}
