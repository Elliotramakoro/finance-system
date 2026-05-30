// src/java/mpeoa/controllers/AdminDashboardServlet.java
package mpeoa.controllers;

import mpeoa.dao.*;
import mpeoa.models.User;
import java.io.IOException;
import java.math.BigDecimal;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/admin/dashboard")
public class AdminDashboardServlet extends HttpServlet {
    
    private UserDAO userDAO;
    private ProductDAO productDAO;
    private SaleDAO saleDAO;
    private ExpenseDAO expenseDAO;
    private SupplierDAO supplierDAO;
    
    @Override
    public void init() throws ServletException {
        userDAO = new UserDAO();
        productDAO = new ProductDAO();
        saleDAO = new SaleDAO();
        expenseDAO = new ExpenseDAO();
        supplierDAO = new SupplierDAO();
        System.out.println("=== AdminDashboardServlet Initialized ===");
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
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
        
        try {
            // Get data from database
            int totalUsers = userDAO.getUserCount();
            int totalProducts = productDAO.getProductCount();
            int totalSales = saleDAO.getSaleCount();
            int totalSuppliers = supplierDAO.getSupplierCount();
            BigDecimal todaySales = saleDAO.getTotalSalesToday();
            BigDecimal todayExpenses = expenseDAO.getTotalExpensesToday();
            BigDecimal profit = todaySales.subtract(todayExpenses);
            List<mpeoa.models.Product> lowStockProducts = productDAO.getLowStockProducts();
            List<mpeoa.models.Sale> recentSales = saleDAO.getRecentSales(5);
            
            // Set attributes for JSP
            request.setAttribute("totalUsers", totalUsers);
            request.setAttribute("totalProducts", totalProducts);
            request.setAttribute("totalSales", totalSales);
            request.setAttribute("totalSuppliers", totalSuppliers);
            request.setAttribute("todaySales", todaySales);
            request.setAttribute("todayExpenses", todayExpenses);
            request.setAttribute("profit", profit);
            request.setAttribute("lowStockCount", lowStockProducts.size());
            request.setAttribute("lowStockProducts", lowStockProducts);
            request.setAttribute("recentSales", recentSales);
            
            // Forward to JSP
            request.getRequestDispatcher("/admin/dashboard.jsp").forward(request, response);
            
        } catch (Exception e) {
            System.err.println("Error loading dashboard: " + e.getMessage());
            e.printStackTrace();
            response.sendError(500, "Error loading dashboard");
        }
    }
}