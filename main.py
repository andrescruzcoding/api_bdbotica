# main.py
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, Body
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.encoders import jsonable_encoder

from typing import Annotated
from pydantic import BaseModel, Field
from decimal import Decimal

import os
import mysql.connector
from mysql.connector import pooling


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Crea el pool al arrancar y lo libera al cerrar. FastAPI llamará a este
    contexto automáticamente.
    """
    # Setup
    try:
        db_config = {
            "host": os.environ["DB_HOST"],
            "port": int(os.environ.get("DB_PORT", 3306)),
            "user": os.environ["DB_USER"],
            "password": os.environ["DB_PASSWORD"],
            "database": os.environ["DB_DATABASE"],
        }
        db_ca = os.environ.get("DB_CA_PATH")
        if db_ca:
            db_config["ssl_ca"] = db_ca

        pool_size = int(os.environ.get("DB_POOL_SIZE", 5))
        pool = pooling.MySQLConnectionPool(
            pool_name="botica_pool",
            pool_size=pool_size,
            **db_config
        )
        app.state.pool = pool
        print("DB pool creado con tamaño:", pool_size)
    except KeyError as e:
        # No silenciamos la excepción: la subimos para que el servicio no arranque sin vars obligatorias
        raise RuntimeError(f"Variable de entorno faltante: {e}") from e
    except Exception as e:
        raise RuntimeError(f"Error inicializando pool DB: {e}") from e

    try:
        yield
    finally:
        # Shutdown: liberamos referencia al pool (mysql-connector no tiene close global)
        app.state.pool = None
        print("Shutdown - pool liberado")

# Crear app pasando el lifespan
app = FastAPI(title="Botica API", lifespan=lifespan)

# CORS - ajustar allow_origins en producción
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------- Helpers ----------------
def convert_decimals(obj):
    """Convierte Decimal → float para JSON serializable"""
    if isinstance(obj, list):
        return [convert_decimals(x) for x in obj]
    if isinstance(obj, dict):
        return {k: convert_decimals(v) for k, v in obj.items()}
    if isinstance(obj, Decimal):
        return float(obj)
    return obj

# ---------------- Modelos ----------------
class MedicamentoCreate(BaseModel):
    descripcion: Annotated[str, Field(min_length=1, max_length=255)]
    pre_cos: Annotated[Decimal, Field(max_digits=12, decimal_places=2)]
    pre_ven: Annotated[Decimal, Field(max_digits=12, decimal_places=2)]
    observacion: str | None = None
    stock: Annotated[int | None, Field(ge=0)] = None  # acepta None o ≥ 0

# ---------------- Rutas ----------------
@app.get("/")
@app.head("/")
def health():
    return {"ok": True}

@app.get("/api/all_medicamento")
def get_medicamentos():
    pool = getattr(app.state, "pool", None)
    if pool is None:
        raise HTTPException(status_code=500, detail="DB pool no inicializado")
    try:
        conn = pool.get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.callproc("sp_listarMedicamentos")
        rows = []
        for result in cursor.stored_results():
            rows.extend(result.fetchall())
        cursor.close()
        conn.close()
        # usar jsonable_encoder
        return JSONResponse(content=jsonable_encoder({"ok": True, "data": rows}))
    except mysql.connector.Error as db_err:
        raise HTTPException(status_code=500, detail=f"DB error: {db_err.msg}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/post_medicamento")
def create_medicamento(med: MedicamentoCreate = Body(...)):
    pool = getattr(app.state, "pool", None)
    if pool is None:
        raise HTTPException(status_code=500, detail="DB pool no inicializado")

    try:
        conn = pool.get_connection()
        cursor = conn.cursor()
        try:
            cursor.callproc(
                "sp_create_medicamento",
                [
                    med.descripcion,
                    med.pre_cos,
                    med.pre_ven,
                    med.observacion,
                    med.stock,
                ],
            )
            conn.commit()
        finally:
            cursor.close()
            conn.close()

        return {"ok": True, "message": "Medicamento creado con exito"}
    except mysql.connector.Error as db_err:
        return JSONResponse(
            status_code=400,
            content={"ok": False, "error": db_err.msg},
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))