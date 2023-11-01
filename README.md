# VPN performance test setup

Use this setup to test VPN tunnel performance. The architecture us super-simple:

Ubuntu -- FGT1 -- FGT2 -- Ubuntu

FGTs deploy with PAYG unless provided with flex tokens in var.fgt1_flextoken/var.fgt2_flextoken

Multiple aggregated tunnels are created if var.tunnels_count>1

### How to use

- deploy (eg. `terraform apply -var ver=7.4.1`)
- connect to lx0
- run iperf3 -c 10.0.200.2
- run ab http://10.0.200.2/64k
- destroy