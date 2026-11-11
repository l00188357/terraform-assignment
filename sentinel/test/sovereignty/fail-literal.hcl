mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-literal.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}
