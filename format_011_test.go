// var replacement inside of JSON

func testAccAWSAPIGatewayMethodConfigWithCognitoAuthorizerUpdate(rInt int) string {
	return fmt.Sprintf(`
resource "aws_api_gateway_rest_api" "test" {
  name = "tf-acc-test-cognito-auth-%d"
}

resource "aws_iam_role" "invocation_role" {
  name = "tf_acc_api_gateway_auth_invocation_role-%d"
  path = "/"

  assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
{
"Action": "sts:AssumeRole",
"Principal": {
"Service": "${aws_iam_role.iam_for_lambda.name}"
},
"Effect": "Allow",
"Sid": ""
}
]
}
EOF

}

resource "aws_iam_role" "iam_for_lambda" {
  name = "tf_acc_iam_for_lambda_api_gateway_authorizer-%d"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
"Action": "sts:AssumeRole",
"Principal": {
"Service": "lambda.amazonaws.com"
},
"Effect": "Allow",
"Sid": ""
}
]
}
EOF

}

resource "aws_cognito_user_pool" "pool" {
name = "tf-acc-test-cognito-pool-%d"

request_models = {
"application/json" = "Error"
}
request_parameters = {
"method.request.querystring.page" = false
}
}
`, rInt, rInt, rInt, rInt)
}
