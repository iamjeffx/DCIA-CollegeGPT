from langchain.document_loaders import TextLoader, CSVLoader, UnstructuredExcelLoader, Docx2txtLoader
from langchain.document_loaders.parsers import PyMuPDFParser

DOCUMENT_MAP = {
    ".txt": TextLoader,
    ".md": TextLoader,
    ".py": TextLoader,
    ".pdf": PyMuPDFParser,
    ".csv": CSVLoader,
    ".xls": UnstructuredExcelLoader,
    ".xlsx": UnstructuredExcelLoader,
    ".docx": Docx2txtLoader,
    ".doc": Docx2txtLoader,
}