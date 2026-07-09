from contextlib import asynccontextmanager
from pathlib import Path
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.database import engine, Base
from app.routers import auth, products, cart, orders, admin
import app.models  # noqa: F401 — ensure all models are registered

STATIC_DIR = Path(__file__).parent.parent / "static"
STATIC_DIR.mkdir(exist_ok=True)
(STATIC_DIR / "images").mkdir(exist_ok=True)


@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield


app = FastAPI(
    title="E-Commerce Golden Bears API",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://localhost:3000", "http://localhost"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(products.router)
app.include_router(cart.router)
app.include_router(orders.router)
app.include_router(admin.router)

app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")

from prometheus_fastapi_instrumentator import Instrumentator, metrics

instrumentator = Instrumentator(
    should_group_status_codes=True,
    should_ignore_untemplated=True,
    excluded_handlers=["/health", "/metrics"],
)
instrumentator.add(metrics.latency(buckets=(0.05, 0.1, 0.25, 0.5, 1, 2.5, 5)))
instrumentator.add(metrics.requests())
instrumentator.instrument(app).expose(
    app, endpoint="/metrics", include_in_schema=False
)


@app.get("/")
async def root():
    return {"message": "Golden Bears API", "docs": "/docs"}


@app.get("/health")
async def health():
    return {"status": "ok"}
