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
class Date:
    year: int
    month: int
    day: int
    
@dataclass
class DateTime:
    hour: int
    minutes: int
@dataclass
class CalendarEvent:
    event_name: str
    start_date: Date
    start_time: DateTime
    end_date: Date
    end_time: DateTime
    
@dataclass
class CalendarEventList:
    events: list[CalendarEvent]
    