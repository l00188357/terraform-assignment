mock "tfconfig/v2" {
  module {
    source = "mock-tfconfig-fail-version-range.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}
