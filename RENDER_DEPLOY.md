# Render Free Deployment

This setup deploys the Java/JSP app on Render's free Docker web service and connects it to an external MySQL database.

## Files Added

- `pom.xml` builds the NetBeans JSP/Servlet project as a WAR.
- `Dockerfile` builds the WAR and runs it with Payara Micro.
- `render.yaml` defines the Render free web service.
- `db/mpeoa_erp_import.sql` is the local import-friendly MySQL dump for external database hosts. It is ignored by Git because it contains real database data.

## 1. Create External MySQL

Create a free MySQL database with a provider that allows remote connections.

For a quick demo, `db4free.net` works, but their own site says it is for testing and can have outages/data loss:

```text
https://db4free.net/signup.php
```

After creating the database, keep these values:

```text
DB_HOST
DB_PORT
DB_NAME
DB_USERNAME
DB_PASSWORD
```

## 2. Import The Database

Import this file into the external database:

```text
db/mpeoa_erp_import.sql
```

If the provider has phpMyAdmin, use Import and upload that file.

If using command line:

```powershell
mysql -h DB_HOST -P DB_PORT -u DB_USERNAME -p DB_NAME < db\mpeoa_erp_import.sql
```

## 3. Push To GitHub

Render deploys from GitHub, so push this project to a GitHub repository.

Make sure these files are included:

```text
pom.xml
Dockerfile
render.yaml
.dockerignore
src/
web/
```

## 4. Create Render Web Service

1. Go to Render.
2. New -> Web Service.
3. Connect your GitHub repository.
4. Choose Docker runtime.
5. Use the free plan.
6. Add environment variables:

```text
DB_URL=jdbc:mysql://DB_HOST:DB_PORT/DB_NAME?useSSL=true&serverTimezone=UTC&allowPublicKeyRetrieval=true
DB_USERNAME=your_database_username
DB_PASSWORD=your_database_password
```

Render will provide a public URL like:

```text
https://mpeoa-erp-system.onrender.com/MpeoaERPSystem/
```

## Notes

- Free Render services may sleep after inactivity, so first load can be slow.
- Free MySQL providers are usually for testing, not serious production.
- Change the default admin password immediately after first login.
