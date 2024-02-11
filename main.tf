terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.36"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_launch_template" "hsa28_template" {
  name_prefix   = "hsa28"
  image_id      = "ami-0bbebc09f0a12d4d9"
  instance_type = "t4g.micro"
}

resource "aws_autoscaling_group" "hsa28_autoscale" {
  name                 = "hsa28-autoscaling-group"
  availability_zones   = ["us-east-1a", "us-east-1b"]
  desired_capacity     = 1
  max_size             = 5
  min_size             = 1
  health_check_type    = "EC2"
  termination_policies = ["OldestInstance"]

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.hsa28_template.id
        version = "$Latest"
      }
    }

    instances_distribution {
      on_demand_base_capacity = 1
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy = "lowest-price"
    }
  }
}

resource "aws_autoscaling_policy" "hsa28_scale_up_cpu" {
  name                   = "hsa28_scale_up_cpu"
  autoscaling_group_name = aws_autoscaling_group.hsa28_autoscale.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 120
}

resource "aws_autoscaling_policy" "hsa28_scale_up_requests" {
  name                   = "hsa28_scale_up_requests"
  autoscaling_group_name = aws_autoscaling_group.hsa28_autoscale.name
  adjustment_type        = "ChangeInCapacity"
  policy_type = "StepScaling"

  step_adjustment {
    scaling_adjustment          = 1
    metric_interval_lower_bound = 1000
    metric_interval_upper_bound = 2000
  }

  step_adjustment {
    scaling_adjustment          = 2
    metric_interval_lower_bound = 2000
    metric_interval_upper_bound = 3000
  }

  step_adjustment {
    scaling_adjustment          = 3
    metric_interval_lower_bound = 3000
  }

}

resource "aws_cloudwatch_metric_alarm" "hsa28_scale_up_cpu" {
  alarm_description   = "HSA28 CPU utilization"
  alarm_actions       = [aws_autoscaling_policy.hsa28_scale_up_cpu.arn]
  alarm_name          = "hsa28_scale_up_cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  threshold           = "50"
  evaluation_periods  = "5"
  period              = "30"
  statistic           = "Average"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.hsa28_autoscale.name
  }
}

resource "aws_cloudwatch_metric_alarm" "hsa28_scale_up_requests" {
  alarm_description   = "HSA28 Requests"
  alarm_actions       = [aws_autoscaling_policy.hsa28_scale_up_requests.arn]
  alarm_name          = "hsa28_scale_up_requests"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "RequestCount"
  threshold           = "1000"
  evaluation_periods  = "5"
  period              = "30"
  statistic           = "SampleCount"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.hsa28_autoscale.name
  }
}


