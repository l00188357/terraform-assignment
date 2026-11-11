mock "tfplan/v2" {
  module {
    source = "mock-tfplan-pass-copy-in-region.sentinel"
  }
}

test {
  rules = {
    main = true
  }
}
