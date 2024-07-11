import {
  EcsCluster,
  Ec2Instance,
  EcrRepository,
} from "./resources";

const { repository } = new EcrRepository()
const { name: clusterName, cluster } = new EcsCluster();
const ec2 = new Ec2Instance({ clusterName, cluster });