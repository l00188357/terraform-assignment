mock "tfplan/v2" {
  module {
    source = "mock-tfplan-pass-variable.sentinel"
  }
}

test {
  rules = {
    main = true
  }
}
