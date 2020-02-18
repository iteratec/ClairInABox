#!/bin/sh

# Setup unique naming scheme
# Note: %3N for getting milliseconds does not work on that base image.
# This means, we cannot start multiple instances of the scanner within one second.
timestamp=`date +"%y%m%d%H%M%S"`
projectName=${PROJECT_NAME}_${timestamp}

networkName=net_${projectName}
dbContainerName=db_${projectName}
scannerContainerName=scanner_${projectName}

clairScannerImage="codebirdone/clair-local-scan"

# TODO: Check variables

# Create network
docker network create "$networkName"
# Connect this container to the network
docker network connect "$networkName" "$(hostname)"

# Get latest clair-db version
docker pull arminc/clair-db:latest
# Starting Clair Database
docker container run --network "$networkName" -d --rm --name "$dbContainerName" arminc/clair-db:latest

# Waiting until Postgres Container is available
until pg_isready --host="$dbContainerName"
do
    echo "waiting for postgres container to become ready..."
    sleep 2
done

# Starting Clair Backend container
docker container run --network "$networkName" -e POSTGRES_HOSTNAME=$dbContainerName -d --rm --name "$scannerContainerName" $clairScannerImage

# Starting Clair scanner
currentIp=$(docker container inspect --format '{{(index .NetworkSettings.Networks "'"$networkName"'").IPAddress}}' $(hostname))

if [ -z "$IMAGE_TO_SCAN_REPO_USERNAME" ];
then
    echo "pull image to scan without authentication ($IMAGE_TO_SCAN)"
    docker pull "$IMAGE_TO_SCAN"
else
    echo "pull image to scan with authentication on repository $IMAGE_TO_SCAN_REPO_URL ($IMAGE_TO_SCAN)"
    docker login -u "$IMAGE_TO_SCAN_REPO_USERNAME" -p "$IMAGE_TO_SCAN_REPO_PASSWORD" "$IMAGE_TO_SCAN_REPO_URL"
    docker pull "$IMAGE_TO_SCAN"
    docker logout "$IMAGE_TO_SCAN_REPO_URL"
fi

if [ -z "$THRESHOLD" ];
then
    echo "Using default threshold 'Unknown'"
    $THRESHOLD = "Unknown"
fi

# Inject whitelist to scanner if provided
echo "Using provided whitelist: $WHITELIST"
if [ -z "$WHITELIST" ];
then
    echo "DEBUG: Proceeding without whitelist"
    /clair-scanner -c http://"$scannerContainerName":6060 --threshold="$THRESHOLD" --ip="$currentIp" -r /result/clair-report.json -l /result/clair-log.log "$IMAGE_TO_SCAN"
else
    whitelistFile=/etc/clair-whitelist.yml
    echo "$WHITELIST" > $whitelistFile
    echo "DEBUG: Content of whitelistfile:"
    cat $whitelistFile
    /clair-scanner -c http://"$scannerContainerName":6060 --threshold="$THRESHOLD" --ip="$currentIp" -r /result/clair-report.json -l /result/clair-log.log -w "$whitelistFile" "$IMAGE_TO_SCAN"
fi

# Capturing the result code of the scan for later to return it as result of the job
return_code=$?

# Convert JSON output to HTML
jq -f jqfilter /result/clair-report.json | mustache - report.mustache > /result/clair-report.html

mkdir -p ./target/clair-result
cp /result/clair-report.json ./target/clair-result/clair-report.json
cp /result/clair-report.html ./target/clair-result/clair-report.html
# Set access rights to the user and group of the workspace
chown -R `stat . -c %u:%g` ./target

# Cleanup of all the containers and the network
docker container stop "$scannerContainerName"
docker container stop "$dbContainerName"
docker network disconnect "$networkName" "$(hostname)"
docker network rm "$networkName"

echo -------- DONE ---------

exit $return_code
