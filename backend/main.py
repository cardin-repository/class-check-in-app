from datetime import datetime

from fastapi import FastAPI
from pydantic import BaseModel


app = FastAPI()


class CheckInCreate(BaseModel):
    name: str
    class_name: str


class CheckIn(CheckInCreate):
    id: int
    time: datetime


check_ins: list[CheckIn] = []


@app.get("/")
def root():
    return {"message": "Class Check-In API is running"}


@app.get("/checkins")
def get_check_ins():
    return check_ins


@app.post("/checkins")
def create_check_in(check_in: CheckInCreate):
    new_check_in = CheckIn(
        id=len(check_ins) + 1,
        name=check_in.name,
        class_name=check_in.class_name,
        time=datetime.now(),
    )

    check_ins.insert(0, new_check_in)

    return new_check_in