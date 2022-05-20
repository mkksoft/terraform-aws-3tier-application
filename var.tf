variable "vpc_data" {
  description = "VPC related data"
  type = object({
    cidr_block = string
    name       = string
    public_subnets = map(object({
      sub_cidr_block    = string
      sub_cidr_name     = string
      az_name = string
      availability_zone = string
    }))
    private_subnets = map(object({
      sub_cidr_block    = string
      sub_cidr_name     = string
      az_name = string
      availability_zone = string
    }))
    db_subnets = map(object({
      sub_cidr_block    = string
      sub_cidr_name     = string
      az_name = string
      availability_zone = string
    }))
  })
  default = {
    cidr_block = "10.0.0.0/16"
    name       = "SIT"
    public_subnets = {
      "pub2a" = {
        sub_cidr_block    = "10.0.0.0/20"
        sub_cidr_name     = "PUBLIC/2A"
        az_name      = "AZ1"
        availability_zone = "us-west-2a"
      },
      "pub2b" = {
        sub_cidr_block    = "10.0.16.0/20"
        sub_cidr_name     = "PUBLIC/2B"
        az_name      = "AZ2"
        availability_zone = "us-west-2b"
      },
      "pub2c" = {
        sub_cidr_block    = "10.0.32.0/20"
        sub_cidr_name     = "PUBLIC/2C"
        az_name      = "AZ3"
        availability_zone = "us-west-2c"
      }
    }
   private_subnets = {
      "pvt2a" = {
        sub_cidr_block    = "10.0.48.0/20"
        sub_cidr_name     = "PRIVATE/2A"
        az_name      = "AZ1"
        availability_zone = "us-west-2a"
      },
      "pvt2b" = {
        sub_cidr_block    = "10.0.64.0/20"
        sub_cidr_name     = "PRIVATE/2B"
        az_name      = "AZ2"
        availability_zone = "us-west-2b"
      },
      "pvt2c" = {
        sub_cidr_block    = "10.0.80.0/20"
        sub_cidr_name     = "PRIVATE/2C"
        az_name      = "AZ3"
        availability_zone = "us-west-2c"
      }
    }
   db_subnets = {    
      "db2a" = {
        sub_cidr_block    = "10.0.96.0/20"
        sub_cidr_name     = "DB/2A"
        az_name      = "AZ1"
        availability_zone = "us-west-2a"
      },
      "db2b" = {
        sub_cidr_block    = "10.0.112.0/20"
        sub_cidr_name     = "DB/2B"
        az_name      = "AZ2"
        availability_zone = "us-west-2b"
      },
      "db2c" = {
        sub_cidr_block    = "10.0.128.0/20"
        sub_cidr_name     = "DB/2C"
        az_name      = "AZ3"
        availability_zone = "us-west-2c"
      }
    }
  }
}

variable "environment" {
  description = "Value for environment name"
  type        = string

  validation {
    condition     = contains(["SIT", "UAT", "PROD"], var.environment)
    error_message = "Valid values for var: environment are (SIT, UAT, PROD)."
  }
  default = "SIT"

}

variable "module_spec" {
  type = map(object({
    module_name = string
    env_prefix  = string
    tgs = map(object({
      name = string
      port = number
    }))
  }))
  default = {
    "SIT" = {
      module_name = "WEBAPP"
      env_prefix  = "S"
      tgs = {
        "tg1" = {
          name = "WEB-APP"
          port = 80
        }
      }
    }
  }
}

variable "project_name" {
  type    = string
  default = "WEBAPP"
}

locals {
  additional_tags = {
    Env         = "${var.environment}",
    Org         = "SB",
    ProjectName = "WEBAPP"
  }
}

variable "rds_data" {
  description = "RDS attributes"
  type = object({
    identifier                            = string
    instance_class                        = string
    engine                                = string
    engine_version                        = string
    allocated_storage                     = number
    max_allocated_storage                 = number
    db_name                               = string
    username                              = string
    port                                  = number
    multi_az                              = bool
    maintenance_window                    = string
    backup_window                         = string
    backup_retention_period               = number
    skip_final_snapshot                   = bool
    performance_insights_enabled          = bool
    performance_insights_retention_period = number
    storage_encrypted                     = bool
  })
  default = {
    identifier                            = "sit-sb-webapp"
    parameter_group_name                  = "postgres14"
    instance_class                        = "db.t4g.large"
    engine                                = "postgres"
    engine_version                        = "14.1"
    allocated_storage                     = 20
    max_allocated_storage                 = 100
    db_name                               = "sbwebapp"
    username                              = "mahout"
    port                                  = 5432
    multi_az                              = true
    maintenance_window                    = "Mon:00:00-Mon:03:00"
    backup_window                         = "03:00-06:00"
    backup_retention_period               = 5
    skip_final_snapshot                   = true
    performance_insights_enabled          = true
    performance_insights_retention_period = 7
    storage_encrypted                     = true
  }
}

variable "ec2_data" {
  description = "EC2 attributes"
  type = object({
    ami           = string
    instance_type = string
    port          = number
    subnet_ids = map(object({
      subnet_id = string
      name      = string
    }))
    root_volume = map(object({
      size = number
      type = string
    }))
  })
  default = {
    ami           = "ami-0ca285d4c2cda3300"
    instance_type = "c4.large"
    port          = 80
    subnet_ids = {
      "AZ1" = {
        subnet_id = "subnet-0fb3da42b0924c4db"
        name      = "AZ1"
      },
      "AZ2" = {
        subnet_id = "subnet-0235bf3913698e56c"
        name      = "AZ2"
      },
      "AZ3" = {
        subnet_id = "subnet-04bd1d41659a5e28e"
        name      = "AZ3"
      }
    }
    root_volume = {
      "volume1" = {
        size = 50
        type = "gp3"
      }
    }
  }
}