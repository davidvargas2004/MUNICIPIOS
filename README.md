# MUNICIPIOS
CONTENEDOR       BASE DE DATOS RELACIONAL    CON UN SISTEMA OPERATIVO  

## Configuración del Contenedor MariaDB

Este proyecto incluye un contenedor Docker con MariaDB para manejar datos de municipios.

### Requisitos
- Docker
- Docker Compose

### Instrucciones

1. **Levantar el contenedor:**
   ```bash
   docker-compose up -d
   ```

2. **Verificar que MariaDB esté corriendo:**
   ```bash
   docker-compose ps
   ```

3. **Conectar a la base de datos:**
   ```bash
   docker-compose exec mariadb mysql -u user -p municipios_db
   ```
   Contraseña: `password`

4. **Importar archivo plano (CSV):**
   - Coloca tu archivo CSV (ej. `municipios.csv`) en la carpeta `init/`.
   - Edita `init/init.sql` para descomentar y ajustar el comando LOAD DATA INFILE.
   - Reinicia el contenedor para ejecutar el script de inicialización:
     ```bash
     docker-compose down
     docker-compose up -d
     ```

### Notas
- La base de datos se inicializa con una tabla `municipios`.
- Los datos se persisten en un volumen Docker llamado `mariadb_data`.
