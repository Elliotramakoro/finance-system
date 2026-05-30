// src/java/mpeoa/utils/DatabaseUtil.java
package mpeoa.utils;

import java.sql.*;

public class DatabaseUtil {

    // Read from environment variables (safe for GitHub)
    private static final String DB_HOST = getEnv("DB_HOST", "mysql-199a95cf-makhabaneramakoro05-32b7.e.aivencloud.com");
    private static final String DB_PORT = getEnv("DB_PORT", "14088");
    private static final String DB_NAME = getEnv("DB_NAME", "defaultdb");
    private static final String DB_USER = getEnv("DB_USER", "avnadmin");
    private static final String DB_PASSWORD = getEnv("DB_PASSWORD", "");  // NO DEFAULT PASSWORD!
    
    private static final String DEFAULT_URL = 
        "jdbc:mysql://" + DB_HOST + ":" + DB_PORT + "/" + DB_NAME + 
        "?sslMode=DISABLED&allowPublicKeyRetrieval=true&serverTimezone=UTC";

    static {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            System.out.println("MySQL JDBC Driver Loaded Successfully");
        } catch (ClassNotFoundException e) {
            System.out.println("Failed to Load MySQL JDBC Driver");
            e.printStackTrace();
        }
    }

    private static String getEnv(String key, String defaultValue) {
        String value = System.getenv(key);
        return (value != null && !value.isEmpty()) ? value : defaultValue;
    }

    public static Connection getConnection() throws SQLException {
        System.out.println("Attempting Database Connection...");
        
        String password = System.getenv("DB_PASSWORD");
        if (password == null || password.isEmpty()) {
            System.err.println("ERROR: DB_PASSWORD environment variable not set!");
            throw new SQLException("Database password not configured");
        }
        
        Connection conn = DriverManager.getConnection(DEFAULT_URL, DB_USER, password);
        System.out.println("DATABASE CONNECTED SUCCESSFULLY");
        return conn;
    }

    public static String describeConnectionSettings() {
        return "url=" + DEFAULT_URL + ", username=" + DB_USER;
    }

    public static void closeConnection(Connection conn) {
        if (conn != null) {
            try { conn.close(); } catch (SQLException e) { e.printStackTrace(); }
        }
    }

    public static void closeStatement(Statement stmt) {
        if (stmt != null) {
            try { stmt.close(); } catch (SQLException e) { e.printStackTrace(); }
        }
    }

    public static void closeResultSet(ResultSet rs) {
        if (rs != null) {
            try { rs.close(); } catch (SQLException e) { e.printStackTrace(); }
        }
    }
}