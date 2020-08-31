// another test of %s type things, including in quotes, %s outside all in HCL

func testAccAWSAccessAnalyzerAnalyzerConfigTags1(rName, tagKey1, tagValue1 string) string {
	return fmt.Sprintf(`
%s

resource "aws_accessanalyzer_analyzer" "test" {
name = "this-has-a-%d"
parent_id = "%d"
path = "fred%[2]sabc"
analyzer_name = %[1]q

tags = {
%[2]q = %[3]q
}
}
`, rName, tagKey1, tagValue1)
}

func testAccAWSAPIGatewayV2RouteConfig_apiHttp(rName string) string {
	return fmt.Sprintf(`
resource "aws_apigatewayv2_api" "test" {
  name          = %[1]q
  protocol_type = "HTTP"
}
`, rName)
}