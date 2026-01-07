---
title: Django - The Web Framework for Perfectionists with Deadlines
description: Comprehensive guide to Django, the high-level Python web framework that enables rapid development of secure and maintainable web applications
---

Django is a high-level Python web framework that encourages rapid development and clean, pragmatic design. Built by experienced developers, Django takes care of much of the hassle of web development, allowing you to focus on writing your application without needing to reinvent the wheel.

## Overview

Django follows the **Model-View-Template (MVT)** architectural pattern and embraces the philosophy of "Don't Repeat Yourself" (DRY). First released in 2005 and named after jazz guitarist Django Reinhardt, it has powered some of the world's most visited websites including Instagram, Mozilla, Pinterest, and The Washington Post.

### Core Philosophy

- **Rapid Development**: Django was designed to help developers take applications from concept to completion quickly
- **Security First**: Django helps developers avoid common security mistakes by default
- **Scalability**: Django's architecture allows applications to scale from small projects to enterprise-level systems
- **Batteries Included**: Django comes with a rich set of tools and libraries out of the box
- **DRY Principle**: Don't Repeat Yourself - reduce redundancy across the codebase

## Key Features

### Full-Stack Framework

- **ORM (Object-Relational Mapping)**: Define data models in Python and Django handles database operations
- **Admin Interface**: Automatically generated admin panel for content management
- **URL Routing**: Clean and elegant URL design with powerful routing capabilities
- **Template Engine**: Flexible template system with inheritance and filters
- **Forms**: Comprehensive form handling with validation
- **Authentication**: Built-in user authentication and permissions system
- **Internationalization**: Full support for multi-language applications
- **Security**: Protection against SQL injection, XSS, CSRF, and clickjacking

### Developer Experience

- **Development Server**: Built-in lightweight web server for development
- **Database Migrations**: Automated schema migration system
- **Management Commands**: Extensible command-line interface
- **Debug Toolbar**: Detailed debugging information during development
- **Testing Framework**: Integrated unit testing support

### Production Ready

- **Caching**: Multiple caching backends (Memcached, Redis, database)
- **Static Files**: Comprehensive static file handling system
- **Sessions**: Flexible session management
- **Middleware**: Pluggable request/response processing
- **Signals**: Decoupled applications through signal dispatching

## Installation

### Requirements

- Python 3.8 or higher
- pip package manager
- Virtual environment (recommended)

### Create Project Environment

```bash
# Create project directory
mkdir myproject
cd myproject

# Create virtual environment
python -m venv venv

# Activate virtual environment
source venv/bin/activate  # Linux/macOS
venv\Scripts\activate     # Windows
```

### Install Django

```bash
# Install latest version
pip install django

# Install specific version
pip install django==5.0

# Install LTS version
pip install django==4.2

# Verify installation
python -m django --version
```

### Create New Project

```bash
# Create Django project
django-admin startproject mysite

# Project structure
mysite/
├── manage.py
└── mysite/
    ├── __init__.py
    ├── asgi.py
    ├── settings.py
    ├── urls.py
    └── wsgi.py
```

### Start Development Server

```bash
cd mysite
python manage.py runserver

# Server starts at http://127.0.0.1:8000/
```

## Project Structure

### Django Project vs Apps

A Django **project** is a collection of configurations and **apps** for a particular website. An **app** is a web application that does something (e.g., blog, polls, authentication).

### Creating an App

```bash
# Create new app
python manage.py startapp blog

# App structure
blog/
├── __init__.py
├── admin.py
├── apps.py
├── migrations/
│   └── __init__.py
├── models.py
├── tests.py
└── views.py
```

### Register App in Settings

```python
# mysite/settings.py
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'blog',  # Add your app
]
```

## Models and Database

### Defining Models

Models define the structure of your database tables using Python classes:

```python
# blog/models.py
from django.db import models
from django.contrib.auth.models import User

class Category(models.Model):
    Name = models.CharField(max_length=100, unique=True)
    Slug = models.SlugField(max_length=100, unique=True)
    Description = models.TextField(blank=True)
    Created = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name_plural = "categories"
        ordering = ['Name']
    
    def __str__(self):
        return self.Name

class Post(models.Model):
    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('published', 'Published'),
    ]
    
    Title = models.CharField(max_length=200)
    Slug = models.SlugField(max_length=200, unique=True)
    Author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='blog_posts')
    Category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, related_name='posts')
    Content = models.TextField()
    Excerpt = models.TextField(max_length=300, blank=True)
    Status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='draft')
    Created = models.DateTimeField(auto_now_add=True)
    Updated = models.DateTimeField(auto_now=True)
    PublishedDate = models.DateTimeField(null=True, blank=True)
    Tags = models.ManyToManyField('Tag', blank=True, related_name='posts')
    Views = models.IntegerField(default=0)
    
    class Meta:
        ordering = ['-PublishedDate']
        indexes = [
            models.Index(fields=['-PublishedDate']),
            models.Index(fields=['Slug']),
        ]
    
    def __str__(self):
        return self.Title

class Tag(models.Model):
    Name = models.CharField(max_length=50, unique=True)
    Slug = models.SlugField(max_length=50, unique=True)
    
    def __str__(self):
        return self.Name
```

### Field Types

Django provides numerous field types:

