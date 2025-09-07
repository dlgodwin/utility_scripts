import json
from bson import json_util, ObjectId
from datetime import datetime

# Function to recursively convert BSON to standard JSON
def convert_bson_to_json(doc):
    if isinstance(doc, dict):
        return {k: convert_bson_to_json(v) for k, v in doc.items()}
    elif isinstance(doc, list):
        return [convert_bson_to_json(v) for v in doc]
    elif isinstance(doc, ObjectId):
        return str(doc)
    elif isinstance(doc, datetime):
        return doc.isoformat()
    elif isinstance(doc, (int, float, str, bool)):
        return doc
    else:
        return str(doc)

# Read the JSON data from the local file
input_file_path = 'mongo_data.json'
with open(input_file_path, 'r') as file:
    document = json.load(file, object_hook=json_util.object_hook)

# Convert the document to standard JSON
standard_json_doc = convert_bson_to_json(document)

# Save to a JSON file
output_file_path = 'exportedData.json'
with open(output_file_path, 'w') as file:
    json.dump(standard_json_doc, file, indent=4)

print(f"Document exported successfully to {output_file_path}")