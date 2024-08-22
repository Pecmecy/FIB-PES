FROM python:3.12-alpine

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1  

WORKDIR /home/app

COPY requirements.txt .
RUN pip install --upgrade pip
RUN pip install -r requirements.txt
RUN pip install powerpathfinder-models
COPY manage.py .
COPY userApi userApi
COPY api api
COPY emailSending emailSending
COPY usrLogin usrLogin
COPY achievement achievement

CMD [ "python", "manage.py", "runserver", "0.0.0.0:8000"]