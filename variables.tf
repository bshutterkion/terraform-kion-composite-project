# Organizational Unit (Project) Metadata

variable "project_name" {
  description = "Name of the Project."
  type        = string
}

variable "project_alias" {
  description = "Alias of the Project, used as a prefix for resource names."
  type        = string
}

variable "ou_id" {
  description = "Organizational Unit ID or name where the Project will be a descendant."
  type        = string
}

variable "labels" {
  description = "A map of labels to assign to the Project."
  type = map(object({
    value = string
    color = string
  }))
  default = {}
}

variable "description" {
  description = "Description for the Project."
  type        = string
  default     = null
}

# User Management

variable "owner_user_ids" {
  description = "List of owner user IDs for the Project."
  type        = list(number)
}

variable "owner_user_group_ids" {
  description = "List of owner user group IDs for the Project."
  type        = list(number)
}

variable "idms_id" {
  description = "IDMS ID for the user groups."
  type        = number
  default     = null
}

variable "app_role_id" {
  description = "The application role ID to assign the created user groups."
  type        = number
  default     = null
}

variable "user_groups" {
  description = "List of user groups to create, with IDMS ID, group name, and app role ID."
  type = list(object({
    idms_id     = number
    group_name  = string
    app_role_id = number
  }))
  default = []
}

# AWS/IAM Policies

variable "iam_policies" {
  description = "List of IAM policies to create and attach."
  type = list(object({
    name                 = string
    policy_template      = optional(string)
    attach_to_cloud_rule = optional(bool, false)
    attach_to_car        = optional(string)
    type                 = string
  }))
  default = []
}

# Cloud Access and Rules

variable "permission_scheme_id" {
  description = "Permission scheme ID for the Project."
  type        = number
  default     = 3
}


variable "cloud_access_roles" {
  description = "List of cloud access roles to create."
  type = list(object({
    name              = string
    aws_iam_role_name = string
    aws_iam_policies = object({
      user_managed   = optional(list(object({ template = string })), [])
      system_managed = optional(list(string), [])
    })
    web_access             = optional(bool, true)
    short_term_access_keys = optional(bool, true)
    long_term_access_keys  = optional(bool, false)
    user_groups            = optional(list(string), [])
    users                  = optional(list(string), [])
  }))
  default = []
}

variable "cloud_rule_attachments" {
  description = "Attachments for the cloud rule."
  type = object({
    aws_iam_policies = optional(object({
      user_managed   = optional(list(string))
      system_managed = optional(list(string))
    }))
    compliance_standard = object({
      compliance_checks = object({
        user_managed = list(object({
          template = string
          overrides = optional(object({
            regions               = optional(list(string))
            auto_archive          = optional(bool)
            all_regions           = optional(bool)
            severity              = optional(string)
            frequency             = optional(number)
            frequency_type        = optional(string)
            compliance_check_type = optional(string)
            csp                   = optional(string)
          }))
        }))
        system_managed = list(object({
          template = string
          overrides = optional(object({
            severity       = optional(string)
            frequency      = optional(number)
            frequency_type = optional(string)
          }))
        }))
      })
    })
  })
  default = null
}

variable "cloud_rules" {
  description = "List of cloud rules."
  type = list(object({
    name        = string
    description = optional(string)
    cloud_rule_attachments = optional(object({
      scps = optional(list(string))
      aws_iam_policies = optional(object({
        user_managed   = optional(list(object({ template = string })), [])
        system_managed = optional(list(string), [])
      }))
    }))
    compliance_standards = optional(list(string))
  }))
  default = []
}

# Compliance Settings

variable "compliance_standards" {
  description = "List of compliance standards."
  type = list(object({
    name        = string
    description = optional(string)
    compliance_checks = optional(object({
      user_managed = optional(list(object({
        template = string
        overrides = optional(object({
          regions               = optional(list(string))
          auto_archive          = optional(bool)
          all_regions           = optional(bool)
          severity              = optional(string)
          frequency             = optional(number)
          frequency_type        = optional(string)
          compliance_check_type = optional(string)
          csp                   = optional(string)
        }))
      })), [])
      system_managed = optional(list(object({
        template = string
        overrides = optional(object({
          severity       = optional(string)
          frequency      = optional(number)
          frequency_type = optional(string)
        }))
      })), [])
    }))
  }))
  default = []
  validation {
    condition = alltrue([
      for cs in var.compliance_standards : can(cs.compliance_checks.user_managed) && can(cs.compliance_checks.system_managed)
    ])
    error_message = "Each compliance_standard must have 'user_managed' and 'system_managed' defined as lists."
  }
}

variable "scp_policy" {
  description = "The JSON policy document for the Service Control Policy (SCP)."
  type        = string
  default     = null
}

variable "scp_policy_template" {
  description = "List of paths to template files for the Service Control Policies (SCPs)."
  type        = list(string)
  default     = []
}

# Compliance Check Configuration

variable "cloud_provider_id" {
  description = "The ID of the cloud provider."
  type        = number
  default     = 1
}

variable "compliance_check_type_id" {
  description = "The ID of the compliance check type."
  type        = number
  default     = 2
}

variable "frequency_minutes" {
  description = "Frequency of the compliance check in minutes."
  type        = number
  default     = 60
}

variable "frequency_type_id" {
  description = "The frequency type ID."
  type        = number
  default     = 2
}

variable "is_all_regions" {
  description = "Whether the compliance check applies to all regions."
  type        = bool
  default     = true
}

variable "is_auto_archived" {
  description = "Whether the compliance check is auto-archived."
  type        = bool
  default     = true
}

variable "regions" {
  description = "Regions where the compliance check applies."
  type        = list(string)
  default     = ["us-east-1"]
}

variable "severity_type_id" {
  description = "The severity type ID."
  type        = number
  default     = 3
}
