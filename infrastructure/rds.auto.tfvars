# RDS
# ===================================================
rds_database_name = {
    dev  = "notejam"
    test = "notejam"
    prod = "notejam"
}
rds_master_username = {
    dev  = "notejam_dev"
    test = "notejam_test"
    prod = "notejam_prod"
}
rds_port = {
    dev  = 3306
    test = 3306
    prod = 3306
}
rds_storage_encrypted = {
    dev  = true
    test = true
    prod = true
}

# BACKUP
# ===================================================
# Time in days for backups
rds_backup_retention_period = {
    dev  = 7
    test = 7
    prod = 30
}
rds_preferred_backup_window = {
    dev  = "07:00-09:00"
    test = "07:00-09:00"
    prod = "07:00-09:00"
}
rds_deletion_protection = {
    dev  = false
    test = false
    prod = true
}


# AVAILABILITY
# ===================================================
rds_min_capacity = {
    dev  = 2
    test = 2
    prod = 4
}
rds_max_capacity = {
    dev  = 2
    test = 2
    prod = 10
}
rds_auto_pause = {
    dev  = true
    test = true
    prod = false
}
rds_seconds_until_auto_pause = {
    dev  = 300
    test = 300
    prod = 0
}

