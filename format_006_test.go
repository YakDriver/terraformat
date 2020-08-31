// weird json in var and then separate HCL

func testAccAWSAPIGatewayV2RouteConfig_model(rName string) string {
	schema := `
{
"$schema": "http://json-schema.org/draft-04/schema#",
"title": "ExampleModel",
"type": "object",
"properties": {
"id": {
"type": "string"
}
}
}
`

	return testAccAWSAPIGatewayV2ModelConfig_basic(rName, schema) + `
		resource "aws_apigatewayv2_route" "test" {
		api_id  = "${aws_apigatewayv2_api.test.id}"
		route_key = "$default"

		model_selection_expression = "action"

		request_models = {
			"test" = "${aws_apigatewayv2_model.test.name}"
		}
		}
`
}
