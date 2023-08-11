
from rest_framework import serializers
from .models import UploadedPDF

#This serializer will be used for the DRF to convert complex data types (django model instances)
#into Python data types (dictionaries) that can be easily rendered into JSON

class UploadedPDFSerializer(serializers.ModelSerializer):
    class Meta:
        #model name
        model = UploadedPDF
        #fields from the UploadedPDF model
        fields = '__all__'