import chromadb

# Initialize ChromaDB client and create/get collection
vector_store = chromadb.PersistentClient(path='./chroma_db')
collection = vector_store.get_or_create_collection('viyaFeatures')