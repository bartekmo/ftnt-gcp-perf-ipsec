output "prefix" {
    description = "Prefix used for resource names"
    value = local.prefix
}

output "tester_ssh_cmd" {
    value = "gcloud compute ssh ${google_compute_instance.cli.name} --zone ${google_compute_instance.cli.zone}"
}