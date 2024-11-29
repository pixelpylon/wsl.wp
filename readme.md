# Setting Up WordPress Development Environment with WSL2

## 1. Install Required Software on WSL2

First, update your Ubuntu system:
```bash
sudo apt update && sudo apt upgrade -y
```

Install Apache, PHP, MySQL, and required PHP extensions:
```bash
sudo apt install apache2 mysql-server php php-mysql php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip phpmyadmin -y
```

## 2. Configure Apache

Enable required Apache modules:
```bash
sudo a2enmod rewrite
sudo service apache2 restart
```

Set proper permissions for web directory:
```bash
sudo chown -R $USER:www-data /var/www/html
sudo chmod -R 755 /var/www/html
```

## 3. Configure MySQL

Start MySQL service:
```bash
sudo service mysql start
```

Secure MySQL installation:
```bash
sudo mysql_secure_installation
```

Create a database and user for WordPress:
```sql
sudo mysql -u root -p
CREATE DATABASE wordpress;
CREATE USER 'wpuser'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

## 4. Install WordPress

Download and set up WordPress:
```bash
cd /var/www/html
sudo rm index.html
wget https://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz
sudo mv wordpress/* .
sudo rm -rf wordpress latest.tar.gz
```

Create and configure wp-config.php:
```bash
cp wp-config-sample.php wp-config.php
```

Edit wp-config.php with your database details:
```php
define('DB_NAME', 'wordpress');
define('DB_USER', 'wpuser');
define('DB_PASSWORD', 'your_password');
```

Set proper permissions:
```bash
sudo chown -R www-data:www-data /var/www/html
sudo find /var/www/html -type d -exec chmod 755 {} \;
sudo find /var/www/html -type f -exec chmod 644 {} \;
```

## 5. Configure Local Domain

### In Windows (as administrator)
Edit `C:\Windows\System32\drivers\etc\hosts` file and add:
```
127.0.0.1 example.local
```

### In WSL2 Apache
Create a new virtual host configuration:
```bash
sudo nano /etc/apache2/sites-available/example.local.conf
```

Add the following configuration:
```apache
<VirtualHost *:80>
    ServerAdmin webmaster@example.local
    ServerName example.local
    DocumentRoot /var/www/html
    
    <Directory /var/www/html>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```

Enable the site and restart Apache:
```bash
sudo a2ensite example.local.conf
sudo service apache2 restart
```

## 6. Access phpMyAdmin

PhpMyAdmin should be available at:
```
http://example.local/phpmyadmin
```

## 7. Complete WordPress Installation

1. Visit `http://example.local` in your browser
2. Follow the WordPress installation wizard
3. Enter your site information:
   - Site Title
   - Admin Username
   - Password
   - Email

## Troubleshooting Tips

If the site isn't accessible:
1. Check Apache status: `sudo service apache2 status`
2. Check MySQL status: `sudo service mysql status`
3. Verify hosts file entry in Windows
4. Check Apache error logs: `sudo tail -f /var/log/apache2/error.log`

Remember to start required services after each WSL restart:
```bash
sudo service apache2 start
sudo service mysql start
```