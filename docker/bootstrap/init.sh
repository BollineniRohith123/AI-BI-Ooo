#!/bin/sh
set -e  # Exit on any error

# declare a variable from the environment variable: DATA_PATH
data_path=${DATA_PATH:-"./"}
echo "Starting bootstrap process with data path: ${data_path}"

# Create a flag file to indicate initialization is in progress
touch ${data_path}/.initializing

# touch a empty config.properties if not exists
# put a content into config.properties if not exists
if [ ! -f ${data_path}/config.properties ]; then
  echo "Initializing config.properties"
  echo "node.environment=production" > ${data_path}/config.properties
  echo "# Created on $(date)" >> ${data_path}/config.properties
fi

# after the config.properties is created, check if config properties properly set
# if not, then append default values to the config.properties
# check if wren.experimental-enable-dynamic-fields is set, otherwise append it with true
if ! grep -q "wren.experimental-enable-dynamic-fields" ${data_path}/config.properties; then
  echo "Setting wren.experimental-enable-dynamic-fields to true"
  echo "wren.experimental-enable-dynamic-fields=true" >> ${data_path}/config.properties
fi

# create a folder mdl if not exists
if [ ! -d ${data_path}/mdl ]; then
  echo "Creating mdl folder"
  mkdir -p ${data_path}/mdl
fi

# put a empty sample.json if not exists
if [ ! -f ${data_path}/mdl/sample.json ]; then
  echo "Initializing mdl/sample.json"
  echo "{\"catalog\": \"test_catalog\", \"schema\": \"test_schema\", \"models\": []}" > ${data_path}/mdl/sample.json
fi

# Create initialization flag file
echo "Finished bootstrap on $(date)" > ${data_path}/.initialized
rm -f ${data_path}/.initializing

echo "Bootstrap process completed successfully"