- **Character Fields**: `CharField`, `TextField`, `SlugField`, `EmailField`, `URLField`
- **Numeric Fields**: `IntegerField`, `DecimalField`, `FloatField`, `BigIntegerField`
- **Date/Time Fields**: `DateField`, `TimeField`, `DateTimeField`, `DurationField`
- **Boolean Fields**: `BooleanField`, `NullBooleanField`
- **File Fields**: `FileField`, `ImageField`, `FilePathField`
- **Relationship Fields**: `ForeignKey`, `ManyToManyField`, `OneToOneField`
- **Special Fields**: `JSONField`, `UUIDField`, `BinaryField`

### Database Configuration

```python
# mysite/settings.py

# SQLite (default, development)
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

# PostgreSQL (recommended for production)
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'myproject_db',
        'USER': 'myproject_user',
        'PASSWORD': 'secure_password',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}

# MySQL
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'myproject_db',
        'USER': 'myproject_user',
        'PASSWORD': 'secure_password',
        'HOST': 'localhost',
        'PORT': '3306',
    }
}
```

### Migrations

Migrations are Django's way of propagating changes to your models into the database schema:

```bash
# Create migrations
python manage.py makemigrations

# View SQL for migration
python manage.py sqlmigrate blog 0001

# Apply migrations
python manage.py migrate

# Show migration status
python manage.py showmigrations

# Create empty migration for data operations
python manage.py makemigrations --empty blog
```

### QuerySets and Database Queries

```python
# Retrieve all objects
Post.objects.all()

# Filter objects
Post.objects.filter(Status='published')
Post.objects.filter(Status='published', Category__Name='Technology')

# Exclude objects
Post.objects.exclude(Status='draft')

# Get single object
Post.objects.get(Slug='my-post')

# Chaining filters
Post.objects.filter(Status='published').filter(Created__year=2025)

# Complex lookups
Post.objects.filter(Title__icontains='django')
Post.objects.filter(Created__gte='2025-01-01')
Post.objects.filter(Views__gt=100)

# Ordering
Post.objects.order_by('-Created')
Post.objects.order_by('Category__Name', '-Created')

# Limiting results
Post.objects.all()[:5]  # First 5 posts

# Aggregation
from django.db.models import Count, Avg, Max, Min, Sum
Post.objects.aggregate(Count('id'))
Post.objects.aggregate(Avg('Views'))

# Annotation
Post.objects.annotate(num_tags=Count('Tags'))

# Select related (optimize queries with foreign keys)
Post.objects.select_related('Author', 'Category')

# Prefetch related (optimize queries with many-to-many)
Post.objects.prefetch_related('Tags')

# Creating objects
post = Post.objects.create(
    Title='New Post',
    Slug='new-post',
    Content='Content here',
    Status='published'
)

# Updating objects
Post.objects.filter(Status='draft').update(Status='published')

# Deleting objects
Post.objects.filter(Status='draft').delete()
```

## Views and URL Configuration

### Function-Based Views

```python
# blog/views.py
from django.shortcuts import render, get_object_or_404
from django.http import HttpResponse, JsonResponse
from .models import Post, Category

def PostList(request):
    Posts = Post.objects.filter(Status='published').order_by('-PublishedDate')
    context = {'Posts': Posts}
    return render(request, 'blog/post_list.html', context)

def PostDetail(request, slug):
    Post = get_object_or_404(Post, Slug=slug, Status='published')
    Post.Views += 1
    Post.save()
    context = {'Post': Post}
    return render(request, 'blog/post_detail.html', context)

def CategoryPosts(request, slug):
    Category = get_object_or_404(Category, Slug=slug)
    Posts = Post.objects.filter(Category=Category, Status='published')
    context = {'Category': Category, 'Posts': Posts}
    return render(request, 'blog/category_posts.html', context)
```

### Class-Based Views

```python
# blog/views.py
from django.views.generic import ListView, DetailView, CreateView, UpdateView, DeleteView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.urls import reverse_lazy
from .models import Post

class PostListView(ListView):
    model = Post
    template_name = 'blog/post_list.html'
    context_object_name = 'Posts'
    paginate_by = 10
    
    def get_queryset(self):
        return Post.objects.filter(Status='published').order_by('-PublishedDate')

class PostDetailView(DetailView):
    model = Post
    template_name = 'blog/post_detail.html'
    context_object_name = 'Post'
    
    def get_queryset(self):
        return Post.objects.filter(Status='published')

class PostCreateView(LoginRequiredMixin, CreateView):
    model = Post
    template_name = 'blog/post_form.html'
    fields = ['Title', 'Content', 'Category', 'Status']
    success_url = reverse_lazy('blog:post_list')
    
    def form_valid(self, form):
        form.instance.Author = self.request.user
        return super().form_valid(form)

class PostUpdateView(LoginRequiredMixin, UpdateView):
    model = Post
    template_name = 'blog/post_form.html'
    fields = ['Title', 'Content', 'Category', 'Status']
    
    def get_queryset(self):
        return Post.objects.filter(Author=self.request.user)

class PostDeleteView(LoginRequiredMixin, DeleteView):
    model = Post
    template_name = 'blog/post_confirm_delete.html'
    success_url = reverse_lazy('blog:post_list')
    
    def get_queryset(self):
        return Post.objects.filter(Author=self.request.user)
```

### URL Configuration

```python
# blog/urls.py
from django.urls import path
from . import views

app_name = 'blog'

urlpatterns = [
    path('', views.PostListView.as_view(), name='post_list'),
    path('post/<slug:slug>/', views.PostDetailView.as_view(), name='post_detail'),
    path('category/<slug:slug>/', views.CategoryPosts, name='category_posts'),
    path('post/create/', views.PostCreateView.as_view(), name='post_create'),
    path('post/<slug:slug>/edit/', views.PostUpdateView.as_view(), name='post_edit'),
    path('post/<slug:slug>/delete/', views.PostDeleteView.as_view(), name='post_delete'),
]

# mysite/urls.py
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('blog/', include('blog.urls')),
]
```

