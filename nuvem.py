"""Sistema na nuvem: um link fixo https, sempre no ar, sem depender de computador da obra nem do MorroDaCruz.exe.

Entrada: o código fica em morrodacruz/servidor/nuvem.py."""
from morrodacruz.servidor.nuvem import application, main  # noqa: F401 (o WSGI do PythonAnywhere importa application)

if __name__ == "__main__":
    main()
