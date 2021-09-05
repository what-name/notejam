# AUTOSCALING
# ===================================================
autoscaling_min_count = {
  dev  = 0
  test = 0
  prod = 3
}
autoscaling_max_count = {
  dev  = 2
  test = 2
  prod = 6
}

# The statistic to apply to the alarm's associated metric.
# SampleCount, Average, Sum, Minimum, Maximum
autoscaling_alarm_statistic = {
  dev  = "Average"
  test = "Average"
  prod = "Average"
}

# SCALE UP
# ===================================================
# in percentage
autoscaling_cpu_high_threshold = {
  dev  = 80
  test = 80
  prod = 60
}
# in seconds
autoscaling_cpu_high_period = {
  dev  = 60
  test = 60
  prod = 60
}
autoscaling_cpu_high_period_counts = {
  dev  = 2
  test = 2
  prod = 2
}
# Time (in secs) between scaling activities
autoscaling_up_cooldown = {
  dev  = 60
  test = 60
  prod = 60
}
# Number of instances to add
autoscaling_up_adjustment = {
  dev  = 1
  test = 1
  prod = 2
}

# SCALE DOWN
# ===================================================
autoscaling_cpu_low_threshold = {
  dev  = 10
  test = 10
  prod = 10
}
autoscaling_cpu_low_period = {
  dev  = 60
  test = 60
  prod = 60
}
autoscaling_cpu_low_period_counts = {
  dev  = 2
  test = 2
  prod = 2
}
autoscaling_down_cooldown = {
  dev  = 1
  test = 1
  prod = 1
}
autoscaling_down_adjustment = {
  dev  = -1
  test = -1
  prod = -1
}
