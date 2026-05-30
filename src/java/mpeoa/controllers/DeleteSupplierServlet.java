// src/java/mpeoa/controllers/DeleteSupplierServlet.java
package mpeoa.controllers;

import mpeoa.dao.SupplierDAO;
import mpeoa.models.User;
import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/admin/supplier-delete")
public class DeleteSupplierServlet extends HttpServlet {
    
    private SupplierDAO supplierDAO;
    
    @Override
    public void init() throws ServletException {
        super.init();
        supplierDAO = new SupplierDAO();
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
        
        // Get supplier ID to delete
        String supplierIdStr = request.getParameter("supplierId");
        
        if (supplierIdStr == null || supplierIdStr.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/suppliers.jsp?error=Supplier ID is required");
            return;
        }
        
        try {
            int supplierId = Integer.parseInt(supplierIdStr);
            
            // Delete supplier (soft delete - set inactive)
            boolean deleted = supplierDAO.deleteSupplier(supplierId);
            
            if (deleted) {
                response.sendRedirect(request.getContextPath() + "/admin/suppliers.jsp?success=Supplier deleted successfully");
            } else {
                response.sendRedirect(request.getContextPath() + "/admin/suppliers.jsp?error=Failed to delete supplier");
            }
            
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/admin/suppliers.jsp?error=Invalid supplier ID");
        }
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect(request.getContextPath() + "/admin/suppliers.jsp");
    }
}