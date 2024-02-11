# HSA28

Autoscale groups

# Autoscale groups on AWS

This template contains Terraform configuration for set up of AWS Autoscale Group `aws_autoscaling_group` for defined template `aws_launch_template`

The autoscale group is designed to work with 1 on-demand and any amount of spot instances, which is defined by `instances_distribution`

#### `! The load balancer must be specified separately to properly track incoming traffic. It is not included in this template

### Autoscaling policies
In this example, provider 2 policies `aws_autoscaling_policy.` Each policy monitors  `aws_cloudwatch_metric_alarm` to scale up the group:

1. `hsa28_scale_up_cpu` provides simple scaling on 1 instance each time AVG CPU usage hits 50%
2. `hsa28_scale_up_requests` provides step scaling  
based on the number of requests tracked: 1 instance for  up to 2000 requests, 2 instances for up to 3000, and 3 instances if more than 3000 requests are tracked