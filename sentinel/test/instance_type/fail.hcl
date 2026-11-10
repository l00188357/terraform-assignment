mock "tfplan/v2" {
  module {
    source = "../../test/instance_type/mock-tfplan-fail.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}