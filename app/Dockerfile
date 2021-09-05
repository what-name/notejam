FROM python:2

ENV PYTHONUNBUFFERED 1
RUN apt-get update
#RUN apt-get install -y libxml2-dev libxslt1-dev antiword poppler-utils
RUN pip install --upgrade pip

COPY ./requirements.txt ./requirements.txt

RUN pip install -r ./requirements.txt

RUN mkdir /notejam
WORKDIR /notejam
COPY ./notejam /notejam

CMD ["python", "manage.py", "syncdb"]
CMD ["python", "manage.py", "migrate"]
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
