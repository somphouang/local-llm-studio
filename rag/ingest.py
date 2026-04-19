#!/usr/bin/env python3
"""
Document ingestion — parse and chunk PDF, DOCX, TXT, Markdown files.
Returns a list of text chunks and associated metadata ready for embedding.
"""

import io
import re
from typing import Tuple, List, Dict


def ingest_document(
    contents: bytes,
    filename: str,
    doc_id: str,
    chunk_size: int = 512,
    chunk_overlap: int = 64,
) -> Tuple[List[str], List[Dict]]:
    """
    Extract text from a file and split it into overlapping chunks.
    Returns (chunks, metadatas).
    """
    ext = filename.rsplit(".", 1)[-1].lower()

    if ext == "pdf":
        text = _extract_pdf(contents)
    elif ext == "docx":
        text = _extract_docx(contents)
    elif ext in {"txt", "md", "markdown"}:
        text = contents.decode("utf-8", errors="replace")
    else:
        text = contents.decode("utf-8", errors="replace")

    text = _clean_text(text)
    chunks = _split_text(text, chunk_size, chunk_overlap)

    metadatas = [
        {"doc_id": doc_id, "filename": filename, "chunk_index": i}
        for i in range(len(chunks))
    ]
    return chunks, metadatas


def _extract_pdf(contents: bytes) -> str:
    try:
        import PyPDF2
        reader = PyPDF2.PdfReader(io.BytesIO(contents))
        pages = []
        for page in reader.pages:
            text = page.extract_text()
            if text:
                pages.append(text)
        return "\n\n".join(pages)
    except ImportError:
        raise RuntimeError("PyPDF2 not installed. Run: pip install PyPDF2")


def _extract_docx(contents: bytes) -> str:
    try:
        import docx
        doc = docx.Document(io.BytesIO(contents))
        paragraphs = [p.text for p in doc.paragraphs if p.text.strip()]
        return "\n\n".join(paragraphs)
    except ImportError:
        raise RuntimeError("python-docx not installed. Run: pip install python-docx")


def _clean_text(text: str) -> str:
    text = re.sub(r"\n{3,}", "\n\n", text)
    text = re.sub(r"[ \t]+", " ", text)
    return text.strip()


def _split_text(text: str, chunk_size: int, chunk_overlap: int) -> List[str]:
    """Split text into chunks of ~chunk_size words with chunk_overlap word overlap."""
    words = text.split()
    chunks = []
    start = 0
    while start < len(words):
        end = min(start + chunk_size, len(words))
        chunk = " ".join(words[start:end])
        if chunk.strip():
            chunks.append(chunk)
        if end >= len(words):
            break
        start += chunk_size - chunk_overlap
    return chunks
