// ticked multi-line strings

func testAccAWSCloudTrailConfig_include_global_service_events(cloudTrailRandInt int) string {
	return fmt.Sprintf(`
resource "aws_cloudtrail" "foobar" {
  name                          = "tf-trail-foobar-%d"
  s3_bucket_name                = aws_s3_bucket.foo.id
  include_global_service_events = false
}

resource "aws_s3_bucket" "foo" {
  bucket        = "tf-test-trail-%d"
  force_destroy = true

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSCloudTrailAclCheck",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::tf-test-trail-%d"
    },
    {
      "Sid": "AWSCloudTrailWrite",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::tf-test-trail-%d/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    }
  ]
}
POLICY

}
`, cloudTrailRandInt, cloudTrailRandInt, cloudTrailRandInt, cloudTrailRandInt)
}

func testAccAWSCloudTrailConfig_tags(cloudTrailRandInt int) string {
	tagsString := `
tags = {
  Foo  = "moo"
  Pooh = "hi"
}
`

	return fmt.Sprintf(testAccAWSCloudTrailConfig_tags_tpl,
		cloudTrailRandInt,
		tagsString,
		cloudTrailRandInt,
		cloudTrailRandInt,
		cloudTrailRandInt)
}

func testAccAWSCloudTrailConfig_tagsModified(cloudTrailRandInt int) string {
	tagsString := `
tags = {
  Foo  = "moo"
  Pooh = "hi"
  Moo  = "boom"
}
`

	return fmt.Sprintf(testAccAWSCloudTrailConfig_tags_tpl,
		cloudTrailRandInt,
		tagsString,
		cloudTrailRandInt,
		cloudTrailRandInt,
		cloudTrailRandInt)
}
