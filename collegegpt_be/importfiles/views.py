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
import lmql
from auto_gptq import AutoGPTQForCausalLM, BaseQuantizeConfig
from transformers import AutoTokenizer, GenerationConfig
from jsonformer import Jsonformer
import json

import threading

from importfiles.file_processing import extract_file_data
from importfiles.jsonformer_fix import generate_number, generate_string
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
        "number_of_events": {"type": "number"},
        "event_list": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "event_name": {"type": "string"},
                    "start_time": {"type": "object", 
                                "properties": {"year": {"type": "number"}, "month": {"type": "number"}, "day": {"type": "number"}, "hour": {"type": "number"}, "minute": {"type": "number"}}
                                },
                    "end_time": {"type": "object", 
                                "properties": {"year": {"type": "number"}, "month": {"type": "number"}, "day": {"type": "number"}, "hour": {"type": "number"}, "minute": {"type": "number"}}
                                },
                }
            }
        }
    }
}

model = AutoGPTQForCausalLM.from_quantized("TheBloke/Llama-2-13B-chat-GPTQ", config=BaseQuantizeConfig(group_size=128, desc_act=False), use_safetensors=True, device="cuda:0")
tokenizer = AutoTokenizer.from_pretrained("TheBloke/Llama-2-13B-chat-GPTQ", use_fast=True)
generation_config = GenerationConfig(max_length=4096, temperature=0.7, top_p=0.1, repetition_penalty=1.18, top_k=40)

def extract_and_split(extracted_text_list, uploaded_file, isSyllabus):
    extracted_text = extract_file_data(uploaded_file)
    split_text = text_splitter.split_documents(extracted_text)
    extracted_text_list.extend(split_text)
    if isSyllabus:
        vectorsearch.add_documents(split_text)
    
def escape(text):
    return text.replace("[", "[[").replace("]", "]]")

# @lmql.query
# def chatbot(history: str, user_message: str):
#     '''lmql
#     sample(temperature=0.7, max_len=4096)
#         """[[INST]] <<SYS>>
#         You are a helpful, respectful and honest assistant. Always answer as helpfully as possible, while being safe.  Your answers should not include any harmful, unethical, racist, sexist, toxic, dangerous, or illegal content. Please ensure that your responses are socially unbiased and positive in nature. If a question does not make any sense, or is not factually coherent, explain why instead of answering something not correct. If you don't know the answer to a question, please don't share false information.
#         <</SYS>>"""
#         "{history}{user_message} [response] "
#     from
#         lmql.model("TheBloke/Llama-2-13B-chat-GPTQ")
#     '''
    
@lmql.query
def needs_info(history: str, user_message: str):
    '''lmql
    sample(temperature=0.7, max_len=4096)
        """[[INST]] <<SYS>>
        You are a helpful, respectful and honest assistant. Always answer as helpfully as possible, while being safe.  Your answers should not include any harmful, unethical, racist, sexist, toxic, dangerous, or illegal content. Please ensure that your responses are socially unbiased and positive in nature. If a question does not make any sense, or is not factually coherent, explain why instead of answering something not correct. If you don't know the answer to a question, please don't share false information.
        <</SYS>>"""
        "{history}{user_message} [[/INST]] Do I need more information? [search] " where search in ["Yes", "No"]
    from
        lmql.model("TheBloke/Llama-2-13B-chat-GPTQ")
    '''

# @lmql.query
# def extract_dates(question: str, information: str):
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


# class UploadedPDFListCreateView(APIView):
#     def get(self, request, format=None):
#         uploaded_pdfs = UploadedPDF.objects.all()
#         serializer = UploadedPDFSerializer(uploaded_pdfs, many=True)
#         return Response(serializer.data)

#     def post(self, request, format=None):
#         serializer = UploadedPDFSerializer(data=request.data)
#         if serializer.is_valid():
#             serializer.save()
#             return Response(serializer.data, status=status.HTTP_201_CREATED)
#         return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
class UploadFileView(APIView):    
    def post(self, request, format=None):
        uploaded_file_list = request.FILES.getlist('file')
        course_name = request.data['courseName']
        syllabusIndex = int(request.data['syllabusIndex'])
        extracted_split_text_list = []
        threads = []
        if syllabusIndex > -1:
            if vectorsearch.client.indices.exists(index=f"{course_name}-syllabus"):
                vectorsearch.client.delete_by_query(index=f"{course_name}-syllabus", body={"query": {"match_all": {}}})
            vectorsearch.index_name = f"{course_name}-syllabus"
        for i in range(len(uploaded_file_list)):
            thread = threading.Thread(target=extract_and_split, args=[extracted_split_text_list, uploaded_file_list[i], i == syllabusIndex])
            threads.append(thread)
            thread.start()
        for thread in threads:
            thread.join()
        vectorsearch.index_name = f"{course_name}-index"
        vectorsearch.add_documents(extracted_split_text_list)
        return Response(status=status.HTTP_201_CREATED)
    
    def delete(self, request, format=None):
        course_name = request.data['courseName']
        vectorsearch.client.delete_by_query(index=f"{course_name}-index", body={"query": {"term": {"metadata.source": request.data['file_name']}}})
        return Response(status=status.HTTP_200_OK)
    
