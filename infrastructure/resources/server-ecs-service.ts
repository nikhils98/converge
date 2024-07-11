import { config, prefixName } from "../utils";
import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

type Args = {
  clusterId: pulumi.Output<string>;
  instance: aws.ec2.Instance;
  repository: aws.ecr.Repository
};

export class ServerEcsService {
  service: aws.ecs.Service;

  constructor({ clusterId, instance, repository }: Args) {
    const roleName = prefixName("server-task-execution-role");
    const role = new aws.iam.Role(roleName, {
      name: roleName,
      assumeRolePolicy: JSON.stringify({
        Version: "2012-10-17",
        Statement: [
          {
            Effect: "Allow",
            Principal: { Service: "ecs-tasks.amazonaws.com" },
            Action: "sts:AssumeRole"
          }
        ]
      })
    });

    new aws.iam.RolePolicyAttachment(`${roleName}-cwl-full-access-pa`, {
      role: role.name,
      policyArn: "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
    });

    new aws.iam.RolePolicyAttachment(`${roleName}-ecs-task-exec-pa`, {
      role: role.name,
      policyArn:
        "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
    });

    const containerName = prefixName("server");
    const taskDef = new aws.ecs.TaskDefinition(`${containerName}-task-def`, {
      family: containerName,
      networkMode: "host",
      requiresCompatibilities: ["EC2"],
      executionRoleArn: role.arn,
      containerDefinitions: repository.repositoryUrl.apply(repoUrl =>
        JSON.stringify([
          {
            name: containerName,
            image: `${repoUrl}:latest`,
            cpu: 512,
            memory: 512,
            portMappings: [
              { containerPort: 8080, hostPort: 8080, protocol: "tcp" }
            ],
            environment: []
          }
        ])),
    });

    this.service = new aws.ecs.Service(
      prefixName("server-ecs-service"),
      {
        name: containerName,
        cluster: clusterId,
        schedulingStrategy: "DAEMON",
        launchType: "EC2",
        taskDefinition: taskDef.arn
      },
      {
        dependsOn: [instance]
      }
    );
  }
}
