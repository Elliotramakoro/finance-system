// src/java/mpeoa/controllers/ViewPurchaseServlet.java
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

@WebServlet("/admin/purchase-view")
public class ViewPurchaseServlet extends HttpServlet {
    
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
            
            // Set attributes for the view
            request.setAttribute("purchase", purchase);
            request.getRequestDispatcher("/admin/view-purchase.jsp").forward(request, response);
            
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/admin/purchases.jsp?error=Invalid purchase ID");
        }
    }
}