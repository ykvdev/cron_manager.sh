# Cron manager (cron_manager.sh)
Small SH script for managing cron jobs for your any projects. Cron jobs save to crontab using `crontab` command and save to current user crontab file, **this is not required root permissions**.

## How to use

Go to project root directory **necessarily!** Current directory is perceived as project base path and use for add or remove jobs from crontab.
```bash
$ cd /var/www/your-site.com
```

Run the one of available commands: `update` or `clear`.

`update` command using for add/update/remove cron jobs by your config crontab file, example:
```bash
$ sh ./cron_manager.sh update ./crontab
```

`clear` command using for clear all jobs of your project from crontab, example:
```bash
$ sh ./cron_manager.sh clear
```

This is all, good luck!
