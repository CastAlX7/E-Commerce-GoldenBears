FROM python:3.13-slim

WORKDIR /app

COPY requirements.txt .
RUN pip sintall --nocache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["sh", "-c", "alembic upgrade head && exec ubicorn app.main:app --host 0.0.0.0 --port 8000"]
