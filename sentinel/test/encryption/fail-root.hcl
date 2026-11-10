mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-root.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}