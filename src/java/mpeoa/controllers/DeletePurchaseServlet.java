// src/java/mpeoa/controllers/DeletePurchaseServlet.java
package mpeoa.controllers;

import mpeoa.dao.PurchaseDAO;
import mpeoa.models.User;
import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/admin/purchase-delete")
public class DeletePurchaseServlet extends HttpServlet {
    
    private PurchaseDAO purchaseDAO;
    
    @Override
    public void init() throws ServletException {
        super.init();
        purchaseDAO = new PurchaseDAO();
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
        if (!"Administrator".equalsIgnoreCase(role) && !"Manager".equalsIgnoreCase(role)) {
            response.sendError(403, "Access Denied");
            return;
        }
        
        // Get purchase ID to delete
        String purchaseIdStr = request.getParameter("purchaseId");
        
        if (purchaseIdStr == null || purchaseIdStr.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/purchases.jsp?error=Purchase ID is required");
            return;
        }
        
        try {
            int purchaseId = Integer.parseInt(purchaseIdStr);
            
            // Delete purchase
            boolean deleted = purchaseDAO.deletePurchase(purchaseId);
            
            if (deleted) {
                response.sendRedirect(request.getContextPath() + "/admin/purchases.jsp?success=Purchase order deleted successfully");
            } else {
                response.sendRedirect(request.getContextPath() + "/admin/purchases.jsp?error=Failed to delete purchase order");
            }
            
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/admin/purchases.jsp?error=Invalid purchase ID");
        }
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect(request.getContextPath() + "/admin/purchases.jsp");
    }
}