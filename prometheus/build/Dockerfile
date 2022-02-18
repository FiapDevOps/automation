FROM python:3.8-alpine

# Padronizacao do Workdir
WORKDIR /src

# Instalacao de Dep.
COPY requeriments.txt .
RUN pip install -r requeriments.txt
COPY src/ .

# Execução da app
CMD [ "python", "./app.py" ]