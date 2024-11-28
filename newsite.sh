#!/bin/bash

# Base directory for project folders
BASE_DIR="/mnt/g"

# WordPress download URL and temporary location
WP_TEMP_DIR="/mnt/g/wordpress"
WP_URL="https://wordpress.org/latest.tar.gz"

# Check for wget
if ! command -v wget &> /dev/null; then
    echo "Error: wget is not installed. Please install it using 'sudo apt install wget'."
    exit 1
fi

# Function to download WordPress if not already downloaded
download_wordpress() {
    if [ ! -d "$WP_TEMP_DIR" ]; then
        echo "Downloading WordPress..."
        wget -q $WP_URL -O /tmp/latest.tar.gz || { echo "Error downloading WordPress. Exiting."; exit 1; }
        mkdir -p "$WP_TEMP_DIR"
        tar -xzf /tmp/latest.tar.gz -C /tmp || { echo "Error extracting WordPress. Exiting."; exit 1; }
        mv /tmp/wordpress/* "$WP_TEMP_DIR"
        rm -rf /tmp/latest.tar.gz /tmp/wordpress
        echo "WordPress downloaded to $WP_TEMP_DIR."
    else
        echo "WordPress already downloaded at $WP_TEMP_DIR."
    fi
}

# Prompt user for inputs
read -p "Enter project name (e.g., skate): " PROJECT_NAME
read -p "Enter database name (e.g., skate_db): " DB_NAME
read -p "Enter database user (e.g., skate_user): " DB_USER
read -p "Enter database password: " DB_PASSWORD

PROJECT_DIR="$BASE_DIR/$PROJECT_NAME"

# Check if project already exists
if [ -d "$PROJECT_DIR" ]; then
    echo "Project $PROJECT_NAME already exists at $PROJECT_DIR. Exiting."
    exit 1
fi

# Download WordPress
download_wordpress

# Create the project directory and copy WordPress files
echo "Setting up WordPress for $PROJECT_NAME..."
mkdir -p "$PROJECT_DIR"
cp -r "$WP_TEMP_DIR/"* "$PROJECT_DIR"

# Create wp-config.php
echo "Configuring wp-config.php for $PROJECT_NAME..."
cp "$PROJECT_DIR/wp-config-sample.php" "$PROJECT_DIR/wp-config.php"
sed -i "s/database_name_here/$DB_NAME/" "$PROJECT_DIR/wp-config.php"
sed -i "s/username_here/$DB_USER/" "$PROJECT_DIR/wp-config.php"
sed -i "s/password_here/$DB_PASSWORD/" "$PROJECT_DIR/wp-config.php"
sed -i "s/localhost/127.0.0.1/" "$PROJECT_DIR/wp-config.php"

# Set permissions
echo "Setting permissions for $PROJECT_NAME..."
sudo chown -R www-data:www-data "$PROJECT_DIR"
sudo chmod -R 755 "$PROJECT_DIR"

# Set up Apache virtual host
CONF_FILE="/etc/apache2/sites-available/$PROJECT_NAME.conf"
echo "Creating Apache virtual host configuration for $PROJECT_NAME..."
echo "<VirtualHost *:80>
    ServerName $PROJECT_NAME
    DocumentRoot $PROJECT_DIR
    ErrorLog $PROJECT_DIR/logs/${PROJECT_NAME}-error.log
    CustomLog $PROJECT_DIR/logs/${PROJECT_NAME}-access.log combined
    <Directory $PROJECT_DIR>
        AllowOverride All
        Require all granted
        Options Indexes FollowSymLinks
    </Directory>
</VirtualHost>" | sudo tee "$CONF_FILE"

# Enable the site and reload Apache
echo "Enabling site $PROJECT_NAME..."
sudo a2ensite "$PROJECT_NAME.conf"
sudo systemctl reload apache2

# Set up MySQL database
echo "Creating MySQL database and user for $PROJECT_NAME..."
sudo mysql -u root -p <<MYSQL_SCRIPT
CREATE DATABASE $DB_NAME;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

echo "WordPress site for $PROJECT_NAME has been successfully set up!"
echo "You can now access it in your browser after adding '$PROJECT_NAME' to your /etc/hosts file."
