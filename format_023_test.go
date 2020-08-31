// nondescript ticked stuff

func TestAccAWSCodeBuildProject_Source_Type_NoSourceInvalid(t *testing.T) {
	rName := acctest.RandomWithPrefix("tf-acc-test")
	rBuildspec := `
version: 0.2
phases:
  build:
    commands:
      - rspec hello_world_spec.rb`

	resource.ParallelTest(t, resource.TestCase{
		PreCheck:     func() { testAccPreCheck(t); testAccPreCheckAWSCodeBuild(t) },
		Providers:    testAccProviders,
		CheckDestroy: testAccCheckAWSCodeBuildProjectDestroy,
		Steps: []resource.TestStep{
			{
				Config:      testAccAWSCodeBuildProjectConfig_Source_Type_NoSource(rName, "", ""),
				ExpectError: regexp.MustCompile("`buildspec` must be set when source's `type` is `NO_SOURCE`"),
			},
			{
				Config:      testAccAWSCodeBuildProjectConfig_Source_Type_NoSource(rName, "location", rBuildspec),
				ExpectError: regexp.MustCompile("`location` must be empty when source's `type` is `NO_SOURCE`"),
			},
		},
	})
}