## Templates

### Template Syntax

```django
<!-- blog/templates/blog/post_list.html -->
{% extends 'base.html' %}
{% load static %}

{% block title %}Blog Posts{% endblock %}

{% block content %}
<div class="container">
    <h1>Recent Blog Posts</h1>
    
    {% if Posts %}
        <div class="post-grid">
            {% for Post in Posts %}
                <article class="post-card">
                    <h2>
                        <a href="{% url 'blog:post_detail' Post.Slug %}">
                            {{ Post.Title }}
                        </a>
                    </h2>
                    
                    <div class="post-meta">
                        <span class="author">By {{ Post.Author.username }}</span>
                        <span class="date">{{ Post.PublishedDate|date:"F d, Y" }}</span>
                        <span class="category">
                            <a href="{% url 'blog:category_posts' Post.Category.Slug %}">
                                {{ Post.Category.Name }}
                            </a>
                        </span>
                    </div>
                    
                    <p class="excerpt">
                        {{ Post.Excerpt|truncatewords:30 }}
                    </p>
                    
                    <div class="post-tags">
                        {% for Tag in Post.Tags.all %}
                            <span class="tag">{{ Tag.Name }}</span>
                        {% endfor %}
                    </div>
                </article>
            {% endfor %}
        </div>
        
        <!-- Pagination -->
        {% if is_paginated %}
            <div class="pagination">
                {% if page_obj.has_previous %}
                    <a href="?page={{ page_obj.previous_page_number }}">&laquo; Previous</a>
                {% endif %}
                
                <span class="current">
                    Page {{ page_obj.number }} of {{ page_obj.paginator.num_pages }}
                </span>
                
                {% if page_obj.has_next %}
                    <a href="?page={{ page_obj.next_page_number }}">Next &raquo;</a>
                {% endif %}
            </div>
        {% endif %}
    {% else %}
        <p>No posts available.</p>
    {% endif %}
</div>
{% endblock %}
```

### Template Filters

```django
<!-- Common template filters -->
{{ Value|lower }}
{{ Value|upper }}
{{ Value|title }}
{{ Value|capfirst }}
{{ Value|truncatewords:30 }}
{{ Value|truncatechars:100 }}
{{ Value|date:"F d, Y" }}
{{ Value|time:"H:i" }}
{{ Value|default:"N/A" }}
{{ Value|length }}
{{ Value|filesizeformat }}
{{ Value|linebreaks }}
{{ Value|striptags }}
{{ Value|safe }}
{{ Value|escape }}
{{ Value|urlencode }}
{{ Value|slugify }}
```

### Template Tags

```django
<!-- Common template tags -->
{% if condition %}
    <!-- Content -->
{% elif other_condition %}
    <!-- Other content -->
{% else %}
    <!-- Default content -->
{% endif %}

{% for Item in Items %}
    {{ forloop.counter }} - {{ Item }}
    {% empty %}
    No items found.
{% endfor %}

{% with Total=Posts.count %}
    Total posts: {{ Total }}
{% endwith %}

{% url 'blog:post_detail' Post.Slug %}

{% static 'css/style.css' %}

{% csrf_token %}

{% load static %}
{% load custom_tags %}
```

### Custom Template Tags and Filters

```python
# blog/templatetags/blog_tags.py
from django import template
from django.db.models import Count
from ..models import Post

register = template.Library()

@register.simple_tag
def TotalPosts():
    return Post.objects.filter(Status='published').count()

@register.inclusion_tag('blog/latest_posts.html')
def ShowLatestPosts(count=5):
    LatestPosts = Post.objects.filter(Status='published')[:count]
    return {'LatestPosts': LatestPosts}

@register.filter
def ReadingTime(text):
    WordCount = len(text.split())
    Minutes = WordCount / 200  # Average reading speed
    return round(Minutes)
```

## Forms

### Django Forms

```python
# blog/forms.py
from django import forms
from .models import Post, Category

class PostForm(forms.ModelForm):
    class Meta:
        model = Post
        fields = ['Title', 'Slug', 'Category', 'Content', 'Excerpt', 'Status', 'Tags']
        widgets = {
            'Content': forms.Textarea(attrs={'rows': 15, 'class': 'form-control'}),
            'Excerpt': forms.Textarea(attrs={'rows': 3, 'class': 'form-control'}),
            'Title': forms.TextInput(attrs={'class': 'form-control'}),
            'Slug': forms.TextInput(attrs={'class': 'form-control'}),
        }
    
    def clean_Slug(self):
        Slug = self.cleaned_data['Slug']
        if Post.objects.filter(Slug=Slug).exclude(pk=self.instance.pk).exists():
            raise forms.ValidationError('This slug is already in use.')
        return Slug

class ContactForm(forms.Form):
    Name = forms.CharField(
        max_length=100,
        widget=forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'Your Name'})
    )
    Email = forms.EmailField(
        widget=forms.EmailInput(attrs={'class': 'form-control', 'placeholder': 'your@email.com'})
    )
    Subject = forms.CharField(
        max_length=200,
        widget=forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'Subject'})
    )
    Message = forms.CharField(
        widget=forms.Textarea(attrs={'class': 'form-control', 'rows': 5, 'placeholder': 'Your message'})
    )
    
    def clean_Email(self):
        Email = self.cleaned_data['Email']
        if not Email.endswith('@example.com'):
            raise forms.ValidationError('Please use your company email.')
        return Email
```

