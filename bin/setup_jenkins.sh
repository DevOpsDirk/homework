#!/bin/bash
# Setup Jenkins Project
# if [ "$#" -ne 3 ]; then
#    echo "Usage:"
#    echo "  $0 GUID REPO CLUSTER"
#    echo "  Example: $0 wkha https://github.com/redhat-gpte-devopsautomation/advdev_homework_template.git na311.openshift.opentlc.com"
#    exit 1
# fi

# GUID=$1
# REPO=$2
# CLUSTER=$3

export GUID=2c88							# noch an Homework GUID anpassen!
export REPO=https://github.com/DevOpsDirk/homework			# noch an repo anpassen!
export CLUSTER=na311.openshift.opentlc.com				# noch an Homework Cluster anpassen!


echo "Setting up Jenkins in project ${GUID}-jenkins from Git Repo ${REPO} for Cluster ${CLUSTER}"
# Set up Jenkins with sufficient resources
oc new-app --template jenkins-persistent \
   -n $GUID-jenkins \
   -p ENABLE_OAUTH=false \
   -p MEMORY_LIMIT=2Gi \
   -p VOLUME_CAPACITY=4Gi \
   -p DISABLE_ADMINISTRATIVE_MONITORS=true \

# Create custom agent container image with skopeo
oc -n $GUID-jenkins new-build \
			-D $'FROM docker.io/openshift/jenkins-agent-maven-35-centos7:v3.11\n
      			USER root\nRUN yum -y install skopeo && yum clean all\n
      			USER 1001' \
			--name=jenkins-agent-appdev \
			-n ${GUID}-jenkins

# Create pipeline build config pointing to the ${REPO} with contextDir `openshift-tasks`
oc new-build ${REPO} \
   --strategy pipeline \

   --env GUID=${GUID} \
   --env CLUSTER=${CLUSTER} \
   --env NEXUS_RELEASE_URL='http://nexus3.gpte-hw-cicd.svc:8081/repository/releases' \
   --env REPO=${REPO} \
   --context-dir openshift-tasks \

# Make sure that Jenkins is fully up and running before proceeding!
while : ; do
  echo "Checking if Jenkins is Ready..."
  AVAILABLE_REPLICAS=$(oc get dc jenkins -n ${GUID}-jenkins -o=jsonpath='{.status.availableReplicas}')
  if [[ "$AVAILABLE_REPLICAS" == "1" ]]; then
    echo "...Yes. Jenkins is ready."
    break
  fi
  echo "...no. Sleeping 10 seconds."
  sleep 10
done
