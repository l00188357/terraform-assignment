mock "tfplan/v2" {
  module {
    source = "mock-tfplan-pass-literal.sentinel"
  }
}

test {
  rules = {
    main = true
  }
}
