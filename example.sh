# Go to project root directory necessarily!
cd /var/www/site.com

# Add cron jobs
sh ./cron_manager.sh update ./crontab

# Clear cron jobs
sh ./cron_manager.sh clear
