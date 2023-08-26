from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from importfiles.models import UploadedPDF
import json

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

# class UploadFileViewTestCase(APITestCase):
#     def setUp(self):
#         self.url = reverse('uploadedfile-create')
#         self.file_data = {'courseName': 'test', 'syllabusIndex': -1, 'files': [open('sample_syllabus.pdf', 'rb'), open('sdxl_report.pdf', 'rb')]}

    # def test_get_uploaded_files(self):
    #     response = self.client.get(self.url)
    #     self.assertEqual(response.status_code, status.HTTP_200_OK)
    
    # def test_upload_file(self):
    #     response = self.client.post(self.url, self.file_data, format='multipart')
    #     self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
    # def test_delete_file(self):
    #     response = self.client.delete(self.url, {"file_name": "sample_syllabus.pdf"})
    #     self.assertEqual(response.status_code, status.HTTP_200_OK)
    
# class SyllabusDatesViewTestCase(APITestCase):
#     def setUp(self):
#         self.url = reverse('syllabus-dates')
    
#     def test_get_syllabus_dates(self):
#         response = self.client.get(self.url)
#         self.assertEqual(response.status_code, status.HTTP_200_OK)

# class CourseManagementViewTestCase(APITestCase):
#     def setUp(self):
#         self.url = reverse('course-delete')
#         self.course_data = {'courseName': 'test'}
    
#     def test_delete_course(self):
#         response = self.client.delete(self.url, self.course_data)
#         self.assertEqual(response.status_code, status.HTTP_200_OK)
    
class ChatbotViewTestCase(APITestCase):
    def setUp(self):
        self.url = reverse('chatbot')
        self.chatbot_data = json.dumps({'context': [json.dumps({"id": "Bob", "text": "Hello"}), json.dumps({"id": "Assistant", "text": "How are you doing today?"})], "courseName": 'test', "message": "Do you know about updog?"})
        
    def test_chatbot(self):
        response = self.client.post(self.url, self.chatbot_data, content_type="application/json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        print(response.data)
        self.assertEqual(response.data, "What's updog?")