// src/java/mpeoa/controllers/AddProductServlet.java
package mpeoa.controllers;

import mpeoa.dao.ProductDAO;
import mpeoa.models.Product;
import mpeoa.models.User;
import java.io.IOException;
import java.math.BigDecimal;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/admin/product-add")
public class AddProductServlet extends HttpServlet {
    
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
        
        // Get form parameters
        String productCode = request.getParameter("productCode");
        String productName = request.getParameter("productName");
        String categoryIdStr = request.getParameter("categoryId");
        String unitPriceStr = request.getParameter("unitPrice");
        String costPriceStr = request.getParameter("costPrice");
        String initialStockStr = request.getParameter("initialStock");
        String reorderLevelStr = request.getParameter("reorderLevel");
        String description = request.getParameter("description");
        
        // Validate input
        if (productCode == null || productCode.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/products.jsp?error=Product code is required");
            return;
        }
        
        if (productName == null || productName.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/products.jsp?error=Product name is required");
            return;
        }
        
        if (categoryIdStr == null || categoryIdStr.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/products.jsp?error=Category is required");
            return;
        }
        
        if (unitPriceStr == null || unitPriceStr.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/products.jsp?error=Unit price is required");
            return;
        }
        
        if (costPriceStr == null || costPriceStr.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/products.jsp?error=Cost price is required");
            return;
        }
        
        try {
            int categoryId = Integer.parseInt(categoryIdStr);
            BigDecimal unitPrice = new BigDecimal(unitPriceStr);
            BigDecimal costPrice = new BigDecimal(costPriceStr);
            int initialStock = (initialStockStr != null && !initialStockStr.isEmpty()) ? Integer.parseInt(initialStockStr) : 0;
            int reorderLevel = (reorderLevelStr != null && !reorderLevelStr.isEmpty()) ? Integer.parseInt(reorderLevelStr) : 10;
            
            // Create product object
            Product product = new Product();
            product.setProductCode(productCode.trim().toUpperCase());
            product.setProductName(productName.trim());
            product.setCategoryId(categoryId);
            product.setUnitPrice(unitPrice);
            product.setCostPrice(costPrice);
            product.setStockQuantity(initialStock);
            product.setReorderLevel(reorderLevel);
            product.setDescription(description != null ? description.trim() : "");
            
            // Save to database
            boolean created = productDAO.createProduct(product);
            
            if (created) {
                response.sendRedirect(request.getContextPath() + "/admin/products.jsp?success=Product created successfully");
            } else {
                response.sendRedirect(request.getContextPath() + "/admin/products.jsp?error=Failed to create product. Product code may already exist.");
            }
            
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/admin/products.jsp?error=Invalid number format");
        }
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect(request.getContextPath() + "/admin/products.jsp");
    }
}