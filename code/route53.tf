data "aws_route53_zone" "aws_dns" {
  name         = "${var.environment == "prod" ? "" : "${var.environment}."}eoncollectiveapp.com" ##$0.50 per hosted zone / month for the first 25 hosted zones + 0.04-0.06 per query
  private_zone = "false"
}
# Create EON DNS record for Adept base cluster/engine
resource "aws_route53_record" "base" {
  zone_id = "${data.aws_route53_zone.aws_dns.zone_id}"
  name    = "talend-arun.${data.aws_route53_zone.aws_dns.name}"
  type    = "CNAME"
  ttl     = "300"

  depends_on = [aws_instance.talend_re]
  records    = ["${aws_instance.talend_re.public_ip}"]
}