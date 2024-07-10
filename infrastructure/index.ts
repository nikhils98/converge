import {
  EcsCluster,
  Ec2Instance,
} from "./resources";

const { name: clusterName, cluster } = new EcsCluster();
const ec2 = new Ec2Instance({ clusterName, cluster });