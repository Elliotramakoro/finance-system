// src/java/mpeoa/controllers/AddSupplierServlet.java
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

@WebServlet("/admin/supplier-add")
public class AddSupplierServlet extends HttpServlet {
    
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
        String supplierName = request.getParameter("supplierName");
        String contactPerson = request.getParameter("contactPerson");
        String phone = request.getParameter("phone");
        String email = request.getParameter("email");
        String address = request.getParameter("address");
        String paymentTerms = request.getParameter("paymentTerms");
        String isActiveStr = request.getParameter("isActive");
        
        // Validate input
        if (supplierName == null || supplierName.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/suppliers.jsp?error=Supplier name is required");
            return;
        }
        
        // Create supplier object
        Supplier supplier = new Supplier();
        supplier.setSupplierName(supplierName.trim());
        supplier.setContactPerson(contactPerson != null ? contactPerson.trim() : "");
        supplier.setPhone(phone != null ? phone.trim() : "");
        supplier.setEmail(email != null ? email.trim() : "");
        supplier.setAddress(address != null ? address.trim() : "");
        supplier.setPaymentTerms(paymentTerms != null ? paymentTerms.trim() : "Net 30");
        supplier.setActive(isActiveStr != null && isActiveStr.equals("true"));
        
        // Save to database
        boolean created = supplierDAO.createSupplier(supplier);
        
        if (created) {
            response.sendRedirect(request.getContextPath() + "/admin/suppliers.jsp?success=Supplier added successfully");
        } else {
            response.sendRedirect(request.getContextPath() + "/admin/suppliers.jsp?error=Failed to add supplier");
        }
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect(request.getContextPath() + "/admin/suppliers.jsp");
    }
}