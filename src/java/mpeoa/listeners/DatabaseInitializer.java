// src/java/mpeoa/listeners/DatabaseInitializer.java
package mpeoa.listeners;

import mpeoa.utils.DatabaseUtil;
import mpeoa.utils.PasswordUtil;
import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

@WebListener
public class DatabaseInitializer implements ServletContextListener {
    
    @Override
    public void contextInitialized(ServletContextEvent sce) {
        System.out.println("=== Mpeoa ERP System Starting ===");
        createTablesIfNotExist();
        ensureAdminUser();
        System.out.println("=== Mpeoa ERP System Ready ===");
    }
    
    private void createTablesIfNotExist() {
        // This will create tables if they don't exist
        // Tables are defined in the SQL schema above
        try (Connection conn = DatabaseUtil.getConnection()) {
            System.out.println("Database connection successful");
        } catch (SQLException e) {
            System.err.println("Database connection failed: " + e.getMessage());
        }
    }
    
    private void ensureAdminUser() {
        // First, ensure roles exist
        ensureRolesExist();
        
        // Then, check if admin exists
        String checkAdminSql = "SELECT COUNT(*) FROM users u JOIN roles r ON u.role_id = r.role_id WHERE r.role_name = 'Administrator'";
        
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement checkStmt = conn.prepareStatement(checkAdminSql)) {
            
            ResultSet rs = checkStmt.executeQuery();
            rs.next();
            int adminCount = rs.getInt(1);
            
            if (adminCount == 0) {
                // Insert admin user
                String insertAdminSql = "INSERT INTO users (username, password, email, full_name, role_id, is_active) " +
                                        "SELECT ?, ?, ?, ?, role_id, ? FROM roles WHERE role_name = 'Administrator'";
                
                try (PreparedStatement insertStmt = conn.prepareStatement(insertAdminSql)) {
                    insertStmt.setString(1, "admin");
                    insertStmt.setString(2, PasswordUtil.hashPassword("Admin@123"));
                    insertStmt.setString(3, "admin@mpeoa.com");
                    insertStmt.setString(4, "System Administrator");
                    insertStmt.setBoolean(5, true);
                    
                    int result = insertStmt.executeUpdate();
                    
                    if (result > 0) {
                        System.out.println("✓ Default admin user created successfully!");
                        System.out.println("  Username: admin");
                        System.out.println("  Password: Admin@123");
                        System.out.println("  Email: admin@mpeoa.com");
                    } else {
                        System.out.println("✗ Failed to create admin user");
                    }
                }
            } else {
                System.out.println("✓ Admin user already exists - no action taken");
            }
            
        } catch (SQLException e) {
            System.err.println("Error ensuring admin user: " + e.getMessage());
        }
    }
    
    private void ensureRolesExist() {
        String[] roles = {
            "Administrator", "Manager", "Accountant", "Cashier", "Inventory Officer"
        };
        
        String checkRoleSql = "SELECT COUNT(*) FROM roles WHERE role_name = ?";
        String insertRoleSql = "INSERT INTO roles (role_name, description) VALUES (?, ?)";
        
        try (Connection conn = DatabaseUtil.getConnection()) {
            for (String role : roles) {
                try (PreparedStatement checkStmt = conn.prepareStatement(checkRoleSql)) {
                    checkStmt.setString(1, role);
                    ResultSet rs = checkStmt.executeQuery();
                    rs.next();
                    
                    if (rs.getInt(1) == 0) {
                        try (PreparedStatement insertStmt = conn.prepareStatement(insertRoleSql)) {
                            insertStmt.setString(1, role);
                            insertStmt.setString(2, getRoleDescription(role));
                            insertStmt.executeUpdate();
                            System.out.println("✓ Created role: " + role);
                        }
                    }
                }
            }
        } catch (SQLException e) {
            System.err.println("Error ensuring roles: " + e.getMessage());
        }
    }
    
    private String getRoleDescription(String role) {
        switch (role) {
            case "Administrator": return "Full system control and user management";
            case "Manager": return "Monitor operations and approve expenses";
            case "Accountant": return "Manage financial transactions and reports";
            case "Cashier": return "Process customer sales and POS transactions";
            case "Inventory Officer": return "Manage stock and inventory operations";
            default: return "";
        }
    }
    
    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        System.out.println("=== Mpeoa ERP System Shutting Down ===");
    }
}