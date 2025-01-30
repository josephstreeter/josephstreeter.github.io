# Flask

This document will outline the process to create a simple CRUD application in Flask.

## Initialize Environment

Create a directory for the project and set up virtual environment.

```bash
mkdir project
python -m venv project
```

Activate virtual environment.

```bash
# Linux
source ./project/bin/activate
```

Install required packages.

```bash
pip install flask-sqlalchemy
pip install Flask-Migrate
```

Create directories and files required.

```bash
mkdir templates
touch app.py
touch ./templates/base.html
touch ./templates/index.html
touch ./templates/list.html
touch ./templates/details.html
touch ./templates/add.html
touch ./templates/update.html
touch ./templates/delete.html
```

## Configure the Application and Create Model

Update the application configuration (app.py).

```python
from flask import Flask, request, redirect
from flask.templating import render_template
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate, migrate

app = Flask(__name__)
app.debug = True
migrate = Migrate(app, db)

# adding configuration for using a sqlite database
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///site.db'

# Creating an SQLAlchemy instance
db = SQLAlchemy(app)

# Models
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(20), unique=True, nullable=False)
    firstname = db.Column(db.String(20), unique=False, nullable=False)
    lastname = db.Column(db.String(20), unique=False, nullable=False)
    initial = db.Column(db.String(1), unique=False, nullable=True)
    email = db.Column(db.String(30), unique=False, nullable=False)
    dateofbirth = db.Column(db.String(10), unique=False, nullable=False)

    def __repr__(self):
        return f"First Name : {self.firstname}, Last Name : {self.lastname}"

if __name__ == '__main__':
    app.run()
```

Create the database.

```bash
python

from app import db, app
with app.app_context():
    db.create_all()

# Exit Python back to bash
```

Create migrations.

```bash
flask db init
flask db migrate -m "Initial migration"
flask db upgrade
```

## Configure CRUD Functions

Update the application configuration (app.py) with the following functions for CRUD activities

```python
# function to list users
@app.route('/')
def index():
    users = User.query.all()
    print(users)
    return render_template('index.html', users=users)

# function to new user
@app.route('/add', methods=["GET","POST"])
def profile():
    
    if request.method == "GET":
        return render_template('add.html')
    else:
        firstname = request.form.get("firstname")
        lastname = request.form.get("lastname")
        initial = request.form.get("initial")
        username = request.form.get("username")
        email = request.form.get("email")
        dateofbirth = request.form.get("dateofbirth")

        if username != '' and email != '':
            p = User(firstname=firstname, lastname=lastname, initial=initial, username=username, email=email, dateofbirth=dateofbirth)
            db.session.add(p)
            db.session.commit()
            return redirect('/')
        else:
            return redirect('/')

# function to update user
@app.route('/update/<int:id>', methods=["GET","POST"])
def update(id):
    user = User.query.get(id)
    if request.method == "GET":
        return render_template('edit.html', user=user)
    else:
        user.firstname = request.form.get("firstname")
        user.lastname = request.form.get("lastname")
        user.initial = request.form.get("initial")
        user.username = request.form.get("username")
        user.email = request.form.get("email")
        user.dateofbirth = request.form.get("dateofbirth")
        db.session.commit()
        return redirect('/')

# function to delete user
@app.route('/delete/<int:id>', methods=["GET","POST"])
def delete(id):
    user = User.query.get(id)
    if request.method == "GET":
        return render_template('delete.html', user=user)
    else:
        data = User.query.get(id)
        db.session.delete(data)
        db.session.commit()
        return redirect('/')
```

## Create Views

Update base.html contents. This template contains the Bootstrap CSS and javascript for styling

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}{% endblock %}</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz" crossorigin="anonymous"></script>
</head>
<body>
    <nav class="navbar navbar-expand-lg bg-body-tertiary">
        <div class="container-fluid">
            <a class="navbar-brand" href="#">Navbar</a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNavAltMarkup" aria-controls="navbarNavAltMarkup" aria-expanded="false" aria-label="Toggle navigation">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNavAltMarkup">
                <div class="navbar-nav">
                    <a class="nav-link active" aria-current="page" href="/">Home</a>
                    <a class="nav-link" href="#">Features</a>
                    <a class="nav-link" href="#">Pricing</a>
                    <a class="nav-link disabled" aria-disabled="true">Disabled</a>
                </div>
            </div>
        </div>
    </nav>
    {% block content %}{% endblock %}
    <script src="https://cdn.jsdelivr.net/npm/@popperjs/core@2.11.8/dist/umd/popper.min.js" integrity="sha384-I7E8VVD/ismYTF4hNIPjVp/Zjvgyol6VFvRkX/vR+Vc4jQkC+hVqc2pM8ODewa9r" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.min.js" integrity="sha384-0pUGZvbkm6XF6gxjEnlmuGrJXVbNuzT9qBBavbLwCsOGabYfZo0T0to5eqruptLy" crossorigin="anonymous"></script>
