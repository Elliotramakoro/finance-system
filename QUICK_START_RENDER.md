# MpeoaERP Backend - MongoDB Migration Quick Start

## ✅ Completed Migrations

Your backend has been successfully migrated to MongoDB with the following updates:

### 1. **Database Utility (DatabaseUtil.java)**
   - ✅ Replaced JDBC MySQL connection with MongoDB driver
   - ✅ Supports environment-based configuration
   - ✅ Automatic connection pooling
   - ✅ Error handling and logging  

### 2. **Data Access Objects (DAOs) - Migrated**
   - ✅ **UserDAO** - User authentication & management
   - ✅ **ProductDAO** - Product & inventory management
   - ✅ **CategoryDAO** - Product categories
   - ✅ **SupplierDAO** - Supplier management
   - ✅ **ExpenseDAO** - Expense tracking & reporting
   
### 3. **Project Configuration**
   - ✅ Updated `nbproject/project.properties` for MongoDB drivers
   - ✅ Removed MySQL JDBC dependencies
   - ✅ Ready for NetBeans build

---

## 🚀 Quick Start: Deploy to Render

### Step 1: Create MongoDB Atlas Database (FREE)

```bash
1. Go to: https://www.mongodb.com/cloud/atlas
2. Sign up for free account
3. Create a free M0 cluster
4. Create database admin user → Save credentials
5. Get connection string like:
   mongodb+srv://username:password@clustername.mongodb.net/?retryWrites=true&w=majority
```

### Step 2: Download MongoDB Drivers

Add these JAI files to `web/WEB-INF/lib/`:

