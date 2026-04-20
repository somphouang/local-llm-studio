#!/usr/bin/env python3
"""
VectorStore — LanceDB + FastEmbed for fully offline vector storage.
LanceDB: pure Python + Rust (pre-built wheels, no compilation required).
FastEmbed: lightweight ONNX-based embeddings, no torch/GPU needed.
"""

import os
import lancedb
import pyarrow as pa
from pathlib import Path
from typing import List, Dict, Any, Optional
from fastembed import TextEmbedding

LANCE_DIR = os.getenv("LANCE_DIR", str(Path(__file__).parent.parent / "rag_storage" / "lancedb"))
EMBED_MODEL = os.getenv("EMBED_MODEL", "BAAI/bge-small-en-v1.5")

# Table schema
SCHEMA = pa.schema([
    pa.field("id",             pa.string()),
    pa.field("doc_id",         pa.string()),
    pa.field("collection",     pa.string()),
    pa.field("filename",       pa.string()),
    pa.field("chunk_index",    pa.int32()),
    pa.field("text",           pa.string()),
    pa.field("vector",         pa.list_(pa.float32(), 384)),
])


class VectorStore:
    def __init__(self):
        Path(LANCE_DIR).mkdir(parents=True, exist_ok=True)
        self.db = lancedb.connect(LANCE_DIR)
        self._embedder = None  # lazy-load on first use

    @property
    def embedder(self) -> TextEmbedding:
        if self._embedder is None:
            cache_dir = str(Path(LANCE_DIR).parent / "embedding_models")
            self._embedder = TextEmbedding(
                model_name=EMBED_MODEL,
                cache_dir=cache_dir,
            )
        return self._embedder

    def _embed(self, texts: List[str]) -> List[List[float]]:
        return [list(v) for v in self.embedder.embed(texts)]

    def _table_name(self, collection: str) -> str:
        # LanceDB table names must be safe identifiers
        return collection.replace("-", "_").replace(" ", "_").lower()

    def get_or_create_collection(self, name: str, description: str = "") -> Any:
        tname = self._table_name(name)
        if tname not in self.db.table_names():
            self.db.create_table(tname, schema=SCHEMA)
        return self.db.open_table(tname)

    def list_collections(self) -> List[Dict]:
        return [{"name": t, "description": ""} for t in self.db.table_names()]

    def delete_collection(self, name: str):
        tname = self._table_name(name)
        if tname in self.db.table_names():
            self.db.drop_table(tname)

    def add_chunks(self, collection_name: str, chunks: List[str], metadatas: List[Dict]):
        vectors = self._embed(chunks)
        table = self.get_or_create_collection(collection_name)
        rows = []
        for i, (chunk, meta, vec) in enumerate(zip(chunks, metadatas, vectors)):
            rows.append({
                "id":          f"{meta['doc_id']}_chunk_{i}",
                "doc_id":      meta["doc_id"],
                "collection":  collection_name,
                "filename":    meta["filename"],
                "chunk_index": meta.get("chunk_index", i),
                "text":        chunk,
                "vector":      vec,
            })
        table.add(rows)

    def query(self, collection_name: str, query_text: str, n_results: int = 5) -> Dict:
        tname = self._table_name(collection_name)
        if tname not in self.db.table_names():
            return {"documents": [[]], "metadatas": [[]], "distances": [[]]}
        try:
            table = self.db.open_table(tname)
            q_vec = self._embed([query_text])[0]
            results = (
                table.search(q_vec)
                     .limit(n_results)
                     .to_list()
            )
            docs   = [r["text"] for r in results]
            metas  = [{"filename": r["filename"], "doc_id": r["doc_id"]} for r in results]
            dists  = [r.get("_distance", 0.0) for r in results]
            return {"documents": [docs], "metadatas": [metas], "distances": [dists]}
        except Exception as e:
            return {"documents": [[]], "metadatas": [[]], "distances": [[]]}

    def list_documents(self, collection_name: str) -> List[Dict]:
        tname = self._table_name(collection_name)
        if tname not in self.db.table_names():
            return []
        try:
            table = self.db.open_table(tname)
            rows = table.to_pandas()[["doc_id", "filename"]].drop_duplicates("doc_id")
            return rows.to_dict(orient="records")
        except Exception:
            return []

    def delete_document(self, collection_name: str, doc_id: str) -> int:
        tname = self._table_name(collection_name)
        if tname not in self.db.table_names():
            return 0
        try:
            table = self.db.open_table(tname)
            before = table.count_rows()
            table.delete(f"doc_id = '{doc_id}'")
            after = table.count_rows()
            return before - after
        except Exception:
            return 0
