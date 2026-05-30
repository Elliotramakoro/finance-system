// src/java/mpeoa/dao/UserDAO.java
package mpeoa.dao;

import mpeoa.models.User;
import mpeoa.utils.DatabaseUtil;
import mpeoa.utils.PasswordUtil;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class UserDAO {
    
    public User authenticate(String username, String password) {
        System.out.println("=== Authenticating user: " + username + " ===");
        System.out.println("Database settings: " + DatabaseUtil.describeConnectionSettings());
        
        String sql = "SELECT u.*, r.role_name FROM users u " +
                    "JOIN roles r ON u.role_id = r.role_id " +
                    "WHERE u.username = ? AND u.is_active = TRUE";
        
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            System.out.println("Database connection established");
            pstmt.setString(1, username);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                System.out.println("User found in database: " + username);
                String storedPassword = rs.getString("password");
                System.out.println("Stored password hash: " + storedPassword);
                
                String hashedInputPassword = PasswordUtil.hashPassword(password);
                System.out.println("Hashed input password: " + hashedInputPassword);
                
                if (storedPassword.equals(hashedInputPassword)) {
                    System.out.println("Password MATCHES for user: " + username);
                    
                    User user = new User();
                    user.setUserId(rs.getInt("user_id"));
                    user.setUsername(rs.getString("username"));
                    user.setEmail(rs.getString("email"));
                    user.setFullName(rs.getString("full_name"));
                    user.setRoleId(rs.getInt("role_id"));
                    user.setRoleName(rs.getString("role_name"));
                    user.setIsActive(rs.getBoolean("is_active"));
                    user.setLastLogin(rs.getTimestamp("last_login"));
                    user.setCreatedAt(rs.getTimestamp("created_at"));
                    
                    // Update last login time
                    updateLastLogin(user.getUserId());
                    
                    return user;
                } else {
                    System.out.println("Password MISMATCH for user: " + username);
                    System.out.println("Please check if password is correct");
                }
            } else {
                System.out.println("User NOT found in database: " + username);
                System.out.println("Available users in database:");
                showAllUsers();
            }
            
        } catch (SQLException e) {
            System.err.println("Database error during authentication: " + e.getMessage());
            e.printStackTrace();
        }
        return null;
    }
    
    private void showAllUsers() {
        String sql = "SELECT username, email, is_active FROM users";
        try (Connection conn = DatabaseUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            
            System.out.println("=== Users in database ===");
            while (rs.next()) {
                System.out.println("Username: " + rs.getString("username") + 
                                 ", Email: " + rs.getString("email") +
                                 ", Active: " + rs.getBoolean("is_active"));
            }
            System.out.println("========================");
            
        } catch (SQLException e) {
            System.err.println("Error listing users: " + e.getMessage());
        }
    }
    
    private void updateLastLogin(int userId) {
        String sql = "UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE user_id = ?";
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, userId);
            pstmt.executeUpdate();
            System.out.println("Updated last_login for user ID: " + userId);
        } catch (SQLException e) {
            System.err.println("Error updating last login: " + e.getMessage());
        }
    }
    
    public int getUserCount() {
        String sql = "SELECT COUNT(*) FROM users WHERE is_active = TRUE";
        try (Connection conn = DatabaseUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            if (rs.next()) {
                int count = rs.getInt(1);
                System.out.println("Total active users: " + count);
                return count;
            }
        } catch (SQLException e) {
            System.err.println("Error getting user count: " + e.getMessage());
            e.printStackTrace();
        }
        return 0;
    }
    
    public List<User> getAllUsers() {
        List<User> users = new ArrayList<>();
        String sql = "SELECT u.*, r.role_name FROM users u " +
                    "JOIN roles r ON u.role_id = r.role_id " +
                    "ORDER BY u.created_at DESC";
        
        try (Connection conn = DatabaseUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            
            while (rs.next()) {
                User user = new User();
                user.setUserId(rs.getInt("user_id"));
                user.setUsername(rs.getString("username"));
                user.setEmail(rs.getString("email"));
                user.setFullName(rs.getString("full_name"));
                user.setRoleId(rs.getInt("role_id"));
                user.setRoleName(rs.getString("role_name"));
                user.setIsActive(rs.getBoolean("is_active"));
                user.setLastLogin(rs.getTimestamp("last_login"));
                user.setCreatedAt(rs.getTimestamp("created_at"));
                users.add(user);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return users;
    }
    
    public User getUserById(int userId) {
        String sql = "SELECT u.*, r.role_name FROM users u " +
                    "JOIN roles r ON u.role_id = r.role_id " +
                    "WHERE u.user_id = ?";
        
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, userId);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                User user = new User();
                user.setUserId(rs.getInt("user_id"));
                user.setUsername(rs.getString("username"));
                user.setEmail(rs.getString("email"));
                user.setFullName(rs.getString("full_name"));
                user.setRoleId(rs.getInt("role_id"));
                user.setRoleName(rs.getString("role_name"));
                user.setIsActive(rs.getBoolean("is_active"));
                return user;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
    
    public boolean createUser(User user) {
        String sql = "INSERT INTO users (username, password, email, full_name, role_id, is_active) " +
                    "VALUES (?, ?, ?, ?, ?, ?)";
        
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, user.getUsername());
            pstmt.setString(2, PasswordUtil.hashPassword(user.getPassword()));
            pstmt.setString(3, user.getEmail());
            pstmt.setString(4, user.getFullName());
            pstmt.setInt(5, user.getRoleId());
            pstmt.setBoolean(6, user.isIsActive());
            
            int result = pstmt.executeUpdate();
            System.out.println("User created: " + user.getUsername() + ", Result: " + result);
            return result > 0;
        } catch (SQLException e) {
            System.err.println("Error creating user: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
    
    public boolean updateUser(User user) {
        String sql = "UPDATE users SET full_name = ?, email = ?, role_id = ?, is_active = ? WHERE user_id = ?";
        
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, user.getFullName());
            pstmt.setString(2, user.getEmail());
            pstmt.setInt(3, user.getRoleId());
            pstmt.setBoolean(4, user.isIsActive());
            pstmt.setInt(5, user.getUserId());
            
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    public boolean deleteUser(int userId) {
        String sql = "DELETE FROM users WHERE user_id = ?";
        
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, userId);
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    public boolean changePassword(int userId, String newPassword) {
        String sql = "UPDATE users SET password = ? WHERE user_id = ?";
        
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, PasswordUtil.hashPassword(newPassword));
            pstmt.setInt(2, userId);
            
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
}
