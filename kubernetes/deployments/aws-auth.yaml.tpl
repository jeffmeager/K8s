mapRoles: |
  - rolearn: ${node_role_arn}
    username: system:node:{{EC2PrivateDNSName}}
    groups:
      - system:bootstrappers
      - system:nodes

  - rolearn: ${admin_role_arn}  # <-- use your SINGLE ARN directly
    username: admin
    groups:
      - system:masters