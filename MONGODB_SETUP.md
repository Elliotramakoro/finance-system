# MongoDB Migration Guide for MpeoaERP System

## Overview
This document provides instructions for setting up and configuring MongoDB for the MpeoaERP System, optimized for deployment on Render.

## Step 1: Create MongoDB Atlas Cluster (FREE)

### Option A: MongoDB Atlas (Recommended for Render)
1. Go to [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
2. Create a FREE account
3. Create a new **Free Tier Cluster** (M0 size)
4. Choose a region close to your app
5. Create a database admin user (save credentials)
6. Get the connection string in the format:
   ```
   mongodb+srv://username:password@clustername.mongodb.net/database?retryWrites=true&w=majority
   ```

## Step 2: Configure Environment Variables for Render

Create a `.env` file in your project root or set environment variables on Render:

```
MONGODB_URI=mongodb+srv://erpadmin:yourpassword@erpcluster.mongodb.net/?retryWrites=true&w=majority
MONGODB_DATABASE=mpeoa_erp
```

For Render deployment:
1. Go to Render Dashboard
2. Select your service
3. Go to **Environment**
4. Add the above variables

## Step 3: Update Project Dependencies

### For NetBeans Maven Projects:
Add to `pom.xml` (if you have one):
```xml
<dependency>
    <groupId>org.mongodb</groupId>
    <artifactId>mongodb-driver-sync</artifactId>
    <version>4.11.0</version>
</dependency>
```

### For NetBeans Ant Projects:
1. Download MongoDB Java Driver:
   - [MongoDB Java Driver 4.11.0 JAR](https://repo1.maven.org/maven2/org/mongodb/mongodb-driver-sync/4.11.0/mongodb-driver-sync-4.11.0.jar)
   - [BSON JAR](https://repo1.maven.org/maven2/org/mongodb/bson/4.11.0/bson-4.11.0.jar)

2. Place JAR files in `web/WEB-INF/lib/` directory

3. Update `nbproject/project.properties`:
```properties
file.reference.mongodb-driver-sync-4.11.0.jar=web/WEB-INF/lib/mongodb-driver-sync-4.11.0.jar
file.reference.bson-4.11.0.jar=web/WEB-INF/lib/bson-4.11.0.jar
javac.classpath=\
    ${file.reference.mongodb-driver-sync-4.11.0.jar}:\
    ${file.reference.bson-4.11.0.jar}
```

## Step 4: Initialize MongoDB Collections

Run this Java code once to create collections and indexes:

```java
import com.mongodb.client.MongoDatabase;
import org.bson.Document;
import mpeoa.utils.DatabaseUtil;

MongoDatabase db = DatabaseUtil.getDatabase();

// Create collections
db.createCollection("users");
db.createCollection("roles");
db.createCollection("products");
db.createCollection("categories");
db.createCollection("inventory");
db.createCollection("sales");
db.createCollection("salesItems");
db.createCollection("purchases");
db.createCollection("suppliers");
db.createCollection("expenses");
db.createCollection("backups");

System.out.println("Collections created successfully!");
```

## Step 5: Seed Initial Data

Create initial roles and admin user:

```java
MongoDatabase db = DatabaseUtil.getDatabase();

// Insert roles
db.getCollection("roles").insertOne(new Document()
    .append("roleId", 1)
    .append("roleName", "Admin")
    .append("description", "Administrator"));

// Insert admin user
db.getCollection("users").insertOne(new Document()
    .append("userId", 1)
    .append("username", "admin")
    .append("password", "hash_of_password")
    .append("email", "admin@example.com")
    .append("fullName", "System Administrator")
    .append("roleId", 1)
    .append("isActive", true)
    .append("createdAt", new Date()));
```

## MongoDB Collection Schema

### users
```json
{
  "_id": ObjectId,
  "userId": 1,
  "username": "admin",
  "password": "hashed_password",
  "email": "admin@example.com",
  "fullName": "Admin User",
  "roleId": 1,
  "roleName": "Admin",
  "isActive": true,
  "lastLogin": ISODate("2024-01-01"),
  "createdAt": ISODate("2024-01-01")
}
```

### products
```json
{
  "_id": ObjectId,
  "productId": 1,
  "productCode": "PRD001",
  "productName": "Product Name",
  "categoryId": 1,
  "unitPrice": 99.99,
  "costPrice": 50.00,
  "description": "Product description",
  "createdAt": ISODate("2024-01-01"),
  "updatedAt": ISODate("2024-01-01")
}
```

### sales
```json
{
  "_id": ObjectId,
  "saleId": 1,
  "invoiceNumber": "INV001",
  "userId": 1,
  "totalAmount": 1000.00,
  "discount": 100.00,
  "tax": 150.00,
  "finalAmount": 1050.00,
  "paymentMethod": "Cash",
  "saleDate": ISODate("2024-01-01"),
  "items": [
    {
      "itemId": 1,
      "productId": 1,
      "quantity": 2,
      "unitPrice": 99.99,
      "totalPrice": 199.98
    }
  ]
}
```

## Deployment on Render

### Create render.yaml
```yaml
version: 1
services:
  - type: web
    name: mpeoa-erp
    env: java
    plan: standard
    buildCommand: ./gradlew build
    startCommand: java -jar build/libs/mpeoa-erp.jar
    envVars:
      - key: MONGODB_URI
        fromDatabase:
          name: mpeoa-db
          property: connectionString
      - key: MONGODB_DATABASE
        value: mpeoa_erp

databases:
  - name: mpeoa-db
    dbName: mpeoa_erp
    plan: starter
    region: ohio
```

### Deploy Steps
1. Push code to GitHub
2. Connect repository to Render
3. Set environment variables in Render dashboard
4. Deploy!

## Common Issues & Solutions

### Connection Timeout
- Check MongoDB Atlas IP whitelist: Allow all IPs (0.0.0.0/0) for Render
- Verify MONGODB_URI is correct
- Check Render region matches MongoDB region

### Authentication Failed
- Reset MongoDB Atlas admin password
- Update MONGODB_URI with correct credentials
- Ensure password is URL-encoded (use special char handling)

### Collections Not Found
- Run initialization script to create collections
- Use MongoDB Compass to verify collections exist

## Testing Database Connection

Add this test servlet:
```java
@WebServlet("/api/test-db")
public class DatabaseTestServlet extends HttpServlet {
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        try {
            MongoDatabase db = DatabaseUtil.getDatabase();
            Document ping = new Document("ping", 1);
            db.runCommand(ping);
            response.getWriter().println("✓ MongoDB Connection Successful!");
        } catch (Exception e) {
            response.getWriter().println("✗ MongoDB Connection Failed: " + e.getMessage());
        }
    }
}
```

## Performance Tips

1. **Create Indexes** for frequently queried fields:
   ```java
   collection.createIndex(Indexes.ascending("username"));
   collection.createIndex(Indexes.ascending("productId"));
   ```

2. **Connection Pooling**: Already configured in MongoDB driver

3. **Batch Operations**: Use insertMany() for bulk inserts

4. **Projection**: Only fetch fields you need:
   ```java
   collection.find().projection(Projections.include("username", "email"))
   ```

## Monitoring

Use MongoDB Atlas Metrics:
- Database operations/sec
- Average query time
- Network throughput
- Storage usage

Set up alerts for:
- Connection failures
- Slow queries (>100ms)
- High memory usage

## References
- [MongoDB Atlas Documentation](https://docs.atlas.mongodb.com/)
- [MongoDB Java Driver](https://mongodb.github.io/mongo-java-driver/)
- [Render Documentation](https://render.com/docs)
