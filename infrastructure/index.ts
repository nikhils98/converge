import {
  EcsCluster,
  Ec2Instance,
  EcrRepository,
  ServerEcsService,
} from "./resources";

const { repository } = new EcrRepository()
const { name: clusterName, cluster } = new EcsCluster();
const { instance } = new Ec2Instance({ clusterName, cluster });
const server = new ServerEcsService({
  clusterId: cluster.id,
  instance,
  repository
})