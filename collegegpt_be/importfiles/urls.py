from django.urls import path
from .views import SyllabusDatesView, UploadFileView

#URL pattern that maps to the 'upload_and_extract_text' view
#When a client makes a POST request to the URL 'UploadedPDF/', the upload_and_extract_text view function will be called/executed
urlpatterns = [
    path('syllabus/', SyllabusDatesView.as_view(), name='syllabus-dates'),
    path('file_upload/', UploadFileView.as_view(), name='uploadedfile-create'),
]