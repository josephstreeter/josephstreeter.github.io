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
pip install flask-sqlalchamy
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
touch ./demplates/update.html
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

from app import db
db.create_all()
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
        user.firstname = request.form.get("firstname")
        user.lastname = request.form.get("lastname")
        user.initial = request.form.get("initial")
        user.username = request.form.get("username")
        user.email = request.form.get("email")
        user.dateofbirth = request.form.get("dateofbirth")

        if username != '' and email != '':
            p = User(firstname=firstname, lastname=lastname, initial=initial, username=username, email=email, dateofbirth=dateofbirth)
            db.session.add(p)
            db.session.commit()
            return redirect('/')
        else:
            return redirect('/')

# function to update user
@app.route('/edit/<int:id>', methods=["GET","POST"])
def edit(id):
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
                <input type="text" name="firstname" placeholder="First name">
                <input type="text" name="lastname" placeholder="Last name">
                <input type="text" name="initial" placeholder="Middle Initial">
                <input type="text" name="username" placeholder="Username">
                <input type="email" name="email" placeholder="Email">
                <input type="text" name="dateofbirth" placeholder="Date of Birth">
                <input type="submit" value="Add">
            </form>
        </div>
    </div>
{% endblock %}
```

Update edit.html

```html
{% extends "base.html"%}

{% block title %}Edit{% endblock %}

{% block content %}
    <form action="/edit/{{ user.id }}" method="post">
        <input type="text" name="firstname" placeholder="First name">
            <input type="text" name="lastname" value="{{ user.username }}">
            <input type="text" name="initial" value="{{ user.username }}">
            <input type="text" name="username" value="{{ user.username }}">
            <input type="email" name="email" value="{{ user.username }}">
            <input type="text" name="dateofbirth" value="{{ user.username }}">
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
                <input type="text" name="lastname" value="{{ user.username }}" readonly>
                <input type="text" name="initial" value="{{ user.username }}" readonly>
                <input type="text" name="username" value="{{ user.username }}" readonly>
                <input type="email" name="email" value="{{ user.username }}" readonly>
                <input type="text" name="dateofbirth" value="{{ user.username }}" readonly>
                <input type="submit" value="Delete">
            </form>
        </div>
    </div>
{% endblock %}
```
