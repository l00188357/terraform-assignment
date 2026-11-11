mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-unresolvable.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}
