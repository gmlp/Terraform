variable "environment" {
  default = "prod"
}
variable "region" {
  description = "Aws region. Changing it will lead to loss of complete stack.!!!"
  default     = "us-west-2"
}