### Form Validation

```python
# blog/forms.py
class PostForm(forms.ModelForm):
    # ... fields ...
    
    def clean(self):
        CleanedData = super().clean()
        Title = CleanedData.get('Title')
        Content = CleanedData.get('Content')
        
        if Title and Content:
            if len(Content) < 100:
                raise forms.ValidationError('Content must be at least 100 characters.')
        
        return CleanedData
    
    def clean_Title(self):
        Title = self.cleaned_data['Title']
        BadWords = ['spam', 'viagra', 'casino']
        if any(word in Title.lower() for word in BadWords):
            raise forms.ValidationError('Title contains prohibited words.')
        return Title
```

### Form Rendering

```django
<!-- blog/templates/blog/post_form.html -->
{% extends 'base.html' %}

{% block content %}
<div class="container">
    <h1>{% if form.instance.pk %}Edit{% else %}Create{% endif %} Post</h1>
    
    <form method="post" enctype="multipart/form-data">
        {% csrf_token %}
        
        <!-- Render all errors -->
        {% if form.errors %}
            <div class="alert alert-danger">
                <ul>
                    {% for field in form %}
                        {% for error in field.errors %}
                            <li>{{ field.label }}: {{ error }}</li>
                        {% endfor %}
                    {% endfor %}
                    {% for error in form.non_field_errors %}
                        <li>{{ error }}</li>
                    {% endfor %}
                </ul>
            </div>
        {% endif %}
        
        <!-- Manual field rendering -->
        <div class="form-group">
            {{ form.Title.label_tag }}
            {{ form.Title }}
            {% if form.Title.help_text %}
                <small class="form-text">{{ form.Title.help_text }}</small>
            {% endif %}
        </div>
        
        <!-- Automatic rendering -->
        {{ form.as_p }}
        
        <!-- Or with custom layout -->
        <div class="row">
            <div class="col-md-8">
                <div class="form-group">
                    <label for="{{ form.Title.id_for_label }}">Title</label>
                    {{ form.Title }}
                </div>
            </div>
            <div class="col-md-4">
                <div class="form-group">
                    <label for="{{ form.Status.id_for_label }}">Status</label>
                    {{ form.Status }}
                </div>
            </div>
        </div>
        
        <button type="submit" class="btn btn-primary">Save</button>
        <a href="{% url 'blog:post_list' %}" class="btn btn-secondary">Cancel</a>
    </form>
</div>
{% endblock %}
```

## Admin Interface

### Registering Models

```python
# blog/admin.py
from django.contrib import admin
from .models import Post, Category, Tag

@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ['Name', 'Slug', 'Created']
    prepopulated_fields = {'Slug': ('Name',)}
    search_fields = ['Name', 'Description']

@admin.register(Tag)
class TagAdmin(admin.ModelAdmin):
    list_display = ['Name', 'Slug']
    prepopulated_fields = {'Slug': ('Name',)}

@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    list_display = ['Title', 'Author', 'Category', 'Status', 'Created', 'Views']
    list_filter = ['Status', 'Created', 'Category', 'Author']
    search_fields = ['Title', 'Content']
    prepopulated_fields = {'Slug': ('Title',)}
    raw_id_fields = ['Author']
    date_hierarchy = 'Created'
    ordering = ['-Created']
    filter_horizontal = ['Tags']
    
    fieldsets = (
        ('Post Information', {
            'fields': ('Title', 'Slug', 'Author', 'Category')
        }),
        ('Content', {
            'fields': ('Content', 'Excerpt')
        }),
        ('Publication', {
            'fields': ('Status', 'PublishedDate')
        }),
        ('Tags', {
            'fields': ('Tags',)
        }),
    )
    
    def get_queryset(self, request):
        QuerySet = super().get_queryset(request)
        if request.user.is_superuser:
            return QuerySet
        return QuerySet.filter(Author=request.user)
```

### Customizing Admin Site

```python
# mysite/admin.py
from django.contrib import admin

admin.site.site_header = "My Blog Administration"
admin.site.site_title = "My Blog Admin"
admin.site.index_title = "Welcome to My Blog Admin"
```

### Creating Superuser

```bash
python manage.py createsuperuser
```

## Authentication and Authorization

### User Authentication

```python
# blog/views.py
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.contrib.auth.forms import UserCreationForm
from django.shortcuts import redirect

def LoginView(request):
    if request.method == 'POST':
        Username = request.POST['Username']
        Password = request.POST['Password']
        User = authenticate(request, username=Username, password=Password)
        if User is not None:
            login(request, User)
            return redirect('blog:post_list')
        else:
            messages.error(request, 'Invalid credentials')
    return render(request, 'blog/login.html')

def LogoutView(request):
    logout(request)
    return redirect('blog:post_list')

def RegisterView(request):
    if request.method == 'POST':
        Form = UserCreationForm(request.POST)
        if Form.is_valid():
            User = Form.save()
            login(request, User)
            return redirect('blog:post_list')
    else:
        Form = UserCreationForm()
    return render(request, 'blog/register.html', {'Form': Form})

@login_required
def ProfileView(request):
    return render(request, 'blog/profile.html')
```

### Permissions and Groups

```python
# blog/views.py
from django.contrib.auth.decorators import permission_required, user_passes_test

@permission_required('blog.add_post')
def CreatePost(request):
    # Only users with 'add_post' permission can access
    pass

@permission_required(['blog.change_post', 'blog.delete_post'])
def ManagePost(request):
    # Users need both permissions
    pass

def IsAuthor(user):
    return user.groups.filter(name='Authors').exists()

@user_passes_test(IsAuthor)
def AuthorDashboard(request):
    # Only users in 'Authors' group can access
    pass
```

