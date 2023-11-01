
locals {
    img = {
        "7.2.2" = var.fgt1_flextoken=="" ? "fortinet-fgtondemand-722-20221004-001-w-license" : "fortinet-fgt-722-20221004-001-w-license"
        "7.2.3" = var.fgt1_flextoken=="" ? "fortinet-fgtondemand-723-20221110-001-w-license" : "fortinet-fgt-723-20221110-001-w-license"
        "7.2.4" = var.fgt1_flextoken=="" ? "fortinet-fgtondemand-724-20230201-001-w-license" : "fortinet-fgt-724-20230310-001-w-license"
        "7.2.5" = var.fgt1_flextoken=="" ? "fortinet-fgtondemand-725-20230613-001-w-license" : "fortinet-fgt-725-20230613-001-w-license"
        "7.2.6" = var.fgt1_flextoken=="" ? "fortinet-fgtondemand-726-20231016-001-w-license" : "fortinet-fgt-726-20231016-001-w-license"
        "7.4.0" = var.fgt1_flextoken=="" ? "fortinet-fgtondemand-740-20230512-001-w-license" : "fortinet-fgt-740-20230512-001-w-license"
        "7.4.1" = var.fgt1_flextoken=="" ? "fortinet-fgtondemand-741-20230905-001-w-license" : "fortinet-fgt-741-20230905-001-w-license"
    }
}

data "google_compute_image" "fgt_image" {
  project = "fortigcp-project-001"
  name = local.img[var.ver]
}

data "google_compute_default_service_account" "default" {
}



resource "google_compute_address" "pip1" {
    name = "${local.prefix}-pip1"
    region = var.region
}

resource "google_compute_address" "pip2" {
    name = "${local.prefix}-pip2"
    region = var.region
}

resource "google_compute_address" "vpnr" {
    count = var.tunnels_count

    name = "${local.prefix}-vpn${count.index}"
    region = var.region
}

resource "google_compute_instance" "fgt1" {
    name         = "${local.prefix}-fgt1"
    zone = "${var.region}-b"
    machine_type = "c2-standard-8"
    can_ip_forward = true
    tags = ["fgt"]

    boot_disk {
        initialize_params {
        image = data.google_compute_image.fgt_image.self_link
        }
    }

    network_interface {
        subnetwork = google_compute_subnetwork.ext.id
        access_config {
            nat_ip = google_compute_address.pip1.address
        }
    }

    network_interface {
        subnetwork = google_compute_subnetwork.left.id
    }

    service_account {
        email                = data.google_compute_default_service_account.default.email
        scopes               = ["cloud-platform"]
    }

    metadata = {
        user-data = data.cloudinit_config.fgt1.rendered
    }
    
}

resource google_compute_address "fgt2_port1" {
    name = "${local.prefix}-fgt2-port1"
    address_type = "INTERNAL"
    subnetwork = google_compute_subnetwork.ext.id
    region = var.region
}

resource "google_compute_instance" "fgt2" {
    name         = "${local.prefix}-fgt2"
    zone = "${var.region}-b"
    machine_type = "c2-standard-8"
    can_ip_forward = true
    tags = ["fgt"]

    boot_disk {
        initialize_params {
        image = data.google_compute_image.fgt_image.self_link
        }
    }

    network_interface {
        subnetwork = google_compute_subnetwork.ext.id
        network_ip = google_compute_address.fgt2_port1.address
        access_config {
            nat_ip = google_compute_address.pip2.address
        }
    }

    network_interface {
        subnetwork = google_compute_subnetwork.right.id
    }
    
    service_account {
        email                = data.google_compute_default_service_account.default.email
        scopes               = ["cloud-platform"]
    }

    metadata = {
        user-data = data.cloudinit_config.fgt2.rendered
    }
}

resource google_compute_instance_group "vpnr" {
    name = "${local.prefix}-umig-vpn-right"
    zone = google_compute_instance.fgt2.zone
    instances = [
        google_compute_instance.fgt2.self_link
    ]

    lifecycle {
        postcondition {
            condition = length(self.instances)==1
            error_message = "Instance group is empty (it's a provider error). Please run 'terraform apply' again"
        }
    }
}

resource "google_compute_region_health_check" "vpnr" {
  name               = "${local.prefix}-hc8008"
  region             = var.region

  tcp_health_check {
    port = 8008
  }
}

resource google_compute_region_backend_service "vpnr" {
    provider = google-beta
    name = "${local.prefix}-bes-vpn-right"
    region = var.region
    health_checks = [
        google_compute_region_health_check.vpnr.id
    ]
  load_balancing_scheme  = "EXTERNAL"
  protocol               = "UNSPECIFIED"
  backend {
    group                = google_compute_instance_group.vpnr.id
  }
  connection_tracking_policy {
    connection_persistence_on_unhealthy_backends = "NEVER_PERSIST"
  }
}

resource google_compute_forwarding_rule "vpnr" {
    count = var.tunnels_count
      name                  = "${local.prefix}fr-vpn${count.index}"
  region                = var.region
  ip_address            = google_compute_address.vpnr[count.index].address
  ip_protocol           = "L3_DEFAULT"
  all_ports             = true
  load_balancing_scheme = "EXTERNAL"
  backend_service       = google_compute_region_backend_service.vpnr.self_link
}


