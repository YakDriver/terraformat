// var replacement in string vs not replaced plus dollar var to not be replaced

func testAccAWSAPIGatewayV2RouteConfig_target(rName string) string {
	return testAccAWSAPIGatewayV2IntegrationConfig_basic(rName) + `
resource "aws_apigatewayv2_route" "test" {
  api_id    = "${aws_apigatewayv2_api.test.id}"
  route_key = "$default"

  target = "integrations/${aws_apigatewayv2_integration.test.id}"
}
`
}
