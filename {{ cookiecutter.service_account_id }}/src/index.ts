{% if 'storage' in cookiecutter.event_type -%}
import { cloudEvent, CloudEvent } from "@google-cloud/functions-framework"
import { StorageObjectData } from "@google/events/cloud/storage/v1/StorageObjectData"
{% else -%}
import { http, Request, Response } from "@google-cloud/functions-framework"
{% endif %}
{% if 'storage' in cookiecutter.event_type -%}
async function {{ cookiecutter.project_slug }}(cloudevent: CloudEvent<StorageObjectData>) {
  console.log("---------------\nProcessing for ", cloudevent.subject, "\n---------------")

  if (!cloudevent.data) {
    throw "CloudEvent does not contain data."
  }

  const filePath = `${cloudevent.data.bucket}/${cloudevent.data.name}`
}

cloudEvent("{{ cookiecutter.project_slug }}", {{ cookiecutter.project_slug }})
{% else -%}
async function {{ cookiecutter.project_slug }}(req: Request, res: Response) {
  res.send("Hello World!")
}

http("{{ cookiecutter.project_slug }}", {{ cookiecutter.project_slug }})
{% endif -%}