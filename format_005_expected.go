// %q, %f, %d in quotes, out of quotes

func testAccAWSAppautoscalingPolicySpotFleetRequestConfig(randPolicyName, validUntil string) string {
	return fmt.Sprintf(`
data "aws_ami" "amzn-ami-minimal-hvm-ebs" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-minimal-hvm-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_acm_certificate" "cert" {
  domain_name               = "%s"
  subject_alternative_names = [%s]
  more_names                = [%s, %d, "%s"]
  validation_method         = "%s"
}

data "aws_partition" "current" {}

resource "aws_spot_fleet_request" "test" {
  iam_fleet_role                      = aws_iam_role.fleet_role.arn
  spot_price                          = "%[1]d"
  target_capacity                     = %[1]d
  valid_until                         = %[2]q
  terminate_instances_with_expiration = true

  launch_specification {
    instance_type = "m3.medium"
    ami           = data.aws_ami.amzn-ami-minimal-hvm-ebs.id
  }
}

resource "aws_appautoscaling_target" "test" {
  service_namespace  = "ec2"
  resource_id        = "spot-fleet-request/${aws_spot_fleet_request.test.id}"
  scalable_dimension = "ec2:spot-fleet-request:TargetCapacity"
  min_capacity       = "%f"
  max_capacity       = "%s"
}

resource "aws_appautoscaling_policy" "test" {
  name               = %[1]q
  resource_id        = aws_appautoscaling_target.test.resource_id
  scalable_dimension = aws_appautoscaling_target.test.scalable_dimension
  service_namespace  = aws_appautoscaling_target.test.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = %[1]f
    }
  }
}
`, randPolicyName, validUntil)
}
