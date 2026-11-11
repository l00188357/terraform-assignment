mock "tfconfig/v2" {
  module {
    source = "mock-tfconfig-pass-local.sentinel"
  }
}

test {
  rules = {
    main = true
  }
}
