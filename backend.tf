terraform {
  backend "s3" {
    skip_region_validation = true
    bucket                 = "terraform-state-182764123461"
    key                    = "states/github/strokes-state"
    dynamodb_table         = "terraform-lock"
    region                 = "eu-central-2"
  }
}