### Custom User Model

```python
# accounts/models.py
from django.contrib.auth.models import AbstractUser
from django.db import models

class CustomUser(AbstractUser):
    Bio = models.TextField(blank=True)
    Website = models.URLField(blank=True)
    Avatar = models.ImageField(upload_to='avatars/', blank=True)
    BirthDate = models.DateField(null=True, blank=True)
    
    def __str__(self):
        return self.username

# mysite/settings.py
AUTH_USER_MODEL = 'accounts.CustomUser'
```

## Django REST Framework

### REST Framework Installation

```bash
pip install djangorestframework
```

### Configuration

```python
# mysite/settings.py
INSTALLED_APPS = [
    # ...
    'rest_framework',
    'blog',
]

REST_FRAMEWORK = {
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 10,
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.SessionAuthentication',
        'rest_framework.authentication.TokenAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticatedOrReadOnly',
    ],
}
```

### Serializers

```python
# blog/serializers.py
from rest_framework import serializers
from .models import Post, Category, Tag

class TagSerializer(serializers.ModelSerializer):
    class Meta:
        model = Tag
        fields = ['id', 'Name', 'Slug']

class CategorySerializer(serializers.ModelSerializer):
    PostCount = serializers.SerializerMethodField()
    
    class Meta:
        model = Category
        fields = ['id', 'Name', 'Slug', 'Description', 'PostCount']
    
    def get_PostCount(self, obj):
        return obj.posts.filter(Status='published').count()

class PostSerializer(serializers.ModelSerializer):
    Author = serializers.ReadOnlyField(source='Author.username')
    Category = CategorySerializer(read_only=True)
    CategoryId = serializers.PrimaryKeyRelatedField(
        queryset=Category.objects.all(),
        source='Category',
        write_only=True
    )
    Tags = TagSerializer(many=True, read_only=True)
    TagIds = serializers.PrimaryKeyRelatedField(
        queryset=Tag.objects.all(),
        many=True,
        source='Tags',
        write_only=True
    )
    ReadingTime = serializers.SerializerMethodField()
    
    class Meta:
        model = Post
        fields = [
            'id', 'Title', 'Slug', 'Author', 'Category', 'CategoryId',
            'Content', 'Excerpt', 'Status', 'Created', 'Updated',
            'PublishedDate', 'Tags', 'TagIds', 'Views', 'ReadingTime'
        ]
        read_only_fields = ['Created', 'Updated', 'Views']
    
    def get_ReadingTime(self, obj):
        WordCount = len(obj.Content.split())
        return round(WordCount / 200)
    
    def validate_Title(self, value):
        if len(value) < 5:
            raise serializers.ValidationError("Title must be at least 5 characters.")
        return value
```

### API Views

```python
# blog/api_views.py
from rest_framework import viewsets, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticatedOrReadOnly, IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from .models import Post, Category, Tag
from .serializers import PostSerializer, CategorySerializer, TagSerializer
from .permissions import IsAuthorOrReadOnly

class PostViewSet(viewsets.ModelViewSet):
    queryset = Post.objects.filter(Status='published')
    serializer_class = PostSerializer
    permission_classes = [IsAuthenticatedOrReadOnly, IsAuthorOrReadOnly]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['Category', 'Author', 'Status']
    search_fields = ['Title', 'Content']
    ordering_fields = ['Created', 'Views', 'Title']
    lookup_field = 'Slug'
    
    def perform_create(self, serializer):
        serializer.save(Author=self.request.user)
    
    @action(detail=True, methods=['post'])
    def increment_views(self, request, Slug=None):
        Post = self.get_object()
        Post.Views += 1
        Post.save()
        return Response({'Views': Post.Views})
    
    @action(detail=False, methods=['get'])
    def popular(self, request):
        PopularPosts = Post.objects.filter(Status='published').order_by('-Views')[:10]
        Serializer = self.get_serializer(PopularPosts, many=True)
        return Response(Serializer.data)

class CategoryViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    lookup_field = 'Slug'

class TagViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Tag.objects.all()
    serializer_class = TagSerializer
    lookup_field = 'Slug'
```

### Custom Permissions

```python
# blog/permissions.py
from rest_framework import permissions

class IsAuthorOrReadOnly(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        # Read permissions are allowed for any request
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Write permissions only for the author
        return obj.Author == request.user
```

### API URLs

```python
# blog/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .api_views import PostViewSet, CategoryViewSet, TagViewSet

router = DefaultRouter()
router.register(r'posts', PostViewSet, basename='post')
router.register(r'categories', CategoryViewSet, basename='category')
router.register(r'tags', TagViewSet, basename='tag')

urlpatterns = [
    path('api/', include(router.urls)),
]
```

## Static Files and Media

### Static Files Configuration

```python
# mysite/settings.py
STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

STATICFILES_DIRS = [
    BASE_DIR / 'static',
]

# Media files (user uploads)
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'
```

### Collecting Static Files

```bash
# Collect all static files for production
python manage.py collectstatic
```

### Serving Media Files in Development

```python
# mysite/urls.py
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    # ... your patterns
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
```

## Middleware

### Creating Custom Middleware

