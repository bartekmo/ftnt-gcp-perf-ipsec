

data "cloudinit_config" "fgt1" {
  gzip          = false
  base64_encode = false

  dynamic "part" {
    for_each = [ var.fgt1_flextoken=="" ? [] : [var.fgt1_flextoken]]
    content {
        filename = "license"
        content = "LICENSE-TOKEN: ${var.fgt1_flextoken}\n"
    }
  }

  part {
    filename = "config"
    content = <<EOF
        config sys interface
            edit port2
                set dhcp-classless-route-addition enable
            next
        end
        config vpn ipsec phase1-interface
        %{for i in range(0,var.tunnels_count) ~}
            edit vpn${i}
                set interface "port1"
                set ike-version 2
                set peertype any
                set net-device disable
                set aggregate-member enable
                set proposal aes128gcm-prfsha256
                set dpd on-idle
                set dhgrp 5
                set remote-gw ${google_compute_address.vpnr[i].address}
                set psksecret verysecretsecret
            next
        %{endfor ~}
        end

        config vpn ipsec phase2-interface
        %{for i in range(0,var.tunnels_count) ~}
            edit "vpn${i}"
                set phase1name "vpn${i}"
                set proposal aes128gcm
                set dhgrp 5
                set auto-negotiate enable
            next
        %{endfor ~}
        end

        config system ipsec-aggregate
            edit "agg1"
                set member ${join(" ", [for i in range(0,var.tunnels_count) : "\"vpn${i}\"" ])}
                set algorithm weighted-round-robin
            next
        end

        config router static
            edit 0
                set dst ${google_compute_subnetwork.right.ip_cidr_range}
                set device agg1
            next
        end

        config firewall policy
            edit 1
                set srcintf "any"
                set dstintf "any"
                set srcaddr "all"
                set dstaddr "all"
                set schedule "always"
                set service "ALL"
                set logtraffic disable
                set action accept
            next
        end

        config sys admin
          edit "admin"
            config gui-dashboard
              edit 12
                set name "perf"
                set vdom "root"
                config widget
                    edit 1
                        set type ipsec-vpn
                        set width 4
                        set height 1
                    next
                    edit 2
                        set type tr-history
                        set x-pos 2
                        set width 2
                        set height 1
                        set interface "agg1"
                    next
                    edit 3
                        set type cpu-usage
                        set x-pos 1
                        set width 2
                        set height 1
                    next
                end
            end
          next
        end
        EOF
  }
}

data "cloudinit_config" "fgt2" {
  gzip          = false
  base64_encode = false

  dynamic "part" {
    for_each = [ var.fgt1_flextoken=="" ? [] : [var.fgt1_flextoken]]
    content {
        filename = "license"
        content = "LICENSE-TOKEN: ${var.fgt1_flextoken}\n"
    }
  }

  part {
    filename = "config"
    content = <<EOF
        config sys probe-response
            set mode http-probe
        end
        config sys interface
            edit port1
                set mode static
                set ip ${google_compute_address.fgt2_port1.address}/32
                set secondary-IP enable
                config secondaryip
                    %{for i in range(0,var.tunnels_count) ~}
                    edit 0
                    set ip ${google_compute_address.vpnr[i].address}/32
                    set allowaccess probe-response
                    next
                    %{endfor ~}
                end
            next
            edit port2
                set dhcp-classless-route-addition enable
            next
        end        
        config router static
            edit 0
            set device port1
            set gateway ${google_compute_subnetwork.ext.gateway_address}
            next
        end
        config vpn ipsec phase1-interface
        %{for i in range(0, var.tunnels_count) ~}
            edit vpn${i}
                set interface "port1"
                set ike-version 2
                set local-gw ${google_compute_address.vpnr[i].address}
                set peertype any
                set net-device disable
                set aggregate-member enable
                set proposal aes128gcm-prfsha256
                set dpd on-idle
                set dhgrp 5
                set remote-gw ${google_compute_address.pip1.address}
                set psksecret verysecretsecret
            next
        %{endfor ~}
        end

        config vpn ipsec phase2-interface
        %{for i in range(0,var.tunnels_count) ~}
            edit "vpn${i}"
                set phase1name "vpn${i}"
                set proposal aes128gcm
                set dhgrp 5
                set auto-negotiate enable
            next
        %{endfor ~}
        end

        config system ipsec-aggregate
            edit "agg1"
                set member ${join(" ", [for i in range(0,var.tunnels_count) : "\"vpn${i}\"" ])}
                set algorithm weighted-round-robin
            next
        end

        config router static
            edit 0
                set dst ${google_compute_subnetwork.left.ip_cidr_range}
                set device agg1
            next
        end

        config firewall policy
            edit 1
                set srcintf "any"
                set dstintf "any"
                set srcaddr "all"
                set dstaddr "all"
                set schedule "always"
                set service "ALL"
                set logtraffic disable
                set action accept
            next
        end

        config sys admin
          edit "admin"
            config gui-dashboard
              edit 12
                set name "perf"
                set vdom "root"
                config widget
                    edit 1
                        set type ipsec-vpn
                        set width 4
                        set height 1
                    next
                    edit 2
                        set type tr-history
                        set x-pos 2
                        set width 2
                        set height 1
                        set interface "agg1"
                    next
                    edit 3
                        set type cpu-usage
                        set x-pos 1
                        set width 2
                        set height 1
                    next
                end
            end
          next
        end
        EOF
  }
}