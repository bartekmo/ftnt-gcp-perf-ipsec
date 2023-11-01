resource "random_string" "random" {
  length           = 4
  special          = false
  upper = false
}

locals {
    prefix = var.prefix!="" ? var.prefix : "test-${random_string.random.result}"
}
