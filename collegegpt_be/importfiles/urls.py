from django.urls import path
from .views import UploadedPDFListCreateView, UploadFileView

#URL pattern that maps to the 'upload_and_extract_text' view
#When a client makes a POST request to the URL 'UploadedPDF/', the upload_and_extract_text view function will be called/executed
urlpatterns = [
    path('syllabus/', UploadedPDFListCreateView.as_view(), name='uploadedpdf-list-create'),
    path('files/', UploadFileView.as_view(), name='uploadedfile-create'),
]