```python
# blog/middleware.py
import time
from django.utils.deprecation import MiddlewareMixin

class RequestTimingMiddleware(MiddlewareMixin):
    def process_request(self, request):
        request.start_time = time.time()
    
    def process_response(self, request, response):
        if hasattr(request, 'start_time'):
            duration = time.time() - request.start_time
            response['X-Request-Duration'] = str(duration)
        return response

class UserActivityMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response
    
    def __call__(self, request):
        # Code before view
        if request.user.is_authenticated:
            # Log user activity
            pass
        
        response = self.get_response(request)
        
        # Code after view
        return response
```

### Registering Middleware

```python
# mysite/settings.py
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'blog.middleware.RequestTimingMiddleware',  # Custom middleware
]
```

## Caching

### Cache Configuration

```python
# mysite/settings.py

# Memcached
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.memcached.PyMemcacheCache',
        'LOCATION': '127.0.0.1:11211',
    }
}

# Redis
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.redis.RedisCache',
        'LOCATION': 'redis://127.0.0.1:6379/1',
    }
}

# Database cache
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.db.DatabaseCache',
        'LOCATION': 'my_cache_table',
    }
}
```

### Using Cache

```python
# View caching
from django.views.decorators.cache import cache_page

@cache_page(60 * 15)  # Cache for 15 minutes
def PostList(request):
    Posts = Post.objects.filter(Status='published')
    return render(request, 'blog/post_list.html', {'Posts': Posts})

# Template fragment caching
{% load cache %}
{% cache 500 sidebar %}
    <!-- Expensive sidebar content -->
{% endcache %}

# Low-level cache API
from django.core.cache import cache

# Set cache
cache.set('key', 'value', timeout=300)

# Get cache
value = cache.get('key')

# Get or set
value = cache.get_or_set('key', default_value, timeout=300)

# Delete cache
cache.delete('key')

# Clear all cache
cache.clear()
```

## Testing

### Unit Tests

```python
# blog/tests.py
from django.test import TestCase, Client
from django.contrib.auth.models import User
from django.urls import reverse
from .models import Post, Category

class PostModelTest(TestCase):
    @classmethod
    def setUpTestData(cls):
        # Set up data for the whole TestCase
        User.objects.create_user(username='testuser', password='12345')
        Category.objects.create(Name='Test Category', Slug='test-category')
    
    def setUp(self):
        # Set up data for each test
        self.User = User.objects.get(username='testuser')
        self.Category = Category.objects.get(Slug='test-category')
    
    def test_post_creation(self):
        Post = Post.objects.create(
            Title='Test Post',
            Slug='test-post',
            Author=self.User,
            Category=self.Category,
            Content='Test content',
            Status='published'
        )
        self.assertEqual(Post.Title, 'Test Post')
        self.assertEqual(str(Post), 'Test Post')
    
    def test_post_slug_unique(self):
        Post.objects.create(
            Title='Test Post 1',
            Slug='test-post',
            Author=self.User,
            Category=self.Category,
            Content='Content'
        )
        with self.assertRaises(Exception):
            Post.objects.create(
                Title='Test Post 2',
                Slug='test-post',
                Author=self.User,
                Category=self.Category,
                Content='Content'
            )

class PostViewTest(TestCase):
    @classmethod
    def setUpTestData(cls):
        User = User.objects.create_user(username='testuser', password='12345')
        Category = Category.objects.create(Name='Test Category', Slug='test-category')
        
        for i in range(15):
            Post.objects.create(
                Title=f'Post {i}',
                Slug=f'post-{i}',
                Author=User,
                Category=Category,
                Content=f'Content {i}',
                Status='published'
            )
    
    def test_post_list_view(self):
        response = self.client.get(reverse('blog:post_list'))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'Post')
        self.assertTemplateUsed(response, 'blog/post_list.html')
    
    def test_post_detail_view(self):
        response = self.client.get(reverse('blog:post_detail', args=['post-1']))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'Post 1')
    
    def test_post_create_requires_login(self):
        response = self.client.get(reverse('blog:post_create'))
        self.assertEqual(response.status_code, 302)  # Redirect to login
    
    def test_post_create_logged_in(self):
        self.client.login(username='testuser', password='12345')
        response = self.client.get(reverse('blog:post_create'))
        self.assertEqual(response.status_code, 200)
```

### Running Tests

```bash
# Run all tests
python manage.py test

# Run specific app tests
python manage.py test blog

# Run specific test case
python manage.py test blog.tests.PostModelTest

# Run specific test method
python manage.py test blog.tests.PostModelTest.test_post_creation

# Run with verbosity
python manage.py test --verbosity=2

# Keep test database
python manage.py test --keepdb

# Run tests in parallel
python manage.py test --parallel
```

## Security Best Practices

### Settings Configuration

```python
# mysite/settings.py

# SECURITY WARNING: keep the secret key used in production secret!
import os
from pathlib import Path

SECRET_KEY = os.environ.get('SECRET_KEY')

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = os.environ.get('DEBUG', 'False') == 'True'

ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', '').split(',')

# HTTPS Settings
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True

# Security headers
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_BROWSER_XSS_FILTER = True
X_FRAME_OPTIONS = 'DENY'

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator', 'OPTIONS': {'min_length': 10}},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]
```

### CSRF Protection

```python
# In views
from django.views.decorators.csrf import csrf_protect, csrf_exempt

@csrf_protect
def MyView(request):
    pass

# In templates
<form method="post">
    {% csrf_token %}
    <!-- form fields -->
</form>
```

### SQL Injection Prevention

