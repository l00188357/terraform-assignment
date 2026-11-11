policy "instance_type" {
  source            = "./instance_type.sentinel"
  enforcement_level = "hard-mandatory"
}

policy "encryption" {
  source            = "./encryption.sentinel"
  enforcement_level = "hard-mandatory"
}

policy "metadata" {
  source            = "./metadata.sentinel"
  enforcement_level = "hard-mandatory"
}

policy "network" {
  source            = "./network.sentinel"
  enforcement_level = "hard-mandatory"
}