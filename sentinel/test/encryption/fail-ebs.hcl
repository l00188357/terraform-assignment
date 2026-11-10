mock "tfplan/v2" {
  module {
    source = "mock-tfplan-fail-ebs.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}