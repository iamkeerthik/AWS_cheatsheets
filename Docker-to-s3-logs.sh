#!/bin/bash

LOGS_PATH="logs"
LogPattern="<log path inside container>"
container_name_pattern="<container_name>"
bucket="<S3 Bucket folder URI>"

# Find the files matching the pattern and extract the dates inside the container
oldest_date=$(docker exec $(docker ps -aqf "name=$container_name_pattern") sh -c "ls -lt <log path inside container>.*.log | tail -n +2 | sed -E 's/.*hivemq\.([0-9]{4}-[0-9]{2}-[0-9]{2}).*/\1/' | sort | head -n 1")


# Format the oldest date as %Y-%m-%d
start_date=$(date -d "$oldest_date" +%Y-%m-%d)

# Calculate the date two days before the current date
end_date=$(date -d "2 days ago" +%Y-%m-%d)
echo "$start_date"
echo "$end_date"
# Loop through dates and process logs
for date in $(seq $(date -d "$start_date" +%s) 86400 $(date -d "$end_date" +%s)); do
  date1=$(date -d @$date +%Y-%m-%d)

  # Pull log file from container
  if docker cp -a $(docker ps -aqf "name=$container_name_pattern"):$LogPattern.$date1.log $LOGS_PATH/; then
    # Compress log file into ZIP file
    zip_file="hivemq.$date1.zip"
    if zip -r "$LOGS_PATH/$zip_file" "$LOGS_PATH/hivemq.$date1.log"; then
      # Upload ZIP file to S3
      if aws s3 cp "$LOGS_PATH/$zip_file" "s3://$bucket"; then
        # Delete log file from container
        if docker exec $(docker ps -aqf "name=$container_name_pattern") rm "$LogPattern.$date1.log"; then
          echo "Log file processed and deleted for date: $date1"
        else
          echo "Failed to delete log file from container for date: $date1"
        fi
      else
        echo "Failed to upload ZIP file to S3 for date: $date1"
      fi
      rm "$LOGS_PATH/$zip_file"
    else
      echo "Failed to compress log file for date: $date1"
    fi
    rm "$LOGS_PATH/hivemq.$date1.log"
  else
    echo "No log file found for date: $date1. Skipping..."
    continue
  fi
done

echo "All logs processed successfully"
