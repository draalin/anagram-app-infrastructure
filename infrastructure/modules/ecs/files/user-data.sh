#!/bin/bash

# ECS config
{
  echo "ECS_CLUSTER=${ecs_cluster_name}"
} >> /etc/ecs/ecs.config

start ecs

echo "Done"