from langchain.document_loaders import TextLoader, CSVLoader, UnstructuredExcelLoader, Docx2txtLoader
from langchain.document_loaders.parsers import PyMuPDFParser
from dataclasses import dataclass

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


@dataclass
class DateTime:
    year: int
    month: int
    day: int
    hour: int
    minute: int
@dataclass
class CalendarEvent:
    event_name: str
    start_time: DateTime
    end_time: DateTime
    
@dataclass
class CalendarEventList:
    events: list[CalendarEvent]
    