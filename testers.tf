resource "google_compute_address" "lx" {
    count = 2
    name = "${local.prefix}-lx${count.index}"
    region = var.region
    address_type = "INTERNAL"
    subnetwork = count.index==0 ? google_compute_subnetwork.left.id : google_compute_subnetwork.right.id
}

resource "google_compute_instance" "cli" {
    name         = "${local.prefix}-lx-cli"
    zone = "${var.region}-b"
    machine_type = "c3-standard-8"

    boot_disk {
        initialize_params {
        image = "ubuntu-os-cloud/ubuntu-2204-lts"
        }
    }

    network_interface {
        subnetwork = google_compute_subnetwork.left.id
        network_ip = google_compute_address.lx[0].address
        nic_type = "GVNIC"
        access_config {}
    }
    metadata_startup_script = <<EOF
    apt update
    apt install iperf iperf3 apache2-utils wrk -y
    EOF
}

resource "google_compute_instance_template" "srv" {
    name         = "${local.prefix}-srv-tmpl"
    machine_type = "c2-standard-8"
    lifecycle {
        create_before_destroy = true
    }
    disk {
        source_image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
    network_interface {
        subnetwork = google_compute_subnetwork.right.id
        nic_type = "GVNIC"
        access_config {}
    }
    metadata_startup_script = <<EOF
    apt update
    apt install iperf iperf3 nginx -y
    iperf3 -sD
    dd if=/dev/random of=/var/www/html/64k bs=1k count=64
    dd if=/dev/random of=/var/www/html/1M bs=1k count=1024
    EOF
}

resource "google_compute_instance_group_manager" "srv" {
  name               = "${local.prefix}-srv-mig"
  version {
    instance_template  = google_compute_instance_template.srv.id
  }
  base_instance_name = "${local.prefix}-srv"
  zone               = "${var.region}-b"
  target_size        = "2"
}

resource "google_compute_health_check" "srv" {
    name = "${local.prefix}-srv-hc"
    http_health_check {
        port = "80"
    }
}

resource "google_compute_region_backend_service" "srv" {
  name                  = "${local.prefix}-srv-ilb"
  region                = var.region
  protocol              = "TCP"
  load_balancing_scheme = "INTERNAL"
  health_checks         = [google_compute_health_check.srv.id]
  backend {
    group           = google_compute_instance_group_manager.srv.instance_group
    balancing_mode  = "CONNECTION"
  }
}

resource "google_compute_forwarding_rule" "srv" {
  name                  = "${local.prefix}-srv-ilb-front"
  backend_service       = google_compute_region_backend_service.srv.id
  region                = var.region
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL"
  all_ports             = true
  network               = google_compute_subnetwork.right.network
  subnetwork            = google_compute_subnetwork.right.id
  ip_address = google_compute_address.lx[1].address
}