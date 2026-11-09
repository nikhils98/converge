import * as pulumi from "@pulumi/pulumi";

const PROJECT_NAME = pulumi.getProject();
const STACK_NAME = pulumi.getStack();

export const config = new pulumi.Config();

export function prefixName(name?: string): string {
  const prefix = `${PROJECT_NAME}-${STACK_NAME}`;
  return name ? `${prefix}-${name}` : prefix;
}
