// src/java/mpeoa/controllers/DeleteProductServlet.java
package mpeoa.controllers;

import mpeoa.dao.ProductDAO;
import mpeoa.models.User;
import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/admin/product-delete")
public class DeleteProductServlet extends HttpServlet {
    
    private ProductDAO productDAO;
    
    @Override
    public void init() throws ServletException {
        super.init();
        productDAO = new ProductDAO();
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
        
        // Get product ID to delete
        String productIdStr = request.getParameter("productId");
        
        if (productIdStr == null || productIdStr.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/products.jsp?error=Product ID is required");
            return;
        }
        
        try {
            int productId = Integer.parseInt(productIdStr);
            
            // Delete product
            boolean deleted = productDAO.deleteProduct(productId);
            
            if (deleted) {
                response.sendRedirect(request.getContextPath() + "/admin/products.jsp?success=Product deleted successfully");
            } else {
                response.sendRedirect(request.getContextPath() + "/admin/products.jsp?error=Failed to delete product");
            }
            
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/admin/products.jsp?error=Invalid product ID");
        }
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect(request.getContextPath() + "/admin/products.jsp");
    }
}