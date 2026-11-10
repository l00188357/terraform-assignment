mock "tfplan/v2" {
  module {
    source = "../../test/instance_type/mock-tfplan-pass.sentinel"
  }
}

test {
  rules = {
    main = true
  }
}