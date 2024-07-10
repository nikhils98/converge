import { prefixName } from "../utils";
import * as aws from "@pulumi/aws";

export class EcsCluster {
  name: string;
  cluster: aws.ecs.Cluster;

  constructor() {
    this.name = prefixName("cluster");
    this.cluster = new aws.ecs.Cluster(this.name, {
      name: this.name,
    });
  }
}
