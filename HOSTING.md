# Hosting MpeoaERPSystem

This project is a NetBeans Java web application using JSP, Jakarta Servlets, and MySQL.

## Runtime Requirements

- Java 11
- A Jakarta Servlet 5+ compatible server:
  - Apache Tomcat 10.x, or
  - Payara / GlassFish 6.x
- MySQL 8.x
- A built WAR file:
  - `dist/MpeoaERPSystem.war`

## Current Deployment Artifact

A WAR can be created from the current NetBeans build output with:

```powershell
New-Item -ItemType Directory -Force dist
jar -cf dist\MpeoaERPSystem.war -C build\web .
```

Deploy this file to the application server.

## Database

The application currently connects to:

```text
jdbc:mysql://localhost:3306/mpeoa_erp?useSSL=false&serverTimezone=UTC
```

Before starting the app on the hosted server, create the MySQL database:

```sql
CREATE DATABASE mpeoa_erp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

Important: the project does not currently include a full SQL schema file. The startup listener checks the connection and creates default roles/admin only after the required tables already exist, so the production database schema must be exported from the working local database or added as a migration/schema file.

## Recommended Hosting Path

1. Rent a small VPS, for example Ubuntu with 1-2 GB RAM.
2. Install Java 11.
3. Install MySQL 8.
4. Install Tomcat 10 or Payara/GlassFish 6.
5. Create the `mpeoa_erp` database and import the schema/data.
6. Deploy `dist/MpeoaERPSystem.war`.
7. Configure the app database connection for the hosted database.
8. Point a domain to the VPS.
9. Add HTTPS using Nginx and Let's Encrypt.

## Before Public Hosting

- Move the database URL, username, and password out of `DatabaseUtil.java`.
- Do not use the MySQL `root` account in production.
- Change the default admin password after first login.
- Add a database schema export to the project.
- Use HTTPS before exposing login pages publicly.
