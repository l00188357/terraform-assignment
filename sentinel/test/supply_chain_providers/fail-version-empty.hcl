mock "tfconfig/v2" {
  module {
    source = "mock-tfconfig-fail-version-empty.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}
