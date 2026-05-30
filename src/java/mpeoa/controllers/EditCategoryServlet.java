// src/java/mpeoa/controllers/EditCategoryServlet.java
package mpeoa.controllers;

import mpeoa.dao.CategoryDAO;
import mpeoa.models.Category;
import mpeoa.models.User;
import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/admin/category-edit")
public class EditCategoryServlet extends HttpServlet {
    
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
        
        // Get form parameters
        String categoryIdStr = request.getParameter("categoryId");
        String categoryName = request.getParameter("categoryName");
        String description = request.getParameter("description");
        
        // Validate input
        if (categoryIdStr == null || categoryIdStr.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/categories.jsp?error=Category ID is required");
            return;
        }
        
        if (categoryName == null || categoryName.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/categories.jsp?error=Category name is required");
            return;
        }
        
        try {
            int categoryId = Integer.parseInt(categoryIdStr);
            
            // Get existing category
            Category existingCategory = categoryDAO.getCategoryById(categoryId);
            if (existingCategory == null) {
                response.sendRedirect(request.getContextPath() + "/admin/categories.jsp?error=Category not found");
                return;
            }
            
            // Update category details
            existingCategory.setCategoryName(categoryName.trim());
            existingCategory.setDescription(description != null ? description.trim() : "");
            
            // Save to database
            boolean updated = categoryDAO.updateCategory(existingCategory);
            
            if (updated) {
                response.sendRedirect(request.getContextPath() + "/admin/categories.jsp?success=Category updated successfully");
            } else {
                response.sendRedirect(request.getContextPath() + "/admin/categories.jsp?error=Failed to update category");
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