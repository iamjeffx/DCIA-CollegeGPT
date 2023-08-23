from importfiles.file_formats import DOCUMENT_MAP
from typing import Any, Iterator, Mapping, Optional, Union
from langchain.document_loaders.parsers import PyMuPDFParser
from langchain.document_loaders.blob_loaders import Blob
from langchain.schema import Document
import io
import os

def lazy_parse_load_from_file(self, blob: Blob) -> Iterator[Document]:
    """Lazily parse the blob."""
    import fitz

    with blob.as_bytes_io() as file_path:
        doc = fitz.open("pdf", file_path)  # open document

        yield from [
            Document(
                page_content=page.get_text(**self.text_kwargs),
                metadata=dict(
                    {
                        "source": blob.source,
                        "file_path": blob.source,
                        "page": page.number,
                        "total_pages": len(doc),
                    },
                    **{
                        k: doc.metadata[k]
                        for k in doc.metadata
                        if type(doc.metadata[k]) in [str, int]
                    },
                ),
            )
            for page in doc
        ]
            

def extract_file_data(file):
    file_name = file.name
    file_path = file.file
    if not (file_loader_class := DOCUMENT_MAP.get(
        os.path.splitext(file_name)[1])):
            raise Exception("File type not supported")

    if file_loader_class == PyMuPDFParser:
        file_loader = file_loader_class()
    else:
        file_loader = file_loader_class(file_path)
    if file_loader_class == PyMuPDFParser:
        PyMuPDFParser.lazy_parse = lazy_parse_load_from_file
        return file_loader.parse(Blob.from_data(file_path.read(), path=file_name))
    return file_loader.load()[0]
