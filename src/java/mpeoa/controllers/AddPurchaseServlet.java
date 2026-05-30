// src/java/mpeoa/controllers/AddPurchaseServlet.java
package mpeoa.controllers;

import mpeoa.dao.PurchaseDAO;
import mpeoa.dao.SupplierDAO;
import mpeoa.models.Purchase;
import mpeoa.models.Supplier;
import mpeoa.models.User;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Date;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/admin/purchase-add")
public class AddPurchaseServlet extends HttpServlet {
    
    private PurchaseDAO purchaseDAO;
    private SupplierDAO supplierDAO;
    
    @Override
    public void init() throws ServletException {
        super.init();
        purchaseDAO = new PurchaseDAO();
        supplierDAO = new SupplierDAO();
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        // Check if user is logged in and has permission
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        
        User loggedInUser = (User) session.getAttribute("user");
        String role = loggedInUser.getRoleName();
        if (!"Administrator".equalsIgnoreCase(role) && !"Manager".equalsIgnoreCase(role) && !"Inventory Officer".equalsIgnoreCase(role)) {
            response.sendError(403, "Access Denied");
            return;
        }
        
        // Get form parameters
        String supplierIdStr = request.getParameter("supplierId");
        String purchaseDateStr = request.getParameter("purchaseDate");
        String totalAmountStr = request.getParameter("totalAmount");
        String paymentStatus = request.getParameter("paymentStatus");
        String deliveredBy = request.getParameter("deliveredBy");
        
        // Validate input
        if (supplierIdStr == null || supplierIdStr.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/purchases.jsp?error=Supplier is required");
            return;
        }
        
        if (purchaseDateStr == null || purchaseDateStr.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/purchases.jsp?error=Purchase date is required");
            return;
        }
        
        if (totalAmountStr == null || totalAmountStr.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/purchases.jsp?error=Total amount is required");
            return;
        }
        
        int supplierId = 0;
        Date purchaseDate = null;
        BigDecimal totalAmount = null;
        
        try {
            supplierId = Integer.parseInt(supplierIdStr);
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/admin/purchases.jsp?error=Invalid supplier ID format");
            return;
        }
        
        try {
            purchaseDate = Date.valueOf(purchaseDateStr);
        } catch (IllegalArgumentException e) {
            response.sendRedirect(request.getContextPath() + "/admin/purchases.jsp?error=Invalid date format. Use YYYY-MM-DD");
            return;
        }
        
        try {
            totalAmount = new BigDecimal(totalAmountStr);
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/admin/purchases.jsp?error=Invalid amount format");
            return;
        }
        
        try {
            // Verify supplier exists
            Supplier supplier = supplierDAO.getSupplierById(supplierId);
            if (supplier == null) {
                response.sendRedirect(request.getContextPath() + "/admin/purchases.jsp?error=Supplier not found");
                return;
            }
            
            // Create purchase object
            Purchase purchase = new Purchase();
            purchase.setSupplierId(supplierId);
            purchase.setPurchaseDate(purchaseDate);
            purchase.setTotalAmount(totalAmount);
            purchase.setPaymentStatus(paymentStatus != null ? paymentStatus : "Pending");
            purchase.setDeliveredBy(deliveredBy != null ? deliveredBy.trim() : "");
            purchase.setReceivedBy(loggedInUser.getUserId());
            
            // Save to database
            boolean created = purchaseDAO.createPurchase(purchase);
            
            if (created) {
                response.sendRedirect(request.getContextPath() + "/admin/purchases.jsp?success=Purchase order created successfully");
            } else {
                response.sendRedirect(request.getContextPath() + "/admin/purchases.jsp?error=Failed to create purchase order");
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/admin/purchases.jsp?error=An error occurred: " + e.getMessage());
        }
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect(request.getContextPath() + "/admin/purchases.jsp");
    }
}