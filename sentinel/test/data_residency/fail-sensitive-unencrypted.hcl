mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-sensitive-unencrypted.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}
