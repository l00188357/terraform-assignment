mock "tfconfig/v2" {
  module {
    source = "mock-tfconfig-fail-version-missing.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}
