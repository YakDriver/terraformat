// unusual HCL return, plus random go code

func testAccDataSourceAwsPricingProductConfigRedshift() string {
	return `data "aws_pricing_product" "test" {
		service_code = "AmazonRedshift"
	  
		filters {
			field = "instanceType"
			value = "ds1.xlarge"
		}

		filters {
			field = "location"
			value = "US East (N. Virginia)"
		}
}
`
}

func testAccPricingCheckValueIsJSON(data string) resource.TestCheckFunc {
	return func(s *terraform.State) error {
		rs, ok := s.RootModule().Resources[data]

		if !ok {
			return fmt.Errorf("Can't find resource: %s", data)
		}

		result := rs.Primary.Attributes["result"]
		var objmap map[string]*json.RawMessage

		if err := json.Unmarshal([]byte(result), &objmap); err != nil {
			return fmt.Errorf("%s result value (%s) is not JSON: %s", data, result, err)
		}

		if len(objmap) == 0 {
			return fmt.Errorf("%s result value (%s) unmarshalling resulted in an empty map", data, result)
		}

		return nil
	}
}