```python
# SAFE - Use Django ORM
Post.objects.filter(Title=user_input)

# SAFE - Use parameterized queries
from django.db import connection
cursor = connection.cursor()
cursor.execute("SELECT * FROM blog_post WHERE title = %s", [user_input])

# DANGEROUS - Never do this!
# cursor.execute(f"SELECT * FROM blog_post WHERE title = '{user_input}'")
```

### XSS Prevention

```django
<!-- Auto-escaped by default -->
{{ user_input }}

<!-- Mark as safe only for trusted content -->
{{ trusted_html|safe }}

<!-- Explicitly escape -->
{{ user_input|escape }}
```

## Performance Optimization

### Database Optimization

```python
# Use select_related for ForeignKey
posts = Post.objects.select_related('Author', 'Category').all()

# Use prefetch_related for ManyToMany
posts = Post.objects.prefetch_related('Tags').all()

# Use only() to limit fields
posts = Post.objects.only('Title', 'Slug', 'Created')

# Use defer() to exclude fields
posts = Post.objects.defer('Content')

# Use values() for dictionaries
posts = Post.objects.values('Title', 'Slug')

# Use values_list() for tuples
titles = Post.objects.values_list('Title', flat=True)

# Use iterator() for large querysets
for post in Post.objects.iterator():
    process(post)

# Use bulk operations
Post.objects.bulk_create([Post(...), Post(...)])
Post.objects.bulk_update(posts, ['Views'])
```

### Query Optimization

```python
# Use exists() instead of count() > 0
if Post.objects.filter(Status='draft').exists():
    pass

# Use count() instead of len(queryset)
post_count = Post.objects.count()

# Avoid repeated database queries
posts = Post.objects.all()
# Cache queryset by evaluating it
posts = list(posts)
```

### Caching Strategies

```python
# Cache expensive computations
from django.core.cache import cache

def GetPopularPosts():
    CachedPosts = cache.get('popular_posts')
    if CachedPosts is None:
        CachedPosts = Post.objects.filter(Status='published').order_by('-Views')[:10]
        cache.set('popular_posts', CachedPosts, 300)
    return CachedPosts
```

## Deployment

### Production Settings

```python
# mysite/settings/production.py
from .base import *

DEBUG = False
ALLOWED_HOSTS = ['yourdomain.com', 'www.yourdomain.com']

# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DB_NAME'),
        'USER': os.environ.get('DB_USER'),
        'PASSWORD': os.environ.get('DB_PASSWORD'),
        'HOST': os.environ.get('DB_HOST'),
        'PORT': os.environ.get('DB_PORT', '5432'),
    }
}

# Static files
STATIC_ROOT = '/var/www/static/'
MEDIA_ROOT = '/var/www/media/'

# Security
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True

# Email
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = os.environ.get('EMAIL_HOST')
EMAIL_PORT = 587
EMAIL_USE_TLS = True
EMAIL_HOST_USER = os.environ.get('EMAIL_USER')
EMAIL_HOST_PASSWORD = os.environ.get('EMAIL_PASSWORD')
```

### Deployment Checklist

```bash
# Run deployment check
python manage.py check --deploy

# Collect static files
python manage.py collectstatic --noinput

# Run migrations
python manage.py migrate

# Create superuser (if needed)
python manage.py createsuperuser
```

### WSGI Configuration

```python
# mysite/wsgi.py
import os
from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'mysite.settings.production')
application = get_wsgi_application()
```

### Gunicorn Configuration

```bash
# Install Gunicorn
pip install gunicorn

# Run with Gunicorn
gunicorn mysite.wsgi:application --bind 0.0.0.0:8000 --workers 4
```

### Nginx Configuration

```nginx
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    
    location = /favicon.ico { access_log off; log_not_found off; }
    
    location /static/ {
        alias /var/www/static/;
    }
    
    location /media/ {
        alias /var/www/media/;
    }
    
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Management Commands

### Built-in Commands

```bash
# Database
python manage.py migrate
python manage.py makemigrations
python manage.py dbshell
python manage.py dumpdata app.model > data.json
python manage.py loaddata data.json

# User management
python manage.py createsuperuser
python manage.py changepassword username

# Static files
python manage.py collectstatic
python manage.py findstatic file.css

# Shell
python manage.py shell
python manage.py shell_plus  # Django extensions

# Server
python manage.py runserver
python manage.py runserver 0.0.0.0:8000

# Testing
python manage.py test
python manage.py test --keepdb
```

### Custom Management Commands

```python
# blog/management/commands/populate_posts.py
from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from blog.models import Post, Category

class Command(BaseCommand):
    help = 'Populates database with sample posts'
    
    def add_arguments(self, parser):
        parser.add_argument('count', type=int, help='Number of posts to create')
    
    def handle(self, *args, **options):
        Count = options['count']
        Author = User.objects.first()
        Category = Category.objects.first()
        
        for i in range(Count):
            Post.objects.create(
                Title=f'Sample Post {i}',
                Slug=f'sample-post-{i}',
                Author=Author,
                Category=Category,
                Content=f'This is sample content for post {i}',
                Status='published'
            )
            self.stdout.write(self.style.SUCCESS(f'Created post {i}'))
        
        self.stdout.write(self.style.SUCCESS(f'Successfully created {Count} posts'))
