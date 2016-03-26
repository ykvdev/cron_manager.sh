#!/bin/bash

CMD_UPDATE="update"
CMD_CLEAR="clear"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

IFS='
'

output_info () {
    echo "$GREEN[INFO] $1$NC"
}

output_notice () {
    echo "$YELLOW[NOTICE] $1$NC"
}

output_error () {
    echo "$RED[ERROR] $1$NC"
}

output_help () {
    output_info "Available commands:"
    output_info "update /path/to/project/crontab - for update project crontab file with current user crontab"
    output_info "clear - for remove all project cron jobs from current user crontab"
}

ereg_quote() {
    printf %s "$1" | sed 's/[][()\.^$?*+]/\\&/g'
}

if [ "$1" != "$CMD_UPDATE" -a "$1" != "$CMD_CLEAR" ]; then
    output_error "You are not specified command"
    output_help
    exit 1
fi

if [ "$1" = "$CMD_UPDATE" -a -z "$2" ]; then
    output_error "You are not specified project crontab file"
    output_help    
    exit 1
fi

if [ "$1" = "$CMD_UPDATE" -a ! -e "$2" ]; then
    output_error "Specified file not found"
    exit 1
fi

old_cron_contents=`crontab -l`
removed_jobs_count=0
added_jobs_count=0
project_dir="`pwd`"

output_info "Current user is $USER"
output_info "Current project directory is $project_dir"

# Check crontab tmp file
tmp_cron_path="/tmp/crontab.$USER"
wait_counter=0
while [ -e "$tmp_cron_path" ]; do
    output_info "Wait for unlock file $tmp_cron_path by other script"

    wait_counter=$((wait_counter+1))
    if [ "$wait_counter" -eq 5 ]; then
        output_error "File $tmp_cron_path is locked by other script"
        exit 1
    fi

    sleep 5
done
output_info "File $tmp_cron_path is unlocked"

# Create crontab tmp file
touch "$tmp_cron_path"

# Run clear command if need
if [ "$1" = "$CMD_CLEAR" ]; then
    # Remove project jobs from current user cron file
    for line in `echo "$old_cron_contents" | grep -vE "^\s*$"`
    do
        if [ `echo "$line" | grep -c "$project_dir"` -ne 0 ]; then
            output_notice "Removed: $line"
            removed_jobs_count=$((removed_jobs_count+1))
        else
            echo "$line" >> "$tmp_cron_path"
        fi
    done
fi

# Run update command if need
if [ "$1" = "$CMD_UPDATE" ]; then
    cron_config_contents=`cat "$2"`

    # Remove old project scripts from current user cron file
    for line in `echo "$old_cron_contents" | grep -vE "^\s*$"`
    do
        if [ `echo "$line" | grep -c "$project_dir"` -ne 0 -a `echo "$cron_config_contents" | grep -cE "^$(ereg_quote "$line")$"` -eq 0 ]; then
            output_notice "Removed: $line"
            removed_jobs_count=$((removed_jobs_count+1))
        else            
            echo "$line" >> "$tmp_cron_path"
        fi
    done

    # Add updated project scripts to current user cron file
    added_jobs_count=0
    for line in `echo "$cron_config_contents" | grep -vE "^#.*|^\s*$"`
    do
        if [ `echo "$old_cron_contents" | grep -cE "^$(ereg_quote "$line")$"` -eq 0 ]; then
            echo "$line" >> "$tmp_cron_path"
            output_notice "Added: $line"
            added_jobs_count=$((added_jobs_count+1))
        fi
    done
fi

# Update current user cron file if need
if [ "$removed_jobs_count" -ne 0 -o "$added_jobs_count" -ne 0 ]; then
    update_result=`crontab "$tmp_cron_path" 2>&1`
    if [ -z "$update_result" ]; then
        output_notice "Current user crontab file has been updated: +$added_jobs_count -$removed_jobs_count"
    else
        output_error "Crontab update error:\n$update_result"
    fi
else
    output_notice "Nothing to update"
fi

# Remove tmp cron file
rm "$tmp_cron_path"

unset IFS

exit 0
