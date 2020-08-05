var testAccAWSCloudFrontDistributionData = fmt.Sprintf(`
%s

data "aws_cloudfront_distribution" "test" {
	id = aws_cloudfront_distribution.s3_distribution.id
}
`, fmt.Sprintf(testAccAWSCloudFrontDistributionS3ConfigWithTags, acctest.RandInt(), originBucket, logBucket, testAccAWSCloudFrontDistributionRetainConfig()))

// Testing name_regex parameter
const testAccCheckAwsAmiDataSourceNameRegexConfig = `
data "aws_ami" "name_regex_filtered_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*"]
  }

  name_regex = "^amzn-ami-\\d{3}[5].*-ecs-optimized"
}
`

func testAccAWSAutoScalingGroupConfigUpdate(name string) string {
	return testAccAvailableAZsNoOptInDefaultExcludeConfig() +
		fmt.Sprintf(`
data "aws_ami" "test_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_launch_configuration" "foobar" {
  image_id      = data.aws_ami.test_ami.id
  instance_type = "t2.micro"
}

resource "aws_launch_configuration" "new" {
  image_id      = data.aws_ami.test_ami.id
  instance_type = "t2.micro"
}
`)
}