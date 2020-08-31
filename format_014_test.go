// basic test, mix of issues

func testAccAWSALBTargetGroupConfig_updateHealthCheck(targetGroupName string) string {
	return fmt.Sprintf(`resource "aws_alb_target_group" "test" {
  name = "%s"
  port = 443
  protocol = "HTTPS"
  vpc_id = "${aws_vpc.test.id}"

  deregistration_delay = 200

stickiness {
type = "lb_cookie"
cookie_duration = 10000
}

health_check {
path = "/health2"
interval = 30
port = 8082
protocol = "HTTPS"
timeout = 4
healthy_threshold = 4
unhealthy_threshold = 4
matcher = "200"
}
}

resource "aws_vpc" "test" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "terraform-testacc-alb-target-group-basic"
  }
}`, targetGroupName)
}
