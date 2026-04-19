#!/usr/bin/env python3
"""
RAG API Server - Native offline Retrieval-Augmented Generation
Endpoints:
  POST /rag/ingest       - Upload and index a document
  GET  /rag/documents    - List all indexed documents
  DELETE /rag/documents/{doc_id} - Remove a document
  POST /rag/chat         - Chat with documents as context
  GET  /rag/collections  - List available knowledge collections
  POST /rag/collections  - Create a new collection
"""

import os
import uuid
import json
import httpx
from pathlib import Path
from typing import Optional, List

from fastapi import FastAPI, UploadFile, File, HTTPException, Form
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv

# Local modules
from vectorstore import VectorStore
from ingest import ingest_document

load_dotenv()

LLM_BASE_URL = os.getenv("LLM_BASE_URL", "http://127.0.0.1:8000/v1")
LLM_MODEL    = os.getenv("LLM_MODEL", "llama-3-8b")
RAG_PORT     = int(os.getenv("RAG_PORT", "8001"))
RAG_HOST     = os.getenv("RAG_HOST", "0.0.0.0")

app = FastAPI(
    title="Local LLM Studio — RAG API",
    description="Native offline Retrieval-Augmented Generation with Vector Database",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount the static UI
UI_DIR = Path(__file__).parent / "ui"
if UI_DIR.exists():
    app.mount("/ui", StaticFiles(directory=str(UI_DIR), html=True), name="ui")

vector_store = VectorStore()


# ---------- Models ----------

class ChatRequest(BaseModel):
    message: str
    collection: str = "default"
    model: Optional[str] = None
    n_results: int = 5
    system_prompt: Optional[str] = None


class CollectionRequest(BaseModel):
    name: str
    description: Optional[str] = ""


# ---------- Routes ----------

@app.get("/", response_class=HTMLResponse)
async def root():
    return """
    <h2>Local LLM Studio — RAG API</h2>
    <p><a href="/docs">📖 API Docs (Swagger)</a> | <a href="/ui">💬 Chat UI</a></p>
    """


@app.get("/health")
async def health():
    return {"status": "ok", "llm_base_url": LLM_BASE_URL}


@app.get("/rag/collections")
async def list_collections():
    return {"collections": vector_store.list_collections()}


@app.post("/rag/collections")
async def create_collection(req: CollectionRequest):
    collection = vector_store.get_or_create_collection(req.name, req.description)
    return {"created": req.name, "description": req.description}


@app.delete("/rag/collections/{name}")
async def delete_collection(name: str):
    vector_store.delete_collection(name)
    return {"deleted": name}


@app.post("/rag/ingest")
async def ingest(
    file: UploadFile = File(...),
    collection: str = Form("default"),
    chunk_size: int = Form(512),
    chunk_overlap: int = Form(64),
):
    """Upload a document (PDF, TXT, DOCX, MD) and embed it into the vector store."""
    suffix = Path(file.filename).suffix.lower()
    allowed = {".pdf", ".txt", ".md", ".docx"}
    if suffix not in allowed:
        raise HTTPException(400, f"Unsupported file type '{suffix}'. Allowed: {allowed}")

    contents = await file.read()
    doc_id = str(uuid.uuid4())

    # Extract text and chunk
    chunks, metadata = ingest_document(contents, file.filename, doc_id, chunk_size, chunk_overlap)

    if not chunks:
        raise HTTPException(400, "No text could be extracted from this document.")

    # Embed and store
    vector_store.add_chunks(collection, chunks, metadata)

    return {
        "doc_id": doc_id,
        "filename": file.filename,
        "collection": collection,
        "chunks_indexed": len(chunks),
    }


@app.get("/rag/documents")
async def list_documents(collection: str = "default"):
    """List all unique documents in a collection."""
    docs = vector_store.list_documents(collection)
    return {"collection": collection, "documents": docs}


@app.delete("/rag/documents/{doc_id}")
async def delete_document(doc_id: str, collection: str = "default"):
    """Remove all chunks belonging to a document."""
    count = vector_store.delete_document(collection, doc_id)
    return {"deleted_doc_id": doc_id, "chunks_removed": count}


@app.post("/rag/chat")
async def chat(req: ChatRequest):
    """Retrieve relevant context from the vector store and generate a grounded response."""
    model = req.model or LLM_MODEL

    # 1. Retrieve top-N relevant chunks
    results = vector_store.query(req.collection, req.message, n_results=req.n_results)
    context_blocks = "\n\n---\n\n".join(results["documents"][0]) if results["documents"] else ""

    # 2. Build the prompt
    system = req.system_prompt or (
        "You are a helpful AI assistant. Answer the user's question using ONLY the provided "
        "context documents. If the answer is not found in the context, say so clearly. "
        "Do not make up information."
    )
    user_message = f"Context:\n{context_blocks}\n\nQuestion: {req.message}" if context_blocks else req.message

    # 3. Call the local llama_cpp.server OpenAI-compatible endpoint
    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": system},
            {"role": "user", "content": user_message},
        ],
    }

    async with httpx.AsyncClient(timeout=120) as client:
        try:
            resp = await client.post(f"{LLM_BASE_URL}/chat/completions", json=payload)
            resp.raise_for_status()
            llm_response = resp.json()
        except Exception as e:
            raise HTTPException(502, f"LLM server error: {e}")

    answer = llm_response["choices"][0]["message"]["content"]
    sources = []
    if results["metadatas"]:
        seen = set()
        for m in results["metadatas"][0]:
            key = m.get("filename", "unknown")
            if key not in seen:
                seen.add(key)
                sources.append({"filename": key, "doc_id": m.get("doc_id", "")})

    return {
        "answer": answer,
        "model": model,
        "sources": sources,
        "context_chunks_used": len(results["documents"][0]) if results["documents"] else 0,
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app:app", host=RAG_HOST, port=RAG_PORT, reload=False)
