from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"Hello": "World"}

@app.post("/ingest")
def ingest():
    return {"message": "Ingested"}

@app.post("/transform")
def transform():
    return {"message": "Transformed"}