from re import T
import databases
import asyncio
import sqlalchemy
import os
from fastapi import FastAPI, Request
from typing import List
from pydantic import BaseModel
from sqlalchemy import create_engine
from sse_starlette.sse import EventSourceResponse

MESSAGE_STREAM_DELAY = 1  # second
MESSAGE_STREAM_RETRY_TIMEOUT = 15000  # milisecond
# Materialize connection
DB_URL = os.getenv('DATABASE_URL', 'postgresql://materialize:materialize@materialized:6875/materialize')

# If you are planning to use the Materialize Cloud, make sure to download your certificate files from the Materialize Cloud dashboard and place them in the same directory as this file and then run the following commands to set the environment variables:
# export PGSSLROOTCERT="./ca.crt"
# export PGSSLMODE="verify-full"
# export PGSSLKEY="./materialize.key"
# export PGSSLCERT="./materialize.crt"

database = databases.Database(DB_URL)

metadata = sqlalchemy.MetaData()

notes = sqlalchemy.Table(
    "sensors",
    metadata,
    sqlalchemy.Column("id", sqlalchemy.Integer, primary_key=True),
    sqlalchemy.Column("pm25", sqlalchemy.Float),
    sqlalchemy.Column("pm10", sqlalchemy.Float),
    sqlalchemy.Column("geo_lat", sqlalchemy.Float),
    sqlalchemy.Column("geo_lon", sqlalchemy.Float),
    sqlalchemy.Column("timestamp", sqlalchemy.DateTime)
)

engine = create_engine(DB_URL)

class NoteIn(BaseModel):
    id: int
    pm25: float
    pm10: float
    geo_lat: float
    geo_lon: float
    timestamp: str


class Note(BaseModel):
    id: int
    pm25: float
    pm10: float
    geo_lat: float
    geo_lon: float
    timestamp: str



app = FastAPI()

@app.on_event("startup")
async def startup():
    await database.connect()


@app.on_event("shutdown")
async def shutdown():
    await database.disconnect()

@app.get("/sensors", response_model=List[Note])
def read_notes():
    results = engine.execute('SELECT * FROM sensors_view LIMIT 1000')
    return [dict(row) for row in results]
    # Or use the fetchall method:
    # return result.fetchall()

async def mz_data():
    connection = engine.raw_connection()
    with connection.cursor() as cur:
        cur.execute("DECLARE c CURSOR FOR TAIL sensors_view")
        while True:
            cur.execute("FETCH ALL c")
            for row in cur:
                print(row)

# @app.get("/stream/")
# async def stream_notes():
#     notes = await mz_data()
#     return notes

@app.get('/stream')
async def message_stream(request: Request):
    def new_messages():
        # Check if data in table
        results = engine.execute('SELECT count(*) FROM sensors_view_1s')
        if results.fetchone()[0] == 0:
            return None
        else:
            return True

    async def event_generator():
        while True:
            # If client was closed the connection
            if await request.is_disconnected():
                break

            # Checks for new messages and return them to client if any
            if new_messages():
                connection = engine.raw_connection()
                with connection.cursor() as cur:
                    cur.execute("DECLARE c CURSOR FOR TAIL sensors_view_1s")
                    cur.execute("FETCH ALL c")
                    for row in cur:
                        yield row

            await asyncio.sleep(MESSAGE_STREAM_DELAY)

    return EventSourceResponse(event_generator())