import { config, prefixName } from "../utils";
import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

type Args = {
  clusterName: string;
  cluster: aws.ecs.Cluster;
};

export class Ec2Instance {
  private securityGroupName: string;

  securityGroup: aws.ec2.SecurityGroup;
  instance: aws.ec2.Instance;

  constructor({ clusterName, cluster }: Args) {
    const roleName = prefixName("ec2-role");
    const role = new aws.iam.Role(roleName, {
      name: roleName,
      assumeRolePolicy: JSON.stringify({
        Version: "2012-10-17",
        Statement: [
          {
            Action: "sts:AssumeRole",
            Principal: {
              Service: "ec2.amazonaws.com"
            },
            Effect: "Allow",
            Sid: ""
          }
        ]
      })
    });

    new aws.iam.RolePolicyAttachment(`${roleName}-container-service-pa`, {
      role: role.name,
      policyArn:
        "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
    });

    // permissions required: task registration and execution
    new aws.iam.RolePolicyAttachment(`${roleName}-ecs-full-access-pa`, {
      role: role.name,
      policyArn: "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
    });

    new aws.iam.RolePolicyAttachment(`${roleName}-s3-full-access-pa`, {
      role: role.name,
      policyArn: "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    });

    const instanceProfile = new aws.iam.InstanceProfile(
      `${roleName}-instance-profile`,
      {
        role: role.name
      }
    );

    const userData = `#!/bin/bash
        # Run update
        apt-get update

        # Install Docker
        apt-get install -y docker.io

        # Start Docker and enable it to run at startup
        systemctl start docker
        systemctl enable docker

        # Install the ECS agent
        docker run --name ecs-agent --detach=true --restart=unless-stopped --volume=/var/run/docker.sock:/var/run/docker.sock --volume=/var/log/ecs/:/log --volume=/var/lib/ecs/data:/data --net=host --env=ECS_LOGFILE=/log/ecs-agent.log --env=ECS_LOGLEVEL=info --env=ECS_DATADIR=/data --env=ECS_CLUSTER=${clusterName} amazon/amazon-ecs-agent:latest
    `;

    this.securityGroupName = prefixName("ec2-sg");
    this.securityGroup = new aws.ec2.SecurityGroup(this.securityGroupName, {
      name: this.securityGroupName,
      tags: {
        Name: this.securityGroupName
      },
      vpcId: config.require("vpcId")
    });

    new aws.vpc.SecurityGroupIngressRule(
      `${this.securityGroupName}-allow-all-http-ingress-rule`,
      {
        securityGroupId: this.securityGroup.id,
        cidrIpv4: "0.0.0.0/0",
        fromPort: 80,
        ipProtocol: "tcp",
        toPort: 80,
      }
    );

    new aws.vpc.SecurityGroupIngressRule(
      `${this.securityGroupName}-allow-all-https-ingress-rule`,
      {
        securityGroupId: this.securityGroup.id,
        cidrIpv4: "0.0.0.0/0",
        fromPort: 443,
        ipProtocol: "tcp",
        toPort: 443,
      }
    );

    new aws.vpc.SecurityGroupEgressRule(
      `${this.securityGroupName}-allow-all-ipv4-egress-rule`,
      {
        securityGroupId: this.securityGroup.id,
        cidrIpv4: "0.0.0.0/0",
        ipProtocol: "-1"
      }
    );

    const ami = "ami-09f4416095bd1b775"; // ubuntu-server-22-arm for t4g instances

    const ec2Name = prefixName("ec2-instance");
    this.instance = new aws.ec2.Instance(
      ec2Name,
      {
        tags: { Name: ec2Name },
        instanceType: aws.ec2.InstanceType.T4g_Micro,
        ami,
        keyName: config.require("ec2KeyPair"),
        userData,
        iamInstanceProfile: instanceProfile.name,
        vpcSecurityGroupIds: [this.securityGroup.id],
        subnetId: (config.requireObject("publicSubnetIds") as string[])[0],
        metadataOptions: {
          httpEndpoint: "enabled",
          httpTokens: "required"
        } // enable imdsv2
      },
      { dependsOn: [cluster] }
    );
  }
}
