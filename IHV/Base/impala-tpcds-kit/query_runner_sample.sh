# Copyright 2022 Cloudera, Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#!/bin/bash

function timedate() {
    TZ="${TIMEZONE}" date
    echo ""
}

function usageExit() {
    echo "Usage: sh util_runtpcds.sh SCALE FORMAT"
    echo "SCALE must be greater than 1"
    echo "FORMAT must be either 'orc' | 'parquet'"
    exit 1
}

function setupRun() {
    ID=$(TZ="${TIMEZONE}" date +"%m.%d.%Y-%H.%M.%S")

    # --- QUERY FILE NAME ---
    QUERY_BASE_NAME="queries/query"
    QUERY_FILE_EXT=".sql"

    # --- SETTINGS ---
    SETTINGS_PATH="settings.sql"

    # --- REPORT NAME ---
    REPORT_NAME="time_elapsed_Impala_tpcds"

    # --- DATABASE ---
    #DATABASE="pse_tpcds_${SCALE}_${FORMAT}"
    DATABASE="tpcds_100g_parquet"

    # --- CLOCK ---
    CLOCK_FILE="aaa_clocktime.txt"

    if [[ -f "${CLOCK_FILE}" ]]; then
        rm "${CLOCK_FILE}"
        echo "Old clock removed"
    fi
    echo "Created new clock"

    # generate time report
    rm "${REPORT_NAME}"*".csv"
    echo "Old report removed"
    echo "query #", "secs elapsed", "status" > "${REPORT_NAME}.csv"
    echo "New report generated"

    # clear and make new log directory
    if [[ -d log_query/ ]]; then
        rm -r log_query/
        echo "Old logs removed"
    fi
    mkdir log_query/
    echo "Log folder generated"

    # make executable
    chmod +x util_internalRunQuery_impala.sh

    # absolute path
    CURR_DIR="$(pwd)/"
}

function runBenchmark() {
    echo "Run queries for Impala TPC-DS ${FORMAT} at scale ${SCALE}" > "${CLOCK_FILE}"
    timedate >> "${CLOCK_FILE}"

    # range of queries
    START=1
    END=5
    REPEAT=1
    for (( QUERY_NUM = START; QUERY_NUM <= END; QUERY_NUM++ )); do
        for (( j = 0; j < REPEAT; j++ )); do
            query_path=("${QUERY_BASE_NAME}${QUERY_NUM}${QUERY_FILE_EXT}")
            LOG_PATH="log_query/query${QUERY_NUM}_log${j}.txt"
            ./util_internalRunQuery_impala.sh "$DATABASE" "$CURR_DIR$SETTINGS_PATH" "$CURR_DIR$query_path" "$CURR_DIR$LOG_PATH" "$QUERY_NUM" "$CURR_DIR$REPORT_NAME.csv"
        done
    done

    echo "Finished" >> "${CLOCK_FILE}"
    timedate >> "${CLOCK_FILE}"
}

function generateZipReport() {
    # Final report location
    FINAL_REPORT_LOCATION="/tmp/PSE-Benchmarks_PVK/pkatti/TPC-DS/Impala_TPCDS_RESULTS/${SCALE}/"
    hdfs dfs -mkdir -p "${FINAL_REPORT_LOCATION}"
    hdfs dfs -chmod 777 "${FINAL_REPORT_LOCATION}"

    mv "${REPORT_NAME}.csv" "${REPORT_NAME}_${ID}.csv"
    zip -j log_query.zip log_query/*
    zip -r "tpcds-Impala-${SCALE}GB-${ID}.zip" log_query.zip "${REPORT_NAME}_${ID}.csv"
    rm log_query.zip
    hdfs dfs -copyFromLocal "tpcds-Impala-${SCALE}GB-${ID}.zip" "${FINAL_REPORT_LOCATION}tpcds-${SCALE}GB-${ID}.zip"
    echo "The results have been copied to the HDFS location:- ${FINAL_REPORT_LOCATION}tpcds-${SCALE}GB-${ID}.zip "
    echo "Script execution is complete."
}

# --- SCRIPT START ---
SCALE=$1
FORMAT=$2
TIMEZONE="America/Los_Angeles"

if [[ "X$SCALE" == "X" || $SCALE -eq 1 ]]; then
    usageExit
fi
if ! [[ "$SCALE" =~ ^[0-9]+$ ]]; then
    echo "'$SCALE' is not a number!"
    usageExit
fi
if [[ "$FORMAT" != "orc" && "$FORMAT" != "parquet" ]]; then
    usageExit
fi

setupRun

runBenchmark

generateZipReport