// src/java/mpeoa/controllers/EditSupplierServlet.java
package mpeoa.controllers;

import mpeoa.dao.SupplierDAO;
import mpeoa.models.Supplier;
import mpeoa.models.User;
import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/admin/supplier-edit")
public class EditSupplierServlet extends HttpServlet {
    
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
        
        // Get form parameters
        String supplierIdStr = request.getParameter("supplierId");
        String supplierName = request.getParameter("supplierName");
        String contactPerson = request.getParameter("contactPerson");
        String phone = request.getParameter("phone");
        String email = request.getParameter("email");
        String address = request.getParameter("address");
        String paymentTerms = request.getParameter("paymentTerms");
        String isActiveStr = request.getParameter("isActive");
        
        // Validate input
        if (supplierIdStr == null || supplierIdStr.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/suppliers.jsp?error=Supplier ID is required");
            return;
        }
        
        if (supplierName == null || supplierName.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/suppliers.jsp?error=Supplier name is required");
            return;
        }
        
        try {
            int supplierId = Integer.parseInt(supplierIdStr);
            
            // Get existing supplier
            Supplier existingSupplier = supplierDAO.getSupplierById(supplierId);
            if (existingSupplier == null) {
                response.sendRedirect(request.getContextPath() + "/admin/suppliers.jsp?error=Supplier not found");
                return;
            }
            
            // Update supplier details
            existingSupplier.setSupplierName(supplierName.trim());
            existingSupplier.setContactPerson(contactPerson != null ? contactPerson.trim() : "");
            existingSupplier.setPhone(phone != null ? phone.trim() : "");
            existingSupplier.setEmail(email != null ? email.trim() : "");
            existingSupplier.setAddress(address != null ? address.trim() : "");
            existingSupplier.setPaymentTerms(paymentTerms != null ? paymentTerms.trim() : "Net 30");
            existingSupplier.setActive(isActiveStr != null && isActiveStr.equals("true"));
            
            // Save to database
            boolean updated = supplierDAO.updateSupplier(existingSupplier);
            
            if (updated) {
                response.sendRedirect(request.getContextPath() + "/admin/suppliers.jsp?success=Supplier updated successfully");
            } else {
                response.sendRedirect(request.getContextPath() + "/admin/suppliers.jsp?error=Failed to update supplier");
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