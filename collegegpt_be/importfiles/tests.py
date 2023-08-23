from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from importfiles.models import UploadedPDF

# class UploadedPDFListCreateViewTestCase(APITestCase):
#     def setUp(self):
#         self.url = reverse('uploadedpdf-list-create')
#         self.pdf_data = {'file_name': 'sample_syllabus.pdf', 'file': open('sample_syllabus.pdf', 'rb')}

#     def test_upload_pdf(self):
#         response = self.client.post(self.url, self.pdf_data, format='multipart')
#         self.assertEqual(response.status_code, status.HTTP_201_CREATED)
#         self.assertEqual(UploadedPDF.objects.count(), 1)
#         self.assertEqual(UploadedPDF.objects.get().file_name, 'sample_syllabus.pdf')

#     def test_get_uploaded_pdfs(self):
#         response = self.client.get(self.url)
#         self.assertEqual(response.status_code, status.HTTP_200_OK)

class UploadFileViewTestCase(APITestCase):
    def setUp(self):
        self.url = reverse('uploadedfile-create')
        self.file_data = {'courseName': 'test', 'syllabusIndex': -1, 'files': [open('sample_syllabus.pdf', 'rb'), open('sdxl_report.pdf', 'rb')]}

    # def test_get_uploaded_files(self):
    #     response = self.client.get(self.url)
    #     self.assertEqual(response.status_code, status.HTTP_200_OK)
    
    def test_upload_file(self):
        response = self.client.post(self.url, self.file_data, format='multipart')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
    # def test_delete_file(self):
    #     response = self.client.delete(self.url, {"file_name": "sample_syllabus.pdf"})
    #     self.assertEqual(response.status_code, status.HTTP_200_OK)
    
# class SyllabusDatesViewTestCase(APITestCase):
#     def setUp(self):
#         self.url = reverse('syllabus-dates')
    
#     def test_get_syllabus_dates(self):
#         response = self.client.get(self.url)
#         self.assertEqual(response.status_code, status.HTTP_200_OK)