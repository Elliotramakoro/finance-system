// src/java/mpeoa/controllers/AddUserServlet.java
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

@WebServlet("/admin/user-add")
public class AddUserServlet extends HttpServlet {
    
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
        String username = request.getParameter("username");
        String fullName = request.getParameter("fullName");
        String email = request.getParameter("email");
        String password = request.getParameter("password");
        String roleIdStr = request.getParameter("roleId");
        String isActiveStr = request.getParameter("isActive");
        
        // Validate input
        if (username == null || username.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/users.jsp?error=Username is required");
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
        
        if (password == null || password.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/users.jsp?error=Password is required");
            return;
        }
        
        if (roleIdStr == null || roleIdStr.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/users.jsp?error=Role is required");
            return;
        }
        
        // Validate password strength
        if (password.length() < 8) {
            response.sendRedirect(request.getContextPath() + "/admin/users.jsp?error=Password must be at least 8 characters");
            return;
        }
        
        // Parse role ID
        int roleId;
        try {
            roleId = Integer.parseInt(roleIdStr);
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/admin/users.jsp?error=Invalid role selected");
            return;
        }
        
        // Parse active status
        boolean isActive = "true".equalsIgnoreCase(isActiveStr);
        
        // Create user object
        User newUser = new User();
        newUser.setUsername(username.trim());
        newUser.setFullName(fullName.trim());
        newUser.setEmail(email.trim());
        newUser.setPassword(password);
        newUser.setRoleId(roleId);
        newUser.setIsActive(isActive);
        
        // Save to database
        boolean created = userDAO.createUser(newUser);
        
        if (created) {
            response.sendRedirect(request.getContextPath() + "/admin/users.jsp?success=User created successfully");
        } else {
            response.sendRedirect(request.getContextPath() + "/admin/users.jsp?error=Failed to create user. Username or email may already exist.");
        }
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // Redirect to users page if GET request
        response.sendRedirect(request.getContextPath() + "/admin/users.jsp");
    }
}