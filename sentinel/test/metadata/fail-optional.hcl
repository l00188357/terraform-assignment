mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-optional.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}