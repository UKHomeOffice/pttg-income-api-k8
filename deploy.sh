#!/bin/bash
set +x

export KUBE_NAMESPACE=${KUBE_NAMESPACE}
export KUBE_SERVER=${KUBE_SERVER}

if [[ -z ${VERSION} ]] ; then
    export VERSION=${IMAGE_VERSION}
fi

if [[ ${ENVIRONMENT} == "pr" ]] ; then
    echo "deploy ${VERSION} to pr namespace, using PTTG_IP_PR drone secret"
    export KUBE_TOKEN=${PTTG_IP_PR}
    # An empty "downscaler/uptime" annotation is ignored
    export DOWNSCALE_PERIOD=''
    export ARCHIVE_CRON_SCHEDULE='30 7 * * *'
else
    if [[ ${ENVIRONMENT} == "test" ]] ; then
        echo "deploy ${VERSION} to test namespace, using PTTG_IP_TEST drone secret"
        export KUBE_TOKEN=${PTTG_IP_TEST}
    else
        echo "deploy ${VERSION} to dev namespace, using PTTG_IP_DEV drone secret"
        export KUBE_TOKEN=${PTTG_IP_DEV}
    fi
    # Scale down all pods every night in non-prod.
#    export DOWNSCALE_PERIOD='Mon-Sun 19:55:00-20:00 Europe/London'
    export DOWNSCALE_PERIOD='Mon-Sun 14:55:00-15:00 Europe/London'
    # Never run the archive in non-prod.  We don't know if the pods are actually up, and if they are we may as well save the data to test archiving anyway.
#    export ARCHIVE_CRON_SCHEDULE='* * * * 3000'
    export ARCHIVE_CRON_SCHEDULE='30 7 * * *'
fi

if [[ -z ${KUBE_TOKEN} ]] ; then
    echo "Failed to find a value for KUBE_TOKEN - exiting"
    exit -1
fi

cd kd

kd --insecure-skip-tls-verify \
    -f audit-archive-cronjob.yaml \
    -f networkPolicy.yaml \
    -f deployment.yaml \
    -f service.yaml
