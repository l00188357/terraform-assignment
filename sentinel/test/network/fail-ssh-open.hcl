mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-ssh-open.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}