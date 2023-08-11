from django.contrib import admin
from .models import UploadedPDF

# Register your models here.

@admin.register(UploadedPDF)
class UploadedPDFAdmin(admin.ModelAdmin):
    list_display =['file']