import azure.functions as func
import json
import uuid
from datetime import datetime

app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)

# In-memory storage for demo purposes
items_store = {}

@app.route(route="items", methods=["GET"])
def get_items(req: func.HttpRequest) -> func.HttpResponse:
    """Get all items from the data store."""
    items = list(items_store.values())
    return func.HttpResponse(
        json.dumps(items),
        mimetype="application/json",
        status_code=200
    )

@app.route(route="items", methods=["POST"])
def create_item(req: func.HttpRequest) -> func.HttpResponse:
    """Create a new item in the data store."""
    try:
        body = req.get_json()
    except ValueError:
        return func.HttpResponse(
            json.dumps({"error": "Invalid JSON body"}),
            mimetype="application/json",
            status_code=400
        )

    item_id = str(uuid.uuid4())
    item = {
        "id": item_id,
        "name": body.get("name", "Unnamed"),
        "description": body.get("description", ""),
        "createdAt": datetime.utcnow().isoformat(),
        "updatedAt": datetime.utcnow().isoformat()
    }
    items_store[item_id] = item

    return func.HttpResponse(
        json.dumps(item),
        mimetype="application/json",
        status_code=201
    )

@app.route(route="items/{id}", methods=["GET"])
def get_item(req: func.HttpRequest) -> func.HttpResponse:
    """Get a specific item by ID."""
    item_id = req.route_params.get("id")

    if item_id not in items_store:
        return func.HttpResponse(
            json.dumps({"error": f"Item with id '{item_id}' not found"}),
            mimetype="application/json",
            status_code=404
        )

    return func.HttpResponse(
        json.dumps(items_store[item_id]),
        mimetype="application/json",
        status_code=200
    )

@app.route(route="items/{id}", methods=["PUT"])
def update_item(req: func.HttpRequest) -> func.HttpResponse:
    """Update an existing item."""
    item_id = req.route_params.get("id")

    if item_id not in items_store:
        return func.HttpResponse(
            json.dumps({"error": f"Item with id '{item_id}' not found"}),
            mimetype="application/json",
            status_code=404
        )

    try:
        body = req.get_json()
    except ValueError:
        return func.HttpResponse(
            json.dumps({"error": "Invalid JSON body"}),
            mimetype="application/json",
            status_code=400
        )

    item = items_store[item_id]
    item["name"] = body.get("name", item["name"])
    item["description"] = body.get("description", item["description"])
    item["updatedAt"] = datetime.utcnow().isoformat()
    items_store[item_id] = item

    return func.HttpResponse(
        json.dumps(item),
        mimetype="application/json",
        status_code=200
    )

@app.route(route="items/{id}", methods=["DELETE"])
def delete_item(req: func.HttpRequest) -> func.HttpResponse:
    """Delete an item from the data store."""
    item_id = req.route_params.get("id")

    if item_id not in items_store:
        return func.HttpResponse(
            json.dumps({"error": f"Item with id '{item_id}' not found"}),
            mimetype="application/json",
            status_code=404
        )

    deleted_item = items_store.pop(item_id)

    return func.HttpResponse(
        json.dumps({"message": f"Item '{deleted_item['name']}' deleted successfully", "id": item_id}),
        mimetype="application/json",
        status_code=200
    )

@app.route(route="health", methods=["GET"])
def health_check(req: func.HttpRequest) -> func.HttpResponse:
    """Health check endpoint."""
    return func.HttpResponse(
        json.dumps({"status": "healthy", "timestamp": datetime.utcnow().isoformat()}),
        mimetype="application/json",
        status_code=200
    )
