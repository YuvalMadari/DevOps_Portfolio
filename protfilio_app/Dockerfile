FROM python:3.10.17-alpine AS builder

WORKDIR /app

COPY ./app/requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.10.17-alpine


WORKDIR /app

COPY --from=builder /usr/local /usr/local

# Copy application source code
COPY ./app/config.py ./app/models.py ./app/app.py app/unit_test.py ./
COPY ./app/templates ./templates

# Use a non-root user for security
RUN adduser -D myuser
USER myuser

EXPOSE 5000

CMD ["python", "app.py"]
