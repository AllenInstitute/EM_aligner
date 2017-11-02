#!/bin/bash

#--------------------------------------
# set up global parameters
#--------------------------------------

OWNER="flyTEM"                            # owner of render stacks and match collections
LOCATION_PROJECT="test"                 # project of render stack used for tile locations
LOCATION_STACK="temp_rough_slab"                # render stack used for tile locations
MIN_Z="102019"                                 # minimum z value for layers to include in potential tile pairs 
MAX_Z="102022"                               # maximum z value for layers to include in potential tile pairs

RENDER_PROJECT="khairyk_stage"                   # project of render stack used for rendering during point match derivation
RENDER_STACK="z_1949_1957_acquire"         # render stack used for rendering during point match derivation

# base command for running the tile pair client
BASE_CMD="/groups/flyTEM/flyTEM/render/pipeline/bin/run_ws_client.sh 6G org.janelia.render.client.TilePairClient"
LOG_DIR="logs"
RUN_TIME=`date +"%Y%m%d_%H%M%S"`
PAIR_GEN_LOG="${LOG_DIR}/tile_pairs-${RUN_TIME}.log"

mkdir -p ${LOG_DIR}

#--------------------------------------
# generate within-layer potential pairs
#--------------------------------------

DISTANCE="0"                              # distance in z from each layer to look for potential tile pairs 

# xyNeighborFactor is used to determine radial distance from tile center to look for potential pairs
FILTER_OPTS="--xyNeighborFactor 0.6 --excludeCornerNeighbors true --excludeSameLayerNeighbors false --excludeCompletelyObscuredTiles true"
                                          
P1="--baseDataUrl http://10.40.3.162:8080/render-ws/v1 --owner ${OWNER} --project ${LOCATION_PROJECT}"
P2="--baseProject ${RENDER_PROJECT} --baseStack ${RENDER_STACK} --stack ${LOCATION_STACK}"
P3="--minZ ${MIN_Z} --maxZ ${MAX_Z}"
JSON_FILE="tile_pairs_${LOCATION_STACK}_z_${MIN_Z}_to_${MAX_Z}_dist_${DISTANCE}.json.gz"

${BASE_CMD} ${P1} ${P2} ${P3} ${FILTER_OPTS} --zNeighborDistance ${DISTANCE} --toJson ${JSON_FILE} | tee -a ${PAIR_GEN_LOG}

#--------------------------------------
# generate outside-layer potential pairs
#--------------------------------------

# exit 0  # NOTE: exit here since cross layer pairs don't make sense before stack is rough aligned

DISTANCE="4"
FILTER_OPTS="--xyNeighborFactor 0.6 --excludeCornerNeighbors false --excludeSameLayerNeighbors true --excludeCompletelyObscuredTiles true"
JSON_FILE="tile_pairs_${LOCATION_STACK}_z_${MIN_Z}_to_${MAX_Z}_dist_${DISTANCE}.json.gz"

${BASE_CMD} ${P1} ${P2} ${P3} ${FILTER_OPTS} --zNeighborDistance ${DISTANCE} --toJson ${JSON_FILE} | tee -a ${PAIR_GEN_LOG}
