from flask import Flask, Response, request, jsonify, render_template
from models import db, Tool
import cowsay
import config
from prometheus_flask_exporter import PrometheusMetrics
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError



app = Flask(__name__)
app.config.from_object(config)
db.init_app(app)

metrics = PrometheusMetrics(app)


@app.route("/health", methods=["GET"])
def health_check():
    try:
        db.session.execute(text("SELECT 1"))
        return jsonify({"status": "ok", "database": "connected"}), 200
    except SQLAlchemyError as e:
        return jsonify({
            "status": "error",
            "database": "unreachable",
            "details": str(e.__class__.__name__)
        }), 500

@app.route("/", methods=["GET"])
def show_index():
    cow_text = cowsay.get_output_string("cow", "Hello from Cowsay DevOps!")
    return render_template("index.html", cow_message=cow_text)

@app.route("/tool/<string:name>", methods=["GET"])
def get_tool(name):
    tool = Tool.query.filter_by(name=name).first()

    if not tool:
        cow_text = cowsay.get_output_string("cow", f"No tool named '{name}' found.")
    else:
        cow_text = cowsay.get_output_string("cow", f"{tool.name}: {tool.definition}")
    
    # Check if it's an AJAX request
    if request.headers.get('X-Requested-With') == 'XMLHttpRequest':
        return jsonify({"cow_message": cow_text})
    
    return render_template("index.html", cow_message=cow_text)

@app.route("/tools", methods=["POST"])
def add_tool():
    data = request.form  # from HTML form
    name = data.get("name")
    definition = data.get("definition")

    if not name or not definition:
        cow_text = cowsay.get_output_string("cow", "Missing 'name' or 'definition'")
        return render_template("index.html", cow_message=cow_text)

    if Tool.query.filter_by(name=name).first():
        cow_text = cowsay.get_output_string("cow", f"Tool '{name}' already exists")
        return render_template("index.html", cow_message=cow_text)

    new_tool = Tool(name=name, definition=definition)
    db.session.add(new_tool)
    db.session.commit()

    cow_text = cowsay.get_output_string("cow", f"Tool '{name}' added!")
    return render_template("index.html", cow_message=cow_text)

@app.route("/tool/<string:name>", methods=["PUT"])
def update_tool(name):
    data = request.form
    new_name = data.get("name")
    new_definition = data.get("definition")

    if not new_name or not new_definition:
        cow_text = cowsay.get_output_string("cow", "Missing 'name' or 'definition'")
    else:
        # Check if tool exists, if not create it
        tool = Tool.query.filter_by(name=name).first()
        
        if not tool:
            # Create new tool
            new_tool = Tool(name=new_name, definition=new_definition)
            db.session.add(new_tool)
            db.session.commit()
            cow_text = cowsay.get_output_string("cow", f"Tool '{new_name}' created!")
        else:
            # Update existing tool
            tool.name = new_name
            tool.definition = new_definition
            db.session.commit()
            cow_text = cowsay.get_output_string("cow", f"Tool '{name}' updated to '{new_name}'!")

    return render_template("index.html", cow_message=cow_text)

@app.route("/tool/<string:name>", methods=["DELETE"])
def delete_tool(name):
    tool = Tool.query.filter_by(name=name).first()

    if not tool:
        cow_text = cowsay.get_output_string("cow", f"Tool '{name}' not found. Nothing to delete.")
    else:
        db.session.delete(tool)
        db.session.commit()
        cow_text = cowsay.get_output_string("cow", f"Tool '{name}' deleted successfully.")

    return render_template("index.html", cow_message=cow_text)

if __name__ == "__main__":
    with app.app_context():
        db.create_all()  # 👈 Ensures table exists on startup
    app.run(host="0.0.0.0", port=5000)