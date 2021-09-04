variable "instance_name" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "Talend-Remote-Engine-ON-TMC"
}
# Define variable types
variable "region" {
  default = "us-east-1"
}
variable "region_dr" {
  default = "us-east-2"
}
variable "preferred_zone" {
  default = "us-east-1e"
}
variable "account_id" {
  default = "152338276817" ## sandbox by R.Scott
# default = "335674665642" ## adept non prod 
}
variable "organization" {
  default = "eoncollective"
}
variable "environment" {
  default = "dev"
}
variable "re_number" {
  default = "1"
}

variable "location_url" {
  type = map
  default = {
    US = "https://pair.us.cloud.talend.com"
    EU = "https://pair.eu.cloud.talend.com"
    AP = "https://pair.ap.cloud.talend.com"
  }
}
variable "location" {default = "US"}
