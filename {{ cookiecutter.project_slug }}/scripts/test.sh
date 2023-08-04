
#!/bin/bash

CLOUD_URL="https://{{ cookiecutter.project_slug }}-{{ cookiecutter.gcp_project_id }}.run.app"
LOCAL_URL="http://localhost:8080"

# Check if an argument is provided and it is either "prod" or "local"
if [ "$1" == "prod" ]; then
  # Use the CLOUD_URL for "prod"
  URL="$CLOUD_URL"
elif [ "$1" == "local" ]; then
  # Use the LOCAL_URL for "local"
  URL="$LOCAL_URL"
else
  # Invalid argument or no argument provided, use the default LOCAL_URL
  URL="$LOCAL_URL"
fi

# Now you can use the URL variable as needed in your script
echo "Using URL: $URL"

curl --max-time 70 -X POST localhost:8080 \
  {% if 'storage' in cookiecutter.event_type -%}
  -H "ce-id: 123451234512345" \
  -H "ce-specversion: 1.0" \
  -H "ce-time: 2022-12-31T00:00:00.0Z" \
  -H "ce-type: google.cloud.storage.object.v1.finalized" \
  -H "ce-source: //storage.googleapis.com/projects/_/buckets/image_bucket" \
  -H "ce-subject: objects/CF_debugging_architecture.png" \
  -d '{
        "bucket": "image_bucket",
        "contentType": "text/plain",
        "kind": "storage#object",
        "md5Hash": "...",
        "metageneration": "1",
        "name": "CF_debugging_architecture.png",
        "size": "352",
        "storageClass": "MULTI_REGIONAL",
        "timeCreated": "2022-12-31T00:00:00.0Z",
        "timeStorageClassUpdated": "2022-12-31T00:00:00.0Z",
        "updated": "2022-12-31T00:00:00.0Z"
      }' \
  {% endif -%}
  -H "Authorization: bearer $(gcloud auth print-identity-token)" \
  -H "Content-Type: application/json"
