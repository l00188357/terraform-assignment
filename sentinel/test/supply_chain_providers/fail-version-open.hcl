mock "tfconfig/v2" {
  module {
    source = "mock-tfconfig-fail-version-open.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}
