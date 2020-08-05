
func testAccDataSourceAwsBatchJobQueueConfig(rName string) string {
	return fmt.Sprintf(`
resource "aws_iam_role" "ecs_instance_role" {
  name = "ecs_%[1]s"
  count = 8
  attr = "hello"
  just_testing = "yes"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
        "Service": "ec2.amazonaws.com"
        }
    }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role" {
  role       = "${aws_iam_role.ecs_instance_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_role" {
  name = "ecs_%[1]s"
  role = "${aws_iam_role.ecs_instance_role.name}"
}

resource "aws_iam_role" "aws_batch_service_role" {
  name = "batch_%[1]s"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
        "Service": "batch.amazonaws.com"
        }
    }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "aws_batch_service_role" {
  role       = "${aws_iam_role.aws_batch_service_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

resource "aws_security_group" "sample" {
  name = "%[1]s"
}

resource "aws_vpc" "sample" {
  cidr_block = "10.1.0.0/16"
}

resource "aws_subnet" "sample" {
  vpc_id     = "${aws_vpc.sample.id}"
  cidr_block = "10.1.1.0/24"
}

resource "aws_batch_compute_environment" "sample" {
  compute_environment_name = "%[1]s"

  compute_resources {
    instance_role = "${aws_iam_instance_profile.ecs_instance_role.arn}"

    instance_type = [
      "c4.large",
    ]

    max_vcpus = 16
    min_vcpus = 0

    security_group_ids = [
      "${aws_security_group.sample.id}",
    ]

    subnets = [
      "${aws_subnet.sample.id}",
    ]

    type = "EC2"
  }

  service_role = "${aws_iam_role.aws_batch_service_role.arn}"
  type         = "MANAGED"
  depends_on   = ["aws_iam_role_policy_attachment.aws_batch_service_role"]
}

resource "aws_batch_job_queue" "test" {
  name                 = "%[1]s"
  state                = "ENABLED"
  priority             = 1
  compute_environments = ["${aws_batch_compute_environment.sample.arn}"]
}

resource "aws_batch_job_queue" "wrong" {
  name                 = "%[1]s_wrong"
  state                = "ENABLED"
  priority             = 2
  compute_environments = ["${aws_batch_compute_environment.sample.arn}"]
}

data "aws_batch_job_queue" "by_name" {
  name = "${aws_batch_job_queue.test.name}"
}
`, rName)
}

package aws

import (
	"fmt"
	"regexp"
	"testing"

	"github.com/hashicorp/terraform-plugin-sdk/helper/acctest"
	"github.com/hashicorp/terraform-plugin-sdk/helper/resource"
)

func TestAccAWSCloudFormationStack_dataSource_basic(t *testing.T) {
	stackName := acctest.RandomWithPrefix("tf-acc-ds-basic")
	resourceName := "data.aws_cloudformation_stack.network"

	resource.ParallelTest(t, resource.TestCase{
		PreCheck:  func() { testAccPreCheck(t) },
		Providers: testAccProviders,
		Steps: []resource.TestStep{
			{
				Config: testAccCheckAwsCloudFormationStackDataSourceConfig_basic(stackName),
				Check: resource.ComposeTestCheckFunc(
					resource.TestCheckResourceAttr(resourceName, "outputs.%", "1"),
					resource.TestMatchResourceAttr(resourceName, "outputs.VPCId", regexp.MustCompile("^vpc-[a-z0-9]+")),
					resource.TestCheckResourceAttr(resourceName, "capabilities.#", "0"),
					resource.TestCheckResourceAttr(resourceName, "disable_rollback", "false"),
					resource.TestCheckResourceAttr(resourceName, "notification_arns.#", "0"),
					resource.TestCheckResourceAttr(resourceName, "parameters.%", "1"),
					resource.TestCheckResourceAttr(resourceName, "parameters.CIDR", "10.10.10.0/24"),
					resource.TestCheckResourceAttr(resourceName, "timeout_in_minutes", "6"),
					resource.TestCheckResourceAttr(resourceName, "tags.%", "2"),
					resource.TestCheckResourceAttr(resourceName, "tags.Name", "Form the Cloud"),
					resource.TestCheckResourceAttr(resourceName, "tags.Second", "meh"),
				),
			},
		},
	})
}

