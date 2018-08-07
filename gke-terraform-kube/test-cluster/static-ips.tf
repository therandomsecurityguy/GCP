resource "google_compute_global_address" "cmsa_static_ip" {
  name = "cmsa-static-ip"
}

resource "google_compute_address" "gitlab_static_ip" {
  name = "gitlab-static-ip"
}
