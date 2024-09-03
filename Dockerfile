FROM --platform=linux/amd64 python:3.11

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
ENV PORT 8000
ENV ENV=production
EXPOSE 8000
CMD ["python","manage.py","runserver","0.0.0.0:8000"]