</body>
</html>
```

Update index.html

```html
<div class="container text-left">
    <a href="/add">Add User</a>
</div>
<div class="container text-center">
    <div class="row">
        <table class="table">
            <tr>
                <th>First Name</th>
                <th>Last Name</th>
                <th>Initial</th>
                <th>User Name</th>
                <th>Email</th>
                <th>dateofbirth</th>
            </tr>
            {% for user in users %}
                <tr>
                    <td>{{ user.firstname }}</td>
                    <td>{{ user.lastname }}</td>
                    <td>{{ user.initial }}</td>
                    <td>{{ user.username }}</td>
                    <td>{{ user.email }}</td>
                    <td>{{ user.dateofbirth }}</td>
                    <td>
                        <a href="/edit/{{ user.id }}">Edit</a>
                        <a href="/delete/{{ user.id }}">Delete</a>
                    </td>
                </tr>
            {% endfor %}
        </table>
    </div>
</div>
```

Update add.html

```html
{% extends "base.html"%}

{% block title %}Add{% endblock %}

{% block content %}
    <div class="container text-left">
        <div class="row">
            <form action="/add" method="post">
                <div class="mb-3">
                    <label for="firstname" class="form-label">First Name</label>
                    <input type="text" class="form-control" name="firstname" placeholder="First name">
                </div>
                <div class="mb-3">
                    <label for="lastname"  class="form-label">Last Name</label>
                    <input type="text" class="form-control" name="lastname" placeholder="Last name">
                </div>
                <div class="mb-3">
                    <label for="initial" class="form-label">Initial</label>
                    <input type="text" class="form-control" name="initial" placeholder="Middle Initial">
                </div>
                <div class="mb-3">
                    <label for="username" class="form-label">User Name</label>
                    <input type="text" class="form-control" name="username" placeholder="Username">
                </div>
                <div class="mb-3">
                    <label for="email" class="form-label">Email</label>
                    <input type="email" class="form-control" name="email" placeholder="Email">
                </div>
                <div class="mb-3">
                    <label for="dateofbirth" class="form-label">Date of Birth</label>
                    <input type="text" class="form-control" name="dateofbirth" placeholder="Date of Birth">
                </div>
                <div class="mb-3">
                    <input type="submit" value="Add">
                </div>
            </form>
        </div>
    </div>
{% endblock %}
```

Update edit.html

```html
{% extends "base.html"%}

{% block title %}Update{% endblock %}

{% block content %}
    <form action="/update/{{ user.id }}" method="post">
        <input type="text" name="firstname" value="{{ user.firstname }}">
        <input type="text" name="lastname" value="{{ user.lastname }}">
        <input type="text" name="initial" value="{{ user.initial }}">
        <input type="text" name="username" value="{{ user.username }}">
        <input type="email" name="email" value="{{ user.email }}">
        <input type="text" name="dateofbirth" value="{{ user.dateofbirth }}">
        <input type="submit" value="Edit">
    </form>
{% endblock %}
```

Update delete.html

```html
{% extends "base.html"%}

{% block title %}Delete{% endblock %}

{% block content %}
    <div class="container text-left">
        <div class="row">
            <form action="/delete/{{ user.id }}" method="post">
                <input type="text" name="firstname" value="{{ user.firstname }}" readonly>
                <input type="text" name="lastname" value="{{ user.lastname }}" readonly>
                <input type="text" name="initial" value="{{ user.initial }}" readonly>
                <input type="text" name="username" value="{{ user.username }}" readonly>
                <input type="email" name="email" value="{{ user.email }}" readonly>
                <input type="text" name="dateofbirth" value="{{ user.dateofbirth }}" readonly>
                <input type="submit" value="Delete">
            </form>
        </div>
    </div>
{% endblock %}
```
