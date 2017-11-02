#!/bin/bash

FROM_OWNER="flyTEM"
FROM_PROJECT="FAFB00"
FROM_STACK="v12_acquire_merged"

MIN_Z="1949"
MAX_Z="1957"

TO_OWNER="flyTEM"
TO_PROJECT="khairyk_stage"
TO_STACK="z_${MIN_Z}_${MAX_Z}_acquire"

# ------------------------------------------------------------------------------------
# you should be able to leave the rest as-is ...

ARGS="--baseDataUrl http://tem-services:8080/render-ws/v1"
ARGS="${ARGS} --owner ${FROM_OWNER} --project ${FROM_PROJECT} --fromStack ${FROM_STACK}"
ARGS="${ARGS} --toOwner ${TO_OWNER} --toProject ${TO_PROJECT} --toStack ${TO_STACK}"
ARGS="${ARGS} --replaceLastTransformWithStage --splitMergedSections"
ARGS="${ARGS} --completeToStackAfterCopy"

for Z in `seq ${MIN_Z} ${MAX_Z}`; do
  ARGS="${ARGS} --z ${Z}"
done

/groups/flyTEM/flyTEM/render/bin/copy-layer.sh ${ARGS}
