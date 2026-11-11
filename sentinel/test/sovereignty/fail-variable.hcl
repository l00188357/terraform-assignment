mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-variable.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}
