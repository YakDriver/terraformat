// 0.11 vs. 0.12 list indexing

func testAccAWSAPIGatewayV2VpcLinkConfig_basic(rName string) string {
	return testAccAWSAPIGatewayV2VpcLinkConfig_base(rName) + fmt.Sprintf(`
resource "aws_apigatewayv2_vpc_link" "test" {
  name               = %[1]q
  security_group_ids = ["${aws_security_group.test.id}"]
  subnet_ids         = ["${aws_subnet.test.*.id[0]}", "${aws_subnet.test.*.id[1]}"]
}
`, rName)
}