```

## Best Practices

### Recommended Project Structure

```text
myproject/
├── manage.py
├── requirements.txt
├── .env
├── .gitignore
├── README.md
├── myproject/
│   ├── __init__.py
│   ├── settings/
│   │   ├── __init__.py
│   │   ├── base.py
│   │   ├── development.py
│   │   └── production.py
│   ├── urls.py
│   ├── wsgi.py
│   └── asgi.py
├── apps/
│   ├── blog/
│   ├── accounts/
│   └── api/
├── static/
│   ├── css/
│   ├── js/
│   └── images/
├── media/
├── templates/
│   ├── base.html
│   ├── blog/
│   └── accounts/
└── tests/
```

### Code Quality

```python
# Use descriptive variable names with PascalCase
UserProfile = get_object_or_404(Profile, user=request.user)

# Add docstrings
def CalculateReadingTime(content):
    """
    Calculate estimated reading time for content.
    
    Args:
        content (str): The text content to analyze
    
    Returns:
        int: Estimated reading time in minutes
    """
    WordCount = len(content.split())
    return round(WordCount / 200)

# Use constants for magic numbers
WORDS_PER_MINUTE = 200
POSTS_PER_PAGE = 10

# Use type hints (Python 3.5+)
def GetPostsByCategory(category_id: int) -> list[Post]:
    return Post.objects.filter(Category_id=category_id, Status='published')
```

### Settings Management

```python
# Use environment variables
import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = os.environ.get('SECRET_KEY')
DEBUG = os.environ.get('DEBUG', 'False') == 'True'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DB_NAME'),
        'USER': os.environ.get('DB_USER'),
        'PASSWORD': os.environ.get('DB_PASSWORD'),
        'HOST': os.environ.get('DB_HOST', 'localhost'),
        'PORT': os.environ.get('DB_PORT', '5432'),
    }
}
```

### Database Best Practices

```python
# Use database indexes
class Post(models.Model):
    # ...
    class Meta:
        indexes = [
            models.Index(fields=['-Created']),
            models.Index(fields=['Status', '-Created']),
        ]

# Use database constraints
class Post(models.Model):
    Slug = models.SlugField(unique=True)
    
    class Meta:
        constraints = [
            models.UniqueConstraint(fields=['Slug'], name='unique_slug'),
        ]

# Use transactions
from django.db import transaction

@transaction.atomic
def CreatePostWithTags(post_data, tag_ids):
    Post = Post.objects.create(**post_data)
    Post.Tags.set(tag_ids)
    return Post
```

## Common Patterns

### Mixins

```python
# Common view mixins
from django.contrib.auth.mixins import LoginRequiredMixin, UserPassesTestMixin

class AuthorRequiredMixin(UserPassesTestMixin):
    def test_func(self):
        Post = self.get_object()
        return Post.Author == self.request.user

class PostUpdateView(LoginRequiredMixin, AuthorRequiredMixin, UpdateView):
    model = Post
    fields = ['Title', 'Content', 'Status']
```

### Signals

```python
# blog/signals.py
from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from django.utils.text import slugify
from .models import Post

@receiver(pre_save, sender=Post)
def GenerateSlug(sender, instance, **kwargs):
    if not instance.Slug:
        instance.Slug = slugify(instance.Title)

@receiver(post_save, sender=Post)
def NotifySubscribers(sender, instance, created, **kwargs):
    if created and instance.Status == 'published':
        # Send notification to subscribers
        pass

# blog/apps.py
from django.apps import AppConfig

class BlogConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'blog'
    
    def ready(self):
        import blog.signals
```

### Context Processors

```python
# blog/context_processors.py
from .models import Category

def Categories(request):
    return {
        'Categories': Category.objects.all()
    }

# mysite/settings.py
TEMPLATES = [
    {
        'OPTIONS': {
            'context_processors': [
                # ... default processors
                'blog.context_processors.Categories',
            ],
        },
    },
]
```

## Troubleshooting

### Common Issues

```bash
# Database locked (SQLite)
# Solution: Use PostgreSQL for production

# Static files not loading
python manage.py collectstatic
# Check STATIC_ROOT and STATIC_URL in settings

# Migration conflicts
python manage.py migrate --merge
python manage.py makemigrations --merge

# Template not found
# Check TEMPLATES['DIRS'] and app order in INSTALLED_APPS

# Import errors
# Ensure app is in INSTALLED_APPS
# Check Python path and virtual environment
```

### Debug Mode

```python
# Enable debug toolbar
pip install django-debug-toolbar

# mysite/settings.py
INSTALLED_APPS = [
    # ...
    'debug_toolbar',
]

MIDDLEWARE = [
    # ...
    'debug_toolbar.middleware.DebugToolbarMiddleware',
]

INTERNAL_IPS = ['127.0.0.1']

# mysite/urls.py
if settings.DEBUG:
    import debug_toolbar
    urlpatterns = [path('__debug__/', include(debug_toolbar.urls))] + urlpatterns
```

## Resources

### Official Documentation

- [Django Documentation](https://docs.djangoproject.com/)
- [Django REST Framework](https://www.django-rest-framework.org/)
- [Django Packages](https://djangopackages.org/)

### Learning Resources

- [Django for Beginners](https://djangoforbeginners.com/)
- [Two Scoops of Django](https://www.feldroy.com/books/two-scoops-of-django-3-x)
- [Django Tutorial](https://docs.djangoproject.com/en/stable/intro/tutorial01/)

### Community

- [Django Forum](https://forum.djangoproject.com/)
- [Django Discord](https://discord.gg/xcRH6mN4fa)
- [r/django](https://www.reddit.com/r/django/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/django)

## See Also

- [Python Web Development](index.md)
- [Flask Framework](flask.md)
- [FastAPI Framework](fastapi.md)
- [REST API Design](../apis/rest-api.md)
- [PostgreSQL Database](../../databases/postgresql.md)
