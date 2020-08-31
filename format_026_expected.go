// interpol vars together

func testAccFred(rName string, tagGroup bool) string {
	return fmt.Sprintf(`
resource "aws_codedeploy_deployment_group" "test" {
  app_name              = aws_iam_role.test.id
  deployment_group_name = "${aws_iam_role.test.id} and stuff in the middle ${aws_iam_role.test.id}"
  service_role_arn      = "${aws_iam_role.test.id}/${aws_iam_role.test.id}"
}
`)
}

func testAccAWSCodeBuildProjectConfig_Source_Type_S3(rName string) string {
	return testAccAWSCodeBuildProjectConfig_Base_ServiceRole(rName) + fmt.Sprintf(`
resource "aws_s3_bucket" "test" {
  bucket = %[1]q
}

resource "aws_s3_bucket_object" "test" {
  bucket  = aws_s3_bucket.test.bucket
  content = "test"
  key     = "test.txt"
}

resource "aws_codebuild_project" "test" {
  name         = %[1]q
  service_role = aws_iam_role.test.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "2"
    type         = "LINUX_CONTAINER"
  }

  source {
    location = "${aws_s3_bucket.test.bucket}/${aws_s3_bucket_object.test.key}"
    type     = "S3"
  }
}
`, rName)
}