class FileListView(APIView):
    def post(self, request, format=None):
        course_name = request.data['courseName']
        response = vectorsearch.client.search(index=f"{course_name}-index", body={"query": {"match_all": {}}}, _source=["metadata"], size=10000)
        response = json.dumps(
            {
                "file_names": list({
                    hit['_source']['metadata']['source']
                    for hit in response['hits']['hits']
                })
            }
        )
        return Response(response, status=status.HTTP_200_OK)
    
class SyllabusDatesView(APIView):
    def post(self, request, format=None):
        course_name = request.data['courseName']
        vectorsearch.index_name = f"{course_name}-syllabus"
        prompt = "List the important dates contained in the syllabus in chronological order."
        results = {d.page_content for d in vectorsearch.similarity_search("important dates", 10)}
        information = "\n\n".join([f"...{r}..." for r in list(results)])
        prompt_template = """[INST] <<SYS>>\nYou are a helpful, respectful and honest assistant. Always answer as helpfully as possible, while being safe.  Your answers should not include any harmful, unethical, racist, sexist, toxic, dangerous, or illegal content. Please ensure that your responses are socially unbiased and positive in nature. If a question does not make any sense, or is not factually coherent, explain why instead of answering something not correct. If you don't know the answer to a question, please don't share false information.\n<</SYS>>\n{question}\nInformation from Syllabus: {information} [/INST]"""
        output = tokenizer.decode(model.generate(**tokenizer(prompt_template.format(question=prompt, information=information), return_tensors="pt").to(model.device), generation_config=generation_config)[0]).split("[/INST]")[1].removesuffix("</s>")
        # print(output)
        jsonformer = Jsonformer(model, tokenizer, json_schema, prompt_template.format(question=prompt, information=max(output.split("\n\n"), key=len)), temperature=0.7)
        events = jsonformer()
        events = json.dumps(events)
        # events = chatbot(prompt_template, information)[0].variables["ImportantEvents"]
        # events = json.dumps(events.__dict__, default=lambda o: o.__dict__)
        # print(events)
        return Response(events, status=status.HTTP_200_OK)
    
class CourseManagementView(APIView):
    def delete(self, request, format=None):
        course_name = request.data['courseName']
        vectorsearch.client.delete_by_query(index=f"{course_name}-index", body={"query": {"match_all": {}}})
        return Response(status=status.HTTP_200_OK)
    
class ChatbotView(APIView):
    def post(self, request, format=None):
        course_name = request.data['courseName']
        context_messages = [json.loads(message) for message in request.data['context']]
        user_message = request.data["message"]
        vectorsearch.index_name = f"{course_name}-index"
        context = []
        for message in context_messages:
            text = message["text"]
            if message["id"] == "Assistant":
                context += f"{text} </s><s>[INST] "
            else:
                context += f"{text} [/INST] "
        search = needs_info(escape("".join(context)), user_message)[0].variables["search"]
        print(search)
        if search == "Yes":
            results = {d.page_content for d in vectorsearch.similarity_search(user_message, 10)}
            information = "\n\n".join([f"...{r}..." for r in list(results)])
            print(information)
            context += f"{user_message} \nRelevant Information:\n{information} [/INST] "
        else:
            context += f"{user_message} [/INST] "
        context_string = "".join(context)
        
        prompt_template = """[INST] <<SYS>>\nYou are a helpful, respectful and honest assistant. Always answer as helpfully as possible, while being safe.  Your answers should not include any harmful, unethical, racist, sexist, toxic, dangerous, or illegal content. Please ensure that your responses are socially unbiased and positive in nature. If a question does not make any sense, or is not factually coherent, explain why instead of answering something not correct. If you don't know the answer to a question, please don't share false information.\n<</SYS>>\n{context}"""
        output = tokenizer.decode(model.generate(**tokenizer(prompt_template.format(context=context_string), return_tensors="pt").to(model.device), generation_config=generation_config)[0]).split("[/INST]")[-1].removesuffix("</s>").strip()
        return Response(output, status=status.HTTP_200_OK)