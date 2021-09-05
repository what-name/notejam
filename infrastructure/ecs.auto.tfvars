# ECS WORKER
# ===================================================
worker_cpu = {
    dev  = 256
    test = 256
    prod = 512
}
worker_memory = {
    dev  = 512
    test = 512
    prod = 1024
}
worker_port = {
    dev  = 8000
    test = 8000
    prod = 8000
}


# PUBLIC IP
# ===================================================
worker_assign_public_ip = {
    dev  = false
    test = false
    prod = false
}



# DEPLOYMENT
# ===================================================
# Min healthy ecs tasks during deployment
worker_deployment_min_healthy = {
    dev  = 0
    test = 0
    prod = 100
}
# Max healthy ecs tasks during deployment
worker_deployment_max_healthy = {
    dev  = 100
    test = 100
    prod = 200
}
# Time (secs) to wait after ecs task startup
# before running health checks
worker_health_check_grace_period = {
    dev  = 0
    test = 0
    prod = 30
}

worker_images_to_keep = {
    dev  = 5
    test = 5
    prod = 20
}