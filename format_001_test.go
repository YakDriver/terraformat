// basic format plus 0.12 stuff

func testAccConfigOrganizationCustomRuleConfigLambdaFunctionArn2(rName string) string {
	return testAccConfigOrganizationCustomRuleConfigBase(rName) + fmt.Sprintf(`
resource "aws_lambda_function" "test2" {
filename      = "test-fixtures/lambdatest.zip"
function_name = "%[1]s2"
role          = "${aws_iam_role.lambda.arn}"
handler       = "exports.example"
runtime       = "nodejs12.x"
}

resource "aws_lambda_permission" "test2" {
action  = "lambda:InvokeFunction"
function_name = "${aws_lambda_function.test2.arn}"
principal = "config.amazonaws.com"
statement_id  = "AllowExecutionFromConfig"
}

resource "aws_config_organization_custom_rule" "test" {
depends_on = [aws_config_configuration_recorder.test, aws_lambda_permission.test2, aws_organizations_organization.test]

lambda_function_arn = "${aws_lambda_function.test2.arn}"
name  = %[1]q
trigger_types = ["ScheduledNotification"]
}
`, rName)
}
