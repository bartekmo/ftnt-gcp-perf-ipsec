variable "region" {
  default = "us-central1"
}

variable "tunnels_count" {
    default = 1
}

variable "ver" {
    type = string
    description = "Firmware version"
    default = "7.4.1"
    validation {
        condition     = contains(["7.2.2", "7.2.3", "7.2.4", "7.2.5", "7.2.6", "7.4.0", "7.4.1"], var.ver)
        error_message = "Valid versions are: 7.2.3, 7.2.4, 7.2.5, 7.2.6, 7.4.0, 7.4.1."
    } 
}

variable "fgt1_flextoken" {
    type = string
    description = "Flex token for your FortiGate 1. If empty (default) template will deploy PAYG"
    default = ""
}

variable "fgt2_flextoken" {
    type = string
    description = "Flex token for your FortiGate2. If empty (default) template will deplooy PAYG"
    default = ""
}

variable "prefix" {
    type = string
    description = "Prefix to be added to all resource names. If empty \"test-[random string]\" will be used"
    default = ""
}