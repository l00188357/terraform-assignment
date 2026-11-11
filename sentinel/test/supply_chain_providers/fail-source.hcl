mock "tfconfig/v2" {
  module {
    source = "mock-tfconfig-fail-source.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}
