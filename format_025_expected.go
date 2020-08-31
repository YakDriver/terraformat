// hcl-containing go variables

func testAccAWSCodeDeployDeploymentGroup(rName string, tagGroup bool) string {
	var tagGroupOrFilter string
	if tagGroup {
		tagGroupOrFilter = `
ec2_tag_set {
  ec2_tag_filter {
    key   = "filterkey"
    type  = "KEY_AND_VALUE"
    value = "filtervalue"
  }
}
`

	} else {
		tagGroupOrFilter = `
ec2_tag_filter {
  key   = "filterkey"
  type  = "KEY_AND_VALUE"
  value = "filtervalue"
}
`

	}

	return fmt.Sprintf(`
resource "aws_codedeploy_deployment_group" "test" {
  app_name              = aws_codedeploy_app.test.name
  deployment_group_name = "tf-acc-test-%[1]s"
  service_role_arn      = aws_iam_role.test.arn
  %[2]s
}

resource "aws_codedeploy_app" "test" {
  name = "tf-acc-test-%[1]s"
}

resource "aws_iam_role_policy" "test" {
  name = "tf-acc-test-%[1]s"
  role = aws_iam_role.test.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:CompleteLifecycleAction",
        "autoscaling:DeleteLifecycleHook",
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeLifecycleHooks",
        "autoscaling:PutLifecycleHook",
        "autoscaling:RecordLifecycleActionHeartbeat",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus",
        "tag:GetTags",
        "tag:GetResources"
      ],
      "Resource": "*"
    }
  ]
}
EOF

}

resource "aws_iam_role" "test" {
  name = "tf-acc-test-%[1]s"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "codedeploy.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}
`, rName, tagGroupOrFilter)
}
