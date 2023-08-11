from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from importfiles.models import UploadedPDF

#class UploadedPDFListCreateViewTestCase(APITestCase):
#    def setUp(self):
#        self.url = reverse('uploadedpdf-list-create')
#        self.pdf_data = {'file_name': 'sample_syllabus.pdf', 'file': open('sample_syllabus.pdf', 'rb')}
#
#    def test_upload_pdf(self):
#        response = self.client.post(self.url, self.pdf_data, format='multipart')
#        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
#        self.assertEqual(UploadedPDF.objects.count(), 1)
#        self.assertEqual(UploadedPDF.objects.get().file_name, 'sample_syllabus.pdf')
#
#    def test_get_uploaded_pdfs(self):
#        response = self.client.get(self.url)
#        self.assertEqual(response.status_code, status.HTTP_200_OK)

class UploadFileViewTestCase(APITestCase):
    def setUp(self):
        self.url = reverse('uploadedfile-create')
        self.pdf_data = {'file_name': 'sample_syllabus.pdf', 'file': open('sample_syllabus.pdf', 'rb')}

    def test_upload_file(self):
        response = self.client.post(self.url, self.pdf_data, format='multipart')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def test_get_ids(self):
        #print out what the get function does and what it returns
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, 200)
        ids = response.json()
        for id in ids:
            print(id)