#!/bin/bash

ABSOLUTE_SCRIPT=`readlink -m $0`
SCRIPT_DIR=`dirname ${ABSOLUTE_SCRIPT}`

# ==========================================================================
# Change these parameters for each run ...

export BILL_TO="flyTEM"
export JOB_RUN_TIME="1814400" # 86400 seconds per day * 21 days = 1814400 second hard runtime

# source data parameters
SERVICE_HOST="10.40.3.162:8080"      # use IP address for tem-services until DNS issue is resolved
MATCH_OWNER="khairyk"
MATCH_COLLECTION="merge_work"

for JSON_FILE in `ls ${SCRIPT_DIR}/tile_pairs_*.json*`; do
  PAIR_JSON_ARGS="${PAIR_JSON_ARGS} --pairJson ${JSON_FILE}"
done

# Default SIFT parameters are:
#   --renderWithFilter true 
#   --renderWithoutMask true 
#   --renderScale 1.0 
#   --fillWithNoise true
#   --SIFTfdSize 8
#   --SIFTminScale 0.5
#   --SIFTmaxScale 0.85
#   --SIFTsteps 3
SIFT_PARAMETERS="--SIFTminScale 0.48 --renderScale 0.6 --SIFTmaxScale 0.62 --SIFTsteps 3"

# Default match filtering parameters are:
#   --matchRod 0.92
#   --matchMaxEpsilon 20.0
#   --matchMinInlierRatio 0.0
#   --matchMinNumInliers 10
MATCH_FILTER_PARAMETERS="--matchRod 0.8 --matchMaxEpsilon 20.0 --matchMinInlierRatio 0.0 --matchMinNumInliers 8 --matchMaxNumInliers 40"

# To be nice to others, avoid requesting more than 60 nodes.
# When the cluster is busy, you may want to decrease node count to get running since
# Spark job won't start until number of requested nodes are available.
NUMBER_OF_SPARK_NODES=20

# ==========================================================================
# You should be able to leave everything under here as is ...

# ==========================================================================
# setup output directory
# (NOTE: you can leave this as is if output can go to the standard location)
# ==========================================================================

YEAR_MONTH=`date +"%Y%m"`
DAY=`date +"%d"`
TIME=`date +"%H%M%S"`

export SPARK_OUTPUT_DIR="/groups/flyTEM/flyTEM/spark/work/${USER}/${YEAR_MONTH}/${DAY}/${TIME}_$$"
export MASTER_ENV_FILE="${SPARK_OUTPUT_DIR}/master_env.sh"

export LOG_DIR="${SPARK_OUTPUT_DIR}/logs"
export TMP="${SPARK_OUTPUT_DIR}/tmp"

echo """
  creating ${SPARK_OUTPUT_DIR}
"""

mkdir -p ${SPARK_OUTPUT_DIR}

# ==========================================================================
# build java args and launch spark
# (NOTE: you should not need to modify anything below)
# ==========================================================================

echo """
  launching Spark job
"""

JAR="/groups/flyTEM/flyTEM/render/lib/current-spark-standalone.jar"
CLASS="org.janelia.render.client.spark.SIFTPointMatchClient"

ARGV="--baseDataUrl http://${SERVICE_HOST}/render-ws/v1 --owner ${MATCH_OWNER} --collection ${MATCH_COLLECTION}"
ARGV="${ARGV} ${SIFT_PARAMETERS} ${MATCH_FILTER_PARAMETERS} --maxFeatureCacheGb 15 ${PAIR_JSON_ARGS}"

/groups/flyTEM/flyTEM/render/spark/bin/inflame.sh ${NUMBER_OF_SPARK_NODES} ${JAR} ${CLASS} ${ARGV}

# from /usr/local/spark-current/conf/spark-env.sh
LIKELY_SPARK_LOG_DIR=~/.spark/logs/$(date +%H-%F)

sleep 2

mkdir -p logs
SPARK_LAUNCH_LOG="logs/spark_launch.log"

qstat | grep spark | tee -a ${SPARK_LAUNCH_LOG}

echo """
  cluster logs will be written to ${LOG_DIR}

  internal spark logs will likely be written to ${LIKELY_SPARK_LOG_DIR}

""" | tee -a ${SPARK_LAUNCH_LOG}
