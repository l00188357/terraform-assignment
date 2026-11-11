mock "tfconfig/v2" {
  module {
    source = "mock-tfconfig-fail-unpinned.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}
