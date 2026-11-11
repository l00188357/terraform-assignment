mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-missing.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}