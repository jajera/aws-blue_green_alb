# aws-blue_green_alb

# Commands
# Shift traffic to green environment
```sh
terraform apply -var 'traffic_distribution=blue-90'
```

# Verify canary deployment traffic
```sh
for i in `seq 1 10`; do curl $(terraform output -raw lb_dns_name); done
```

# Increase traffic to green environment
```sh
terraform apply -var 'traffic_distribution=split'
```

# Verify rolling deployment traffic
```sh
for i in `seq 1 10`; do curl $(terraform output -raw lb_dns_name); done
```

# Promote green environment
```sh
terraform apply -var 'traffic_distribution=green'
```

# Verify load balancer traffic
```sh
for i in `seq 1 5`; do curl $(terraform output -raw lb_dns_name); done
```

# Scale down blue environment
```sh
terraform apply -var 'traffic_distribution=green' -var 'enable_blue_env=false'
```

# Enable new version environment
```sh
terraform apply -var 'traffic_distribution=green'
```

# Start shifting traffic to blue environment
```sh
terraform apply -var 'traffic_distribution=green-90'
```

# Verify that your load balancer is routing all traffic to the green environment
```sh
for i in `seq 1 10`; do curl $(terraform output -raw lb_dns_name); done
```

# Promote blue environment
```sh
terraform apply -var 'traffic_distribution=blue'
```

# Verify that your load balancer is routing all traffic to the blue environment
```sh
for i in `seq 1 5`; do curl $(terraform output -raw lb_dns_name); done
```
