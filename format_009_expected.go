// backtick var, no return after backtick for HCL

func testAccAWSALBTargetGroupConfig_loadBalancingAlgorithm(targetGroupName string, nonDefault bool, algoType string) string {
	var algoTypeParam string

	if nonDefault {
		algoTypeParam = fmt.Sprintf(`load_balancing_algorithm_type = "%s"`, algoType)
	}

	return fmt.Sprintf(`
resource "aws_alb_target_group" "test" {
  name     = "%s"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = aws_vpc.test.id
}

resource "aws_vpc" "test" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "terraform-testacc-alb-target-group-load-balancing-algo"
  }
}
`, targetGroupName, algoTypeParam)
}
