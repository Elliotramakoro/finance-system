// src/java/mpeoa/controllers/AddCategoryServlet.java
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

@WebServlet("/admin/category-add")
public class AddCategoryServlet extends HttpServlet {
    
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
        String categoryName = request.getParameter("categoryName");
        String description = request.getParameter("description");
        
        // Validate input
        if (categoryName == null || categoryName.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/categories.jsp?error=Category name is required");
            return;
        }
        
        // Create category object
        Category category = new Category();
        category.setCategoryName(categoryName.trim());
        category.setDescription(description != null ? description.trim() : "");
        
        // Save to database
        boolean created = categoryDAO.createCategory(category);
        
        if (created) {
            response.sendRedirect(request.getContextPath() + "/admin/categories.jsp?success=Category created successfully");
        } else {
            response.sendRedirect(request.getContextPath() + "/admin/categories.jsp?error=Failed to create category. Name may already exist.");
        }
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect(request.getContextPath() + "/admin/categories.jsp");
    }
}