func testAccCheckAwsCloudFormationStackDataSourceConfig_basic(stackName string) string {
	return fmt.Sprintf(`
resource "aws_cloudformation_stack" "cfs" {
  name = "%s"

  parameters = {
    CIDR = "10.10.10.0/24"
  }

  timeout_in_minutes = 6

  template_body = <<STACK
{
  "Parameters": {
    "CIDR": {
      "Type": "String"
    }
  },
  "Resources" : {
    "myvpc": {
      "Type" : "AWS::EC2::VPC",
      "Properties" : {
        "CidrBlock" : { "Ref" : "CIDR" },
        "Tags" : [
          {"Key": "Name", "Value": "Primary_CF_VPC"}
        ]
      }
    }
  },
  "Outputs" : {
    "VPCId" : {
      "Value" : { "Ref" : "myvpc" },
      "Description" : "VPC ID"
    }
  }
}
STACK

  tags = {
    Name   = "Form the Cloud"
    Second = "meh"
  }
}

data "aws_cloudformation_stack" "network" {
  name = "${aws_cloudformation_stack.cfs.name}"
}
`, stackName)
}

func TestAccAWSCloudFormationStack_dataSource_yaml(t *testing.T) {
	stackName := acctest.RandomWithPrefix("tf-acc-ds-yaml")
	resourceName := "data.aws_cloudformation_stack.yaml"

	resource.ParallelTest(t, resource.TestCase{
		PreCheck:  func() { testAccPreCheck(t) },
		Providers: testAccProviders,
		Steps: []resource.TestStep{
			{
				Config: testAccCheckAwsCloudFormationStackDataSourceConfig_yaml(stackName),
				Check: resource.ComposeTestCheckFunc(
					resource.TestCheckResourceAttr(resourceName, "outputs.%", "1"),
					resource.TestMatchResourceAttr(resourceName, "outputs.VPCId", regexp.MustCompile("^vpc-[a-z0-9]+")),
					resource.TestCheckResourceAttr(resourceName, "capabilities.#", "0"),
					resource.TestCheckResourceAttr(resourceName, "disable_rollback", "false"),
					resource.TestCheckResourceAttr(resourceName, "notification_arns.#", "0"),
					resource.TestCheckResourceAttr(resourceName, "parameters.%", "1"),
					resource.TestCheckResourceAttr(resourceName, "parameters.CIDR", "10.10.10.0/24"),
					resource.TestCheckResourceAttr(resourceName, "timeout_in_minutes", "6"),
					resource.TestCheckResourceAttr(resourceName, "tags.%", "2"),
					resource.TestCheckResourceAttr(resourceName, "tags.Name", "Form the Cloud"),
					resource.TestCheckResourceAttr(resourceName, "tags.Second", "meh"),
				),
			},
		},
	})
}

func testAccCheckAwsCloudFormationStackDataSourceConfig_yaml(stackName string) string {
	return fmt.Sprintf(`
resource "aws_cloudformation_stack" "yaml" {
  name = "%s"

  parameters = {
    CIDR = "10.10.10.0/24"
  }

  timeout_in_minutes = 6

  template_body = <<STACK
Parameters:
  CIDR:
    Type: String

Resources:
  myvpc:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: !Ref CIDR
      Tags:
        -
          Key: Name
          Value: Primary_CF_VPC

Outputs:
  VPCId:
    Value: !Ref myvpc
    Description: VPC ID
STACK

  tags = {
    Name   = "Form the Cloud"
    Second = "meh"
  }
}

data "aws_cloudformation_stack" "yaml" {
  name = "${aws_cloudformation_stack.yaml.name}"
}
`, stackName)
}
