gcloud functions deploy get-upload-url \
  {% if cookiecutter.gen2 -%}
  --gen2 \
  {% endif -%}
  {% if 'storage' in cookiecutter.event_type -%}
  --trigger-resource transgate \
  --trigger-event google.storage.object.finalize \
  --trigger-location eu \
  {% else -%}
  --trigger-http \
  {% endif -%}
  --runtime={{ cookiecutter.runtime }} \
  --service-account={{ cookiecutter.service_account_id }}@{{ cookiecutter.gcp_project_id }}.iam.gserviceaccount.com \
  --region="{{ cookiecutter.region }}" \
  --no-allow-unauthenticated \
  --env-vars-file .env.yaml \
  --source=.
