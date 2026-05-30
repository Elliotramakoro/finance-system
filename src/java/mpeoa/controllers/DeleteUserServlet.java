// src/java/mpeoa/controllers/DeleteUserServlet.java
package mpeoa.controllers;

import mpeoa.dao.UserDAO;
import mpeoa.models.User;
import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/admin/user-delete")
public class DeleteUserServlet extends HttpServlet {
    
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
        
        // Get user ID to delete
        String userIdStr = request.getParameter("userId");
        
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
        
        // Prevent admin from deleting themselves
        if (userId == loggedInUser.getUserId()) {
            response.sendRedirect(request.getContextPath() + "/admin/users.jsp?error=You cannot delete your own account");
            return;
        }
        
        // Delete user
        boolean deleted = userDAO.deleteUser(userId);
        
        if (deleted) {
            response.sendRedirect(request.getContextPath() + "/admin/users.jsp?success=User deleted successfully");
        } else {
            response.sendRedirect(request.getContextPath() + "/admin/users.jsp?error=Failed to delete user");
        }
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect(request.getContextPath() + "/admin/users.jsp");
    }
}