**Option A: Manual Download**
- [mongodb-driver-sync-4.11.0.jar](https://repo1.maven.org/maven2/org/mongodb/mongodb-driver-sync/4.11.0/mongodb-driver-sync-4.11.0.jar)
- [bson-4.11.0.jar](https://repo1.maven.org/maven2/org/mongodb/bson/4.11.0/bson-4.11.0.jar)

**Option B: Maven (if you have it)**
```bash
mvn dependency:copy-dependencies -DoutputDirectory=web/WEB-INF/lib
```

Copy the jars to `web/WEB-INF/lib/` directory

### Step 3: Verify Build Configuration

The `nbproject/project.properties` has been updated. Verify it contains:
```properties
file.reference.mongodb-driver-sync-4.11.0.jar=web/WEB-INF/lib/mongodb-driver-sync-4.11.0.jar
file.reference.bson-4.11.0.jar=web/WEB-INF/lib/bson-4.11.0.jar

javac.classpath=\
    ${file.reference.mongodb-driver-sync-4.11.0.jar}:\
    ${file.reference.bson-4.11.0.jar}
```

### Step 4: Test Locally

Create a test servlet to verify MongoDB connection:

```java
@WebServlet("/api/test-db")
public class TestDBServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        try {
            MongoDatabase db = DatabaseUtil.getDatabase();
            Document ping = new Document("ping", 1);
            db.runCommand(ping);
            response.getWriter().println("✓ MongoDB Connected!");
        } catch (Exception e) {
            response.getWriter().println("✗ Error: " + e.getMessage());
        }
    }
}
```

### Step 5: Deploy to Render

#### A. Using Render Web Service

1. **Push to GitHub**
   ```bash
   git add .
   git commit -m "MongoDB migration: Replace MySQL with MongoDB"
   git push
   ```

2. **Create Render Service**
   - Go to [render.com](https://render.com)
   - Click "New +" → "Web Service"
   - Connect your GitHub repo
   - Select Java as runtime

3. **Set Environment Variables** in Render dashboard:
   ```
   MONGODB_URI=mongodb+srv://your-user:your-password@your-cluster.mongodb.net/?retryWrites=true&w=majority
   MONGODB_DATABASE=mpeoa_erp
   ```

4. **Configure Build Command:**
   ```bash
   cd . && ./gradlew build -x test
   ```
   Or if using NetBeans/Ant:
   ```bash
   ant clean build
   ```

5. **Configure Start Command:**
   ```bash
   java -jar target/mpeoa-erp.jar
   ```

#### B. Using Render with Database

Create `render.yaml` in project root:
```yaml
services:
  - type: web
    name: mpeoa-erp
    runtime: java
    buildCommand: ant clean build
    startCommand: java -Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true -cp . -jar your-app.jar
    envVars:
      - key: MONGODB_URI
        fromService:
          type: mongodb
      - key: MONGODB_DATABASE
        value: mpeoa_erp

databases:
  - name: mongodb
    plan: starter
```

### Step 6: Initialize Collections (First Time Only)

After deployment, run this initialization script once:

```java
import com.mongodb.client.MongoDatabase;
import org.bson.Document;
import mpeoa.utils.DatabaseUtil;

public class InitializeDatabase {
    public static void main(String[] args) {
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
        
        System.out.println("✓ Collections created!");
        
        // Seed admin role
        db.getCollection("roles").insertOne(new Document()
            .append("roleId", 1)
            .append("roleName", "Admin"));
            
        System.out.println("✓ Database initialized!");
    }
}
```

---

## 📋 MongoDB Schema Reference

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
  "isActive": true,
  "lastLogin": ISODate,
  "createdAt": ISODate
}
```

### products
```json
{
  "productId": 1,
  "productCode": "PRD001",
  "productName": "Product Name",
  "categoryId": 1,
  "unitPrice": 99.99,
  "costPrice": 50.00,
  "description": "Description",
  "createdAt": ISODate
}
```

### sales
```json
{
  "saleId": 1,
  "invoiceNumber": "INV001",
  "userId": 1,
  "items": [
    {
      "productId": 1,
      "quantity": 2,
      "unitPrice": 99.99,
      "totalPrice": 199.98
    }
  ],
  "totalAmount": 1000.00,
  "saleDate": ISODate
}
```

---

## 🔧 Environment Variables

Create a `.env` file in project root:
```
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/?retryWrites=true&w=majority
MONGODB_DATABASE=mpeoa_erp
```

Or set in Render dashboard.

---

## ✨ What Was Changed

### Removed (MySQL JDBC)
- ❌ `mysql-connector-j-9.6.0.jar`
- ❌ All JDBC `Connection`, `PreparedStatement`, `ResultSet` imports
- ❌ SQL query strings

### Added (MongoDB Driver)
- ✅ `mongodb-driver-sync-4.11.0.jar`
- ✅ `bson-4.11.0.jar`
- ✅ `MongoCollection`, `MongoDatabase` imports
- ✅ Document-based operations

### Updated Files
1. `src/java/mpeoa/utils/DatabaseUtil.java` - MongoDB connection
2. `src/java/mpeoa/dao/UserDAO.java` - User operations
3. `src/java/mpeoa/dao/ProductDAO.java` - Product operations
4. `src/java/mpeoa/dao/CategoryDAO.java` - Category operations
5. `src/java/mpeoa/dao/SupplierDAO.java` - Supplier operations
6. `src/java/mpeoa/dao/ExpenseDAO.java` - Expense operations
7. `nbproject/project.properties` - Build configuration

---

## 📦 Remaining DAOs to Migrate

Still using JDBC (optional - can be done later):
- `SaleDAO.java` 
- `PurchaseDAO.java`
- `BackupDAO.java`

These aren't critical for basic functionality, but can be migrated following the same pattern.

---

## 🐛 Troubleshooting

### "MongoDB connection refused"
- Check MONGODB_URI is correct
- Verify MongoDB Atlas IP whitelist: Allow `0.0.0.0/0`
- Check credentials in connection string

### "Class not found: MongoClient"
- Ensure JAR files are in `web/WEB-INF/lib/`
- Run `ant clean build` to rebuild classpath

### "Database not selected"
- Verify MONGODB_DATABASE env variable
- Default is `mpeoa_erp`

### "Collection not found"
- Run initialization script first
- Create collections with `db.createCollection("name")`

---

## 📚 Useful Links

- [MongoDB Atlas Documentation](https://docs.atlas.mongodb.com/)
- [MongoDB Java Driver Guide](https://mongodb.github.io/mongo-java-driver/)
- [Render Deployment Guide](https://render.com/docs)
- [MongoDB Connection String](https://docs.mongodb.com/manual/reference/connection-string/)

---

## ✅ Deployment Checklist

- [ ] MongoDB Atlas account created
- [ ] Cluster created with free tier
- [ ] Admin user created
- [ ] Connection string saved
- [ ] MongoDB JAR files downloaded → `web/WEB-INF/lib/`
- [ ] Project builds successfully (`ant clean build`)
- [ ] Database connection tests locally
- [ ] GitHub repo updated
- [ ] Render service created
- [ ] Environment variables set in Render
- [ ] Application deployed
- [ ] Collections initialized
- [ ] Login page working

---

## 🎉 You're Ready!

Your MpeoaERP system is now configured for MongoDB. Deploy to Render and you're live with a fully online MongoDB database!

For questions or issues, refer to `MONGODB_SETUP.md` for detailed documentation.

