// src/java/mpeoa/controllers/EditUserServlet.java
package mpeoa.controllers;

import mpeoa.dao.UserDAO;
import mpeoa.models.User;
import mpeoa.utils.PasswordUtil;
import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/admin/user-edit")
public class EditUserServlet extends HttpServlet {
    
    private UserDAO userDAO;
    
    @Override
    public void init() throws ServletException {
        super.init();
        userDAO = new UserDAO();
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        // Check if user is logged in and is admin
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        
        User loggedInUser = (User) session.getAttribute("user");
        if (!"Administrator".equalsIgnoreCase(loggedInUser.getRoleName())) {
            response.sendError(403, "Access Denied");
            return;
        }
        
        // Get form parameters
        String userIdStr = request.getParameter("userId");
        String fullName = request.getParameter("fullName");
        String email = request.getParameter("email");
        String newPassword = request.getParameter("password");
        String roleIdStr = request.getParameter("roleId");
        String isActiveStr = request.getParameter("isActive");
        
        // Validate input
        if (userIdStr == null || userIdStr.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/users.jsp?error=User ID is required");
            return;
        }
        
        int userId;
        try {
            userId = Integer.parseInt(userIdStr);
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/admin/users.jsp?error=Invalid user ID");
            return;
        }
        
        if (fullName == null || fullName.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/users.jsp?error=Full name is required");
            return;
        }
        
        if (email == null || email.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/users.jsp?error=Email is required");
            return;
        }
        
        // Get existing user
        User existingUser = userDAO.getUserById(userId);
        if (existingUser == null) {
            response.sendRedirect(request.getContextPath() + "/admin/users.jsp?error=User not found");
            return;
        }
        
        // Update user details
        existingUser.setFullName(fullName.trim());
        existingUser.setEmail(email.trim());
        
        if (roleIdStr != null && !roleIdStr.trim().isEmpty()) {
            try {
                existingUser.setRoleId(Integer.parseInt(roleIdStr));
            } catch (NumberFormatException e) {
                // Keep existing role
            }
        }
        
        if (isActiveStr != null) {
            existingUser.setIsActive("true".equalsIgnoreCase(isActiveStr));
        }
        
        // Update password if provided
        if (newPassword != null && !newPassword.trim().isEmpty()) {
            if (newPassword.length() >= 8) {
                userDAO.changePassword(userId, newPassword);
            } else {
                response.sendRedirect(request.getContextPath() + "/admin/users.jsp?error=Password must be at least 8 characters");
                return;
            }
        }
        
        // Save to database
        boolean updated = userDAO.updateUser(existingUser);
        
        if (updated) {
            response.sendRedirect(request.getContextPath() + "/admin/users.jsp?success=User updated successfully");
        } else {
            response.sendRedirect(request.getContextPath() + "/admin/users.jsp?error=Failed to update user");
        }
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect(request.getContextPath() + "/admin/users.jsp");
    }
}