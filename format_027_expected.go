// spaced out %s strings

func testAccAWSConfigConfigurationAggregatorConfig_tags(rName, tagKey1, tagValue1, tagKey2, tagValue2 string) string {
	return fmt.Sprintf(`
resource "aws_config_configuration_aggregator" "example" {
  name = %[1]q

  tags = {
    Name  = %[1]q
    %[2]s = %[3]q
    %[4]s = %[5]q
  }
}

resource "aws_config_configuration_aggregator" "example2" {
  name = %[1]q

  tags = {
    A     = %[1]q
    %[2]s = %[3]q
    %[4]s = %[5]q
  }
}

resource "aws_config_configuration_aggregator" "example3" {
  name = %[1]q

  tags = {
    A  = %[1]q
    %s = %[3]q
    %s = %[5]q
  }
}

resource "aws_config_configuration_aggregator" "example3" {
  name = %[1]q

  tags = {
    really_long_name = %[1]q
    %s               = %[3]q
    %s               = %[5]q
  }
}

data "aws_caller_identity" "current" {}
`, rName, tagKey1, tagValue1, tagKey2, tagValue2)
}
