# Retrieval-Augmented Generation (RAG)

This project aims to explore the Retrieval Augmented Generation (RAG) technology. 

## What is RAG?

RAG is an AI framework that combines information retrieval with text generation. It brings our own data to Language Models (LMs) in order to enhance their capabilities. In particular, instead of relying only on a pre-trained LM, RAG retrieves relevant documents from an external knowledge base (e.g., database, vector store, or search engine) and uses them to ground the model's responses.

**Use Cases**:

RAG can be applied for many scenarios:
- Question Answering (QA): Customer support, knowledge base queries, healthcare FAQs.
- Document Search & Summarization: Research papers, legal documents, compliance checks.
- Chatbots & Virtual Assistants: More accurate and up-to-date answers.
- Enterprise Applications: Finance, law, or scientific domains where correctness matters.

**Importance**:
Language Models (LMs) exist some limitations:

- Outdated knowledge: LMs are typically trained on public data up to a certain date, leading to the lack of updated information.
- Missing internal knowledge: Companies typically have lots of valuable documents that are outside of the reach of LMs.

RAG is designed to address the above shortcomings with the following advantages:

- Up-to-date knowledge: Goes beyond the model’s training cutoff.
- Accuracy & reliability: Reduces hallucinations by grounding answers in real data.
- Domain adaptation: Tailors general LMs to specialized fields (medicine, law, etc.).
- Efficiency: Avoids retraining large models — just update the knowledge base.

# Pipeline and Techniques

![RAG Pipeline](images/RAG_pipeline.png)

A typical RAG pipeline has 4 main stages:

**1. Document Ingestion & Preprocessing**

Raw data (PDFs, web pages, reports, knowledge bases) is collected and prepared for search.
- Text Cleaning: remove noise (HTML tags, symbols).
- Chunking: split long documents into smaller and focused passages so that LMs and retrievers work better.
- Embedding Generation: convert each chunk into a numerical vector to enable semantic similarity search instead of just keyword matching.

**2. Indexing & Retrieval**

Store embeddings in a fast, searchable system. When a user asks a question, the system retrieves the most relevant chunks.

- Vector Databases: store embeddings and enable fast similarity search (using Approximate Nearest Neighbor algorithms).
- Retrieval Methods:
    - Dense Retrieval (embedding similarity): captures semantic meaning.
    - Sparse Retrieval (BM25, TF-IDF): captures exact keywords.
    - Hybrid Retrieval: combines both to improves accuracy since some queries need exact terms (like dates/numbers), others need semantic understanding.
- Reranking: reorder retrieved passages based on deeper context matching to improve precision by pushing the best passages to the top.

**3. Generation with Augmentation**

The query and retrieved documents are fed into LLMs to generate a grounded answer.

- Prompt Engineering: insert retrieved chunks into the LLM prompt (e.g., "Answer based only on the documents below…") to reduce hallucination.
- Context Window Management: summarization or sliding windows if retrieved documents exceed token limits since LLMs have context length limits.
- Fusion-in-Decoder (FiD): model attends to multiple retrieved documents and decides relevance to ensure it uses evidence effectively instead of relying on a single passage.

**4. Post-processing & Evaluation**

Ensure the generated answer is reliable and useful.

- Answer Verification: compare output against sources to check correctness to prevent hallucination.
- Citation Linking: attach sources to answers to build trust and transparency.
- Evaluation Metrics:
    - Relevance: does it answer the query?
    - Faithfulness: is it grounded in sources?
    - Coverage: does it use all necessary infomation?
- Optional Re-query / Feedback loop: retry retrieval if first results are weak.