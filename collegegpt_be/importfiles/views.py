from django.shortcuts import render
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import UploadedPDF
from .serializers import UploadedPDFSerializer
from langchain.docstore.document import Document
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.embeddings import HuggingFaceEmbeddings
from langchain.vectorstores import OpenSearchVectorSearch
from decouple import config
import boto3
from requests_aws4auth import AWS4Auth
from opensearchpy import RequestsHttpConnection

from importfiles.file_processing import extract_file_data

credentials = boto3.Session(aws_access_key_id=config('AWS_OPENSEARCH_ACCESS_KEY'),aws_secret_access_key=config('AWS_OPENSEARCH_SECRET_ACCESS_KEY')).get_credentials()
awsauth = AWS4Auth(credentials.access_key, credentials.secret_key, 'us-east-2', 'es', session_token=credentials.token)
text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)
embeddings = HuggingFaceEmbeddings(model_name="sentence-transformers/all-mpnet-base-v2")
vectorsearch = OpenSearchVectorSearch(
            opensearch_url=config('OPENSEARCH_URL'),
            index_name="test-index",
            embedding_function=embeddings,
            is_aoss=True,
            http_auth=awsauth,
            use_ssl=True,
            verify_certs=True,
            connection_class=RequestsHttpConnection,
        )
# Create your views here.

#This view function will handle the file upload
#It will be called when clients make requests to your API

class UploadedPDFListCreateView(APIView):
    def get(self, request, format=None):
        uploaded_pdfs = UploadedPDF.objects.all()
        serializer = UploadedPDFSerializer(uploaded_pdfs, many=True)
        return Response(serializer.data)

    def post(self, request, format=None):
        serializer = UploadedPDFSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
class UploadFileView(APIView):
    def get(self, request, format=None):
        #search docs
        response = vectorsearch.client.search(index='test-index', body={"query": {"match_all": {}}, "_source": ["text"]}, size=10000)
        #extract IDs from response
        ids = [hit['_source']['text'] for hit in response['hits']['hits']]
        #extract source from metadata from response
        #source = [hit['_source']['metadata']['text'] for hit in response['hits']['hits']]

        return Response(ids, status=status.HTTP_200_OK)
    
    def post(self, request, format=None):
        uploaded_file = request.FILES['file']
        extracted_text = extract_file_data(uploaded_file)
        split_documents = text_splitter.split_documents(extracted_text)
        vectorsearch.add_documents(split_documents)
        return Response(status=status.HTTP_201_CREATED)
    
    def delete(self, request, format=None):
        vectorsearch.client.delete_by_query(index="test-index", body={"query": {"id": {request.data['id']}}})
        return Response(status=status.HTTP_204_NO_CONTENT)
    
