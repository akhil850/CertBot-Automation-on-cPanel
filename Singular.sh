#!/bin/bash
# Written by : https://github.com/akhil850
echo ""
# Performing Renewal.
# An Existing certbot issued certificate required.!!!
echo "Requesting new SSL Certifcate..."
/usr/bin/certbot renew --force-renewal
sleep 5
#Setting paths and variable
echo "Defining Initial Paths...."
pwdd1='/etc/letsencrypt/live/transport.telangana.gov.in/'
pwdd2='/var/cpanel/ssl/apache_tls/transport.telangana.gov.in/'
old_combined_path='/var/cpanel/ssl/apache_tls/transport.telangana.gov.in/combined'
old_certificates_path='/var/cpanel/ssl/apache_tls/transport.telangana.gov.in/certificates'
sleep 3
#Done
cd $pwdd1
echo "Combining files..."
cat privkey.pem cert.pem chain.pem >combined
cat cert.pem chain.pem >certificates
echo "Writing new certificate..."
cat combined > $old_combined_path
cat certificates > $old_certificates_path
sleep 3
cd $pwdd2
echo "Renaming cache files..."
mv combined.cache combined.cache$(date +%d-%m-%Y)
sleep 2
mv certificates.cache certificates.cache$(date +%d-%m-%Y)
echo "Stop/Starting Apache..."
#cPanel based method applied below, change accordingly as per hosting environment.
/scripts/restartsrv_httpd --stop
sleep 5
/scripts/restartsrv_httpd --start
echo "Task Completed."