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

policy "sovereignty" {
  source            = "./sovereignty.sentinel"
  enforcement_level = "hard-mandatory"
}

policy "supply_chain_providers" {
  source            = "./supply_chain_providers.sentinel"
  enforcement_level = "hard-mandatory"
}

policy "supply_chain_modules" {
  source            = "./supply_chain_modules.sentinel"
  enforcement_level = "hard-mandatory"
}

policy "data_residency" {
  source            = "./data_residency.sentinel"
  enforcement_level = "hard-mandatory"
}