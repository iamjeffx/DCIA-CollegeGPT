from django.db import models

# Create your models here.


class UploadedPDF(models.Model):
    #Field to store the file name of the uploadedPDF
    file_name = models.CharField(max_length = 255, default='')

    #Field that allows uploading files
    file = models.FileField(upload_to='syllabus/')

    #defines how the object should be represented as a string when it is printed/displayed
    def __str__(self):
        return self.file_name
