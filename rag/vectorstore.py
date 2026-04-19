#!/usr/bin/env python3
"""
VectorStore — ChromaDB wrapper for offline persistent storage.
All embeddings are generated locally using sentence-transformers.
"""

import os
import chromadb
from chromadb.utils import embedding_functions
from pathlib import Path
from typing import List, Dict, Any, Optional

CHROMA_DIR = os.getenv("CHROMA_DIR", str(Path(__file__).parent.parent / "rag_storage" / "chroma"))
EMBED_MODEL = os.getenv("EMBED_MODEL", "sentence-transformers/all-MiniLM-L6-v2")


class VectorStore:
    def __init__(self):
        Path(CHROMA_DIR).mkdir(parents=True, exist_ok=True)
        self.client = chromadb.PersistentClient(path=CHROMA_DIR)
        self.embed_fn = embedding_functions.SentenceTransformerEmbeddingFunction(
            model_name=EMBED_MODEL
        )

    def get_or_create_collection(self, name: str, description: str = "") -> Any:
        return self.client.get_or_create_collection(
            name=name,
            embedding_function=self.embed_fn,
            metadata={"description": description},
        )

    def list_collections(self) -> List[Dict]:
        cols = self.client.list_collections()
        return [{"name": c.name, "description": c.metadata.get("description", "")} for c in cols]

    def delete_collection(self, name: str):
        self.client.delete_collection(name)

    def add_chunks(self, collection_name: str, chunks: List[str], metadatas: List[Dict]):
        col = self.get_or_create_collection(collection_name)
        ids = [f"{m['doc_id']}_chunk_{i}" for i, m in enumerate(metadatas)]
        col.add(documents=chunks, metadatas=metadatas, ids=ids)

    def query(self, collection_name: str, query_text: str, n_results: int = 5) -> Dict:
        try:
            col = self.get_or_create_collection(collection_name)
            return col.query(query_texts=[query_text], n_results=n_results)
        except Exception:
            return {"documents": [[]], "metadatas": [[]], "distances": [[]]}

    def list_documents(self, collection_name: str) -> List[Dict]:
        try:
            col = self.get_or_create_collection(collection_name)
            results = col.get(include=["metadatas"])
            seen = {}
            for meta in results["metadatas"]:
                doc_id = meta.get("doc_id")
                if doc_id and doc_id not in seen:
                    seen[doc_id] = {
                        "doc_id": doc_id,
                        "filename": meta.get("filename", "unknown"),
                    }
            return list(seen.values())
        except Exception:
            return []

    def delete_document(self, collection_name: str, doc_id: str) -> int:
        try:
            col = self.get_or_create_collection(collection_name)
            existing = col.get(where={"doc_id": doc_id})
            ids = existing["ids"]
            if ids:
                col.delete(ids=ids)
            return len(ids)
        except Exception:
            return 0
