mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-copy-us.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}
