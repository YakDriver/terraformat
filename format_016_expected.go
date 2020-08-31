// unusual HCL return

func TestAccDataSourceAwsPricingProduct_redshift(t *testing.T) {
	oldRegion := os.Getenv("AWS_DEFAULT_REGION")
	os.Setenv("AWS_DEFAULT_REGION", "us-east-1")
	defer os.Setenv("AWS_DEFAULT_REGION", oldRegion)
	resource.ParallelTest(t, resource.TestCase{
		PreCheck:  func() { testAccPreCheck(t) },
		Providers: testAccProviders,
		Steps: []resource.TestStep{
			{
				Config: testAccDataSourceAwsPricingProductConfigRedshift(),
				Check: resource.ComposeAggregateTestCheckFunc(
					resource.TestCheckResourceAttrSet("data.aws_pricing_product.test", "result"),
					testAccPricingCheckValueIsJSON("data.aws_pricing_product.test"),
				),
			},
		},
	})
}

func testAccDataSourceAwsPricingProductConfigEc2(dataName string, instanceType string) string {
	return fmt.Sprintf(`
data "aws_pricing_product" "%s" {
  service_code = "AmazonEC2"

  filters {
    field = "instanceType"
    value = "%s"
  }

  filters {
    field = "operatingSystem"
    value = "Linux"
  }

  filters {
    field = "location"
    value = "US East (N. Virginia)"
  }

  filters {
    field = "preInstalledSw"
    value = "NA"
  }

  filters {
    field = "licenseModel"
    value = "No License required"
  }

  filters {
    field = "tenancy"
    value = "Shared"
  }

  filters {
    field = "capacitystatus"
    value = "Used"
  }
}
`, dataName, instanceType)
}
