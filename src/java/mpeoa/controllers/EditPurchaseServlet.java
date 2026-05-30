// src/java/mpeoa/controllers/EditPurchaseServlet.java
package mpeoa.controllers;

import mpeoa.dao.PurchaseDAO;
import mpeoa.models.Purchase;
import mpeoa.models.User;
import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/admin/purchase-edit")
public class EditPurchaseServlet extends HttpServlet {
    
    private PurchaseDAO purchaseDAO;
    
    @Override
    public void init() throws ServletException {
        super.init();
        purchaseDAO = new PurchaseDAO();
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        // Check if user is logged in
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        
        String purchaseIdStr = request.getParameter("id");
        if (purchaseIdStr == null || purchaseIdStr.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/purchases.jsp?error=Invalid purchase ID");
            return;
        }
        
        try {
            int purchaseId = Integer.parseInt(purchaseIdStr);
            Purchase purchase = purchaseDAO.getPurchaseById(purchaseId);
            
            if (purchase == null) {
                response.sendRedirect(request.getContextPath() + "/admin/purchases.jsp?error=Purchase order not found");
                return;
            }
            
            // Set attributes for the edit form
            request.setAttribute("purchase", purchase);
            request.getRequestDispatcher("/admin/edit-purchase.jsp").forward(request, response);
            
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/admin/purchases.jsp?error=Invalid purchase ID");
        }
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        // Check if user is logged in
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
        String purchaseIdStr = request.getParameter("purchaseId");
        String purchaseDateStr = request.getParameter("purchaseDate");
        String totalAmountStr = request.getParameter("totalAmount");
        String paymentStatus = request.getParameter("paymentStatus");
        String deliveredBy = request.getParameter("deliveredBy");
        
        if (purchaseIdStr == null || purchaseIdStr.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/purchases.jsp?error=Purchase ID is required");
            return;
        }
        
        try {
            int purchaseId = Integer.parseInt(purchaseIdStr);
            Purchase existingPurchase = purchaseDAO.getPurchaseById(purchaseId);
            
            if (existingPurchase == null) {
                response.sendRedirect(request.getContextPath() + "/admin/purchases.jsp?error=Purchase order not found");
                return;
            }
            
            // Update fields
            if (purchaseDateStr != null && !purchaseDateStr.isEmpty()) {
                existingPurchase.setPurchaseDate(java.sql.Date.valueOf(purchaseDateStr));
            }
            if (totalAmountStr != null && !totalAmountStr.isEmpty()) {
                existingPurchase.setTotalAmount(new java.math.BigDecimal(totalAmountStr));
            }
            if (paymentStatus != null) {
                existingPurchase.setPaymentStatus(paymentStatus);
            }
            if (deliveredBy != null) {
                existingPurchase.setDeliveredBy(deliveredBy);
            }
            
            boolean updated = purchaseDAO.updatePurchase(existingPurchase);
            
            if (updated) {
                response.sendRedirect(request.getContextPath() + "/admin/purchases.jsp?success=Purchase order updated successfully");
            } else {
                response.sendRedirect(request.getContextPath() + "/admin/purchases.jsp?error=Failed to update purchase order");
            }
            
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/admin/purchases.jsp?error=Invalid purchase ID");
        } catch (IllegalArgumentException e) {
            response.sendRedirect(request.getContextPath() + "/admin/purchases.jsp?error=Invalid date format");
        }
    }
}