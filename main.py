# main.py
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.encoders import jsonable_encoder
from dotenv import load_dotenv
import os
import mysql.connector
from mysql.connector import pooling

# Cargar .env antes de crear el app/lifespan
load_dotenv()

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

@app.get("/")
@app.head("/")
def health():
    return {"ok": True}

@app.get("/api/medicamentos")
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
