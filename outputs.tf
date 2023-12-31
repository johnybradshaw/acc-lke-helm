output "wordpressURL" {
    value = "http${var.dns.ddns_secure ? "s" : ""}://${local.subdomain}.${var.dns.ddns}"
    description = "Wordpress URL"
}
output "wordpressAdmin" {
    value = "http${var.dns.ddns_secure ? "s" : ""}://${local.subdomain}.${var.dns.ddns}/wp-login.php"
    description = "Wordpress Admin URL"
}
output "wordpressUsername" {
    value = random_string.wordpressUsername.result
    description = "Wordpress Username"
}
output "wordpressPassword" {
    value = random_password.wordpressPassword.result
    description = "Wordpress Password"
    sensitive = true
}