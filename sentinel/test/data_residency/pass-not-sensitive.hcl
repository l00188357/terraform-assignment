mock "tfplan/v2" {
  module {
    source = "mock-tfplan-pass-not-sensitive.sentinel"
  }
}

test {
  rules = {
    main = true
  }
}
