import os
import sys
from pathlib import Path


def iniciar_con_venv():
    raiz = Path(__file__).resolve().parent
    venv_python = raiz / "venv" / "Scripts" / "python.exe"

    if not venv_python.exists():
        print(venv_python)
        sys.exit(1)

    if Path(sys.executable).resolve() == venv_python.resolve():
        ejecutar_servidor()
        return

    print("Activando entorno virtual...")
    os.execv(str(venv_python), [str(venv_python), __file__])


def ejecutar_servidor():
    import uvicorn

    os.system("title Backend FastAPI")
    host = os.getenv("API_HOST", "0.0.0.0")
    port = int(os.getenv("API_PORT", "8000"))

    print(f"API escuchando en {host}:{port}")
    print(f"Comprobación local: http://127.0.0.1:{port}/")
    print(f"Emulador Android: http://10.0.2.2:{port}")
    print("Teléfono físico: usa la IP local de esta PC y permite el puerto en el firewall.")
    print(f"Swagger: http://127.0.0.1:{port}/docs")
    print()

    uvicorn.run(
        "main:app",
        host=host,
        port=port,
        reload=True,
    )


if __name__ == "__main__":
    iniciar_con_venv()