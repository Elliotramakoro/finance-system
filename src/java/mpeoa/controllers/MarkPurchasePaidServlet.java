// src/java/mpeoa/controllers/MarkPurchasePaidServlet.java
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

@WebServlet("/admin/purchase-paid")
public class MarkPurchasePaidServlet extends HttpServlet {
    
    private PurchaseDAO purchaseDAO;
    
    @Override
    public void init() throws ServletException {
        super.init();
        purchaseDAO = new PurchaseDAO();
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
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
        
        // Get purchase ID
        String purchaseIdStr = request.getParameter("id");
        
        if (purchaseIdStr == null || purchaseIdStr.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/purchases.jsp?error=Purchase ID is required");
            return;
        }
        
        try {
            int purchaseId = Integer.parseInt(purchaseIdStr);
            
            // Mark as paid
            boolean updated = purchaseDAO.markAsPaid(purchaseId);
            
            if (updated) {
                response.sendRedirect(request.getContextPath() + "/admin/purchases.jsp?success=Purchase order marked as paid");
            } else {
                response.sendRedirect(request.getContextPath() + "/admin/purchases.jsp?error=Failed to update payment status");
            }
            
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/admin/purchases.jsp?error=Invalid purchase ID");
        }
    }
}