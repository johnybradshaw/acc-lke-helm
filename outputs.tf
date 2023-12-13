output "wordpress" {
    value = "http${var.dns.ddns_secure ? "s" : ""}://${data.linode_profile.me.username}.${var.dns.ddns}"
    description = "Wordpress URL"
}
output "wordpressAdmin" {
    value = "http${var.dns.ddns_secure ? "s" : ""}://${data.linode_profile.me.username}.${var.dns.ddns}/wp-login.php"
    description = "Wordpress Admin URL"
}
output "wordpressUsername" {
    value = data.linode_profile.me.username
    description = "Wordpress Username"
}
output "wordpressPassword" {
    value = random_password.wordpressPassword.result
    description = "Wordpress Password"
    sensitive = true
}