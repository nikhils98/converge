import { prefixName } from "../utils";
import * as aws from "@pulumi/aws";

export class EcrRepository {
  repository: aws.ecr.Repository

  constructor() {
    const repoName = prefixName()
    const resourceName = prefixName("ecr-repository")

    this.repository = new aws.ecr.Repository(
      resourceName,
      {
        name: repoName
      }
    )

    new aws.ecr.LifecyclePolicy(
      `${resourceName}-lifecycle-policy`,
      {
        repository: this.repository.name,
        policy: {
          rules: [
            {
              rulePriority: 1,
              description: "Expire older images",
              selection: {
                tagStatus: "any",
                countType: "imageCountMoreThan",
                countNumber: 20
              },
              action: {
                type: "expire"
              }
            }
          ]
        }
      }
    )
  }
}
