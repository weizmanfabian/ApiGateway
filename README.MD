
# ApiGateway SQL Server y Postgres

Este proyecto configura y ejecuta un apiGateway utilizando SQL Server y Postgres en contenedores Docker.

## Pasos para la ejecución del proyecto

### 1. Clonar el proyecto

```bash
git clone <URL-del-repositorio>
cd <nombre-del-repositorio>
```

### 1.1. Descargar y ejecutar la imagen de Docker para SQL Server

```bash
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=YourStrong#Passw0rd" -p 1433:1433 --name sql1 --hostname sql1 -d mcr.microsoft.com/mssql/server:2022-latest
```

### 1.2. Verificar la ejecución del contenedor SQL Server

```bash
docker ps
```

### 2. Conectarse a la base de datos SQL Server

- **Server:** localhost,1433
- **User Name:** sa
- **Password:** YourStrong#Passw0rd
- **Trust server certificate:** True

### 3. Crear la base de datos en SQL Server

```sql
CREATE DATABASE ejemplo;
```

### 4. Ejecutar el script `OrquestadorSqlServer` en la base de datos creada

Copia y pega todo el contenido del script `OrquestadorSqlServer` y ejecútalo en la base de datos `ejemplo`.

### 5. Descargar y ejecutar la imagen de Docker para Postgres

```bash
docker run --name postgres1 -e POSTGRES_PASSWORD=YourStrong#Passw0rd -d -p 5433:5432 postgres
```

### 5.1. Verificar la ejecución del contenedor Postgres

```bash
docker ps
```

### 6. Conectarse a la base de datos en Postgres

- **Host:** localhost
- **Username:** postgres
- **Password:** YourStrong#Passw0rd
- **Port:** 5433

### 7. Crear la base de datos en Postgres

```sql
CREATE DATABASE ejemplo;
```

### 8. Ejecutar el script `OrquestadorPostgres` en la base de datos creada

Copia y pega todo el contenido del script `OrquestadorPostgres` y ejecútalo en la base de datos `ejemplo`.

### 9. Navegar al directorio `apiGateway`

```bash
cd apiGateway
```

### 10. Instalar las dependencias del proyecto

```bash
npm install
```

### 11. Iniciar la aplicación

```bash
npm start
```

### 12. Importar la colección de Postman

Abre Postman e importa la colección `test.postman_collection`.

## Notas Adicionales

- Asegúrate de que Docker esté instalado y en funcionamiento en tu sistema.
- Los puertos utilizados (1433 para SQL Server y 5433 para Postgres) deben estar disponibles en tu máquina.
- Ajusta las contraseñas y configuraciones según tus necesidades de seguridad.
- El ApiGateway se expone en el puerto 5001