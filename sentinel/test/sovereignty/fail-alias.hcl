mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-alias.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}
