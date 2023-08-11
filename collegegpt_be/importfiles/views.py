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
# import lmql
from auto_gptq import AutoGPTQForCausalLM, BaseQuantizeConfig
from transformers import AutoTokenizer
from jsonformer import Jsonformer
import json

from importfiles.file_processing import extract_file_data
from jsonformer_fix import generate_number, generate_string
# from file_formats import CalendarEventList, CalendarEvent

Jsonformer.generate_number = generate_number
Jsonformer.generate_string = generate_string

credentials = boto3.Session(aws_access_key_id=config('AWS_OPENSEARCH_ACCESS_KEY'),aws_secret_access_key=config('AWS_OPENSEARCH_SECRET_ACCESS_KEY')).get_credentials()
awsauth = AWS4Auth(credentials.access_key, credentials.secret_key, 'us-east-2', 'es', session_token=credentials.token)
text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)
embeddings = HuggingFaceEmbeddings(model_name="sentence-transformers/all-mpnet-base-v2")
vectorsearch = OpenSearchVectorSearch(
            opensearch_url=config('OPENSEARCH_URL'),
            index_name="test-index",
            embedding_function=embeddings,
            is_aoss=False,
            http_auth=awsauth,
            use_ssl=True,
            verify_certs=True,
            connection_class=RequestsHttpConnection,
        )
# lmql.serve("TheBloke/StableBeluga-13B-GPTQ", cuda=True, loader="auto-gptq", use_safetensors=True)
json_schema = {
    "type": "object",
    "properties": {
        "num_of_events": {"type": "number"},
        "event_list": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "event_name": {"type": "string"},
                    "start_date": {"type": "object", 
                                "properties": 
                                    {"year": {"type": "number"}, "month": {"type": "number"}, "day": {"type": "number"}}
                                    },
                    "start_time": {"type": "object", 
                                "properties": {"hour": {"type": "number"}, "minutes": {"type": "number"}}
                                },
                    "end_date": {"type": "object", 
                                "properties": {"year": {"type": "number"}, "month": {"type": "number"}, "day": {"type": "number"}}
                                },
                    "end_time": {"type": "object", 
                                "properties": {"hour": {"type": "number"}, "minutes": {"type": "number"}}
                                },
                }
            }
        }
    }
}

model = AutoGPTQForCausalLM.from_quantized("TheBloke/Llama-2-13B-chat-GPTQ", config=BaseQuantizeConfig(group_size=128, desc_act=False), use_safetensors=True, device="cuda:0")
tokenizer = AutoTokenizer.from_pretrained("TheBloke/Llama-2-13B-chat-GPTQ", use_fast=True)


# @lmql.query
# def chatbot(question: str, information: str):
#     '''lmql
#     sample(temperature=0.7, max_len=4096)
#         """[INST] <<SYS>>
#         You are a helpful, respectful and honest assistant. Always answer as helpfully as possible, while being safe.  Your answers should not include any harmful, unethical, racist, sexist, toxic, dangerous, or illegal content. Please ensure that your responses are socially unbiased and positive in nature. If a question does not make any sense, or is not factually coherent, explain why instead of answering something not correct. If you don't know the answer to a question, please don't share false information.
#         <</SYS>>
#         {question}
#         Relevant Information: {information} [/INST] Here are the important dates: [ImportantEvents]"""
#     from
#         lmql.model("TheBloke/Llama-2-13B-chat-GPTQ")
#     where
#         type(ImportantEvents) is CalendarEvent
#     '''

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
        response = vectorsearch.client.search(index='test-index', body={"query": {"match_all": {}}}, _source=["metadata"], size=10000)
        breakpoint()
        response = [hit['_source']['metadata']['source'] for hit in response['hits']['hits']]

        return Response(response, status=status.HTTP_200_OK)
    
    def post(self, request, format=None):
        uploaded_file = request.FILES['file']
        extracted_text = extract_file_data(uploaded_file)
        split_documents = text_splitter.split_documents(extracted_text)
        if request.data['is_syllabus'] == 'true':
            vectorsearch.index_name = "syllabus-index"
            vectorsearch.add_documents(split_documents)
            vectorsearch.index_name = "test-index"
        vectorsearch.add_documents(split_documents)
        return Response(status=status.HTTP_201_CREATED)
    
    def delete(self, request, format=None):
        vectorsearch.client.delete_by_query(index="test-index", body={"query": {"source": {request.data['file_name']}}})
        return Response(status=status.HTTP_204_NO_CONTENT)
    
class SyllabusDatesView(APIView):
    def get(self, request, format=None):
        prompt = "What are the important dates included in the syllabus?"
        results = {d.page_content for d in vectorsearch.similarity_search("important dates", 10)}
        information = "\n\n".join([f"...{r}..." for r in list(results)])
        prompt_template = """[INST] <<SYS>>\nYou are a helpful, respectful and honest assistant. Always answer as helpfully as possible, while being safe.  Your answers should not include any harmful, unethical, racist, sexist, toxic, dangerous, or illegal content. Please ensure that your responses are socially unbiased and positive in nature. If a question does not make any sense, or is not factually coherent, explain why instead of answering something not correct. If you don't know the answer to a question, please don't share false information.\n<</SYS>>\n{question}\nRelevant Information: {information} [/INST]""".format(question=prompt, information=information)
        jsonformer = Jsonformer(model, tokenizer, json_schema, prompt_template, temperature=1)
        events = jsonformer()
        events = json.dumps(events)
        # events = chatbot(prompt_template, information)[0].variables["ImportantEvents"]
        # events = json.dumps(events.__dict__, default=lambda o: o.__dict__)
        print(events)
        return Response(events, status=status.HTTP_200_OK)
    
