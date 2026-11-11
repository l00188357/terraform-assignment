mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-range-open.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}