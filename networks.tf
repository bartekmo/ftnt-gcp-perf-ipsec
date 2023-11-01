resource "google_compute_network" "ext" {
    name = "${local.prefix}-ext"
    auto_create_subnetworks = false
}

resource "google_compute_network" "left" {
    name = "${local.prefix}-left"
    auto_create_subnetworks = false
}

resource "google_compute_network" "right" {
    name = "${local.prefix}-right"
    auto_create_subnetworks = false
}

resource google_compute_subnetwork "ext" {
    name = "${local.prefix}-ext"
    region = var.region
    network = google_compute_network.ext.id
    ip_cidr_range = "10.0.0.0/24"
}
resource google_compute_subnetwork "left" {
    name = "${local.prefix}-left"
    region = var.region
    network = google_compute_network.left.id
    ip_cidr_range = "10.0.100.0/24"
    secondary_ip_range {
        range_name = "secondary"
        ip_cidr_range = "10.0.101.0/24"
    }
}
resource google_compute_subnetwork "right" {
    name = "${local.prefix}-right"
    region = var.region
    network = google_compute_network.right.id
    ip_cidr_range = "10.0.200.0/24"
}

resource google_compute_route "l2r" {
    name = "${local.prefix}-to-right"
    dest_range = google_compute_subnetwork.right.ip_cidr_range
    network = google_compute_network.left.id
    next_hop_instance = google_compute_instance.fgt1.id
}

resource google_compute_route "r2l" {
    name = "${local.prefix}-to-left"
    dest_range = google_compute_subnetwork.left.ip_cidr_range
    network = google_compute_network.right.id
    next_hop_instance = google_compute_instance.fgt2.id
}

resource google_compute_firewall "openext" {
    name = "${local.prefix}-open-ext"
    network = google_compute_network.ext.id
    allow {
        protocol = "all"
    }
    source_ranges = ["0.0.0.0/0"]
}

resource google_compute_firewall "openleft" {
    name = "${local.prefix}-open-left"
    network = google_compute_network.left.id
    allow {
        protocol = "all"
    }
    source_ranges = ["0.0.0.0/0"]
}

resource google_compute_firewall "openright" {
    name = "${local.prefix}-open-right"
    network = google_compute_network.right.id
    allow {
        protocol = "all"
    }
    source_ranges = ["0.0.0.0/0"]
}