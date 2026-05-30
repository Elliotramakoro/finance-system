// src/java/mpeoa/controllers/EditProductServlet.java
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

@WebServlet("/admin/product-edit")
public class EditProductServlet extends HttpServlet {
    
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
        String productIdStr = request.getParameter("productId");
        String productName = request.getParameter("productName");
        String unitPriceStr = request.getParameter("unitPrice");
        String costPriceStr = request.getParameter("costPrice");
        String description = request.getParameter("description");
        
        // Validate input
        if (productIdStr == null || productIdStr.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/products.jsp?error=Product ID is required");
            return;
        }
        
        if (productName == null || productName.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/products.jsp?error=Product name is required");
            return;
        }
        
        try {
            int productId = Integer.parseInt(productIdStr);
            BigDecimal unitPrice = new BigDecimal(unitPriceStr);
            BigDecimal costPrice = new BigDecimal(costPriceStr);
            
            // Get existing product
            Product existingProduct = productDAO.getProductById(productId);
            if (existingProduct == null) {
                response.sendRedirect(request.getContextPath() + "/admin/products.jsp?error=Product not found");
                return;
            }
            
            // Update product details
            existingProduct.setProductName(productName.trim());
            existingProduct.setUnitPrice(unitPrice);
            existingProduct.setCostPrice(costPrice);
            existingProduct.setDescription(description != null ? description.trim() : "");
            
            // Note: We're not updating category or product code here as they might have constraints
            // For a full update, you would need to add those fields to the edit form
            
            // Save to database - you need to add an updateProduct method in ProductDAO
            // For now, we'll create a simple update
            boolean updated = updateProductInDatabase(existingProduct);
            
            if (updated) {
                response.sendRedirect(request.getContextPath() + "/admin/products.jsp?success=Product updated successfully");
            } else {
                response.sendRedirect(request.getContextPath() + "/admin/products.jsp?error=Failed to update product");
            }
            
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/admin/products.jsp?error=Invalid number format");
        }
    }
    
    private boolean updateProductInDatabase(Product product) {
        String sql = "UPDATE products SET product_name = ?, unit_price = ?, cost_price = ?, description = ? WHERE product_id = ?";
        try (java.sql.Connection conn = mpeoa.utils.DatabaseUtil.getConnection();
             java.sql.PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, product.getProductName());
            pstmt.setBigDecimal(2, product.getUnitPrice());
            pstmt.setBigDecimal(3, product.getCostPrice());
            pstmt.setString(4, product.getDescription());
            pstmt.setInt(5, product.getProductId());
            return pstmt.executeUpdate() > 0;
        } catch (java.sql.SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect(request.getContextPath() + "/admin/products.jsp");
    }
}