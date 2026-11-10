policy "instance_type" {
  source            = "./instance_type.sentinel"
  enforcement_level = "hard-mandatory"
}

policy "encryption" {
  source            = "./encryption.sentinel"
  enforcement_level = "hard-mandatory"
}