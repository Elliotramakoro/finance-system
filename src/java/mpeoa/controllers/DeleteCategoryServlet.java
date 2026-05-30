// src/java/mpeoa/controllers/DeleteCategoryServlet.java
package mpeoa.controllers;

import mpeoa.dao.CategoryDAO;
import mpeoa.models.User;
import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/admin/category-delete")
public class DeleteCategoryServlet extends HttpServlet {
    
    private CategoryDAO categoryDAO;
    
    @Override
    public void init() throws ServletException {
        super.init();
        categoryDAO = new CategoryDAO();
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
        
        // Get category ID to delete
        String categoryIdStr = request.getParameter("categoryId");
        
        if (categoryIdStr == null || categoryIdStr.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/categories.jsp?error=Category ID is required");
            return;
        }
        
        try {
            int categoryId = Integer.parseInt(categoryIdStr);
            
            // First check if category has products
            boolean hasProducts = categoryDAO.hasProducts(categoryId);
            
            if (hasProducts) {
                response.sendRedirect(request.getContextPath() + "/admin/categories.jsp?error=Cannot delete category with existing products. Reassign products first.");
                return;
            }
            
            // Delete category
            boolean deleted = categoryDAO.deleteCategory(categoryId);
            
            if (deleted) {
                response.sendRedirect(request.getContextPath() + "/admin/categories.jsp?success=Category deleted successfully");
            } else {
                response.sendRedirect(request.getContextPath() + "/admin/categories.jsp?error=Failed to delete category");
            }
            
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/admin/categories.jsp?error=Invalid category ID");
        }
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect(request.getContextPath() + "/admin/categories.jsp");
    }
}