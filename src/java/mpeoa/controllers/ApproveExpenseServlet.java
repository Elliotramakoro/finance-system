// src/java/mpeoa/controllers/ApproveExpenseServlet.java
package mpeoa.controllers;

import mpeoa.dao.ExpenseDAO;
import mpeoa.models.User;
import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/admin/expense-approve")
public class ApproveExpenseServlet extends HttpServlet {
    
    private ExpenseDAO expenseDAO;
    
    @Override
    public void init() throws ServletException {
        super.init();
        expenseDAO = new ExpenseDAO();
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
        
        User loggedInUser = (User) session.getAttribute("user");
        String role = loggedInUser.getRoleName();
        
        // Allow only Administrator and Manager to approve expenses
        if (!"Administrator".equalsIgnoreCase(role) && !"Manager".equalsIgnoreCase(role)) {
            response.sendError(403, "Access Denied. Only Administrators and Managers can approve expenses.");
            return;
        }
        
        String expenseIdStr = request.getParameter("id");
        
        if (expenseIdStr == null || expenseIdStr.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/expenses.jsp?error=Expense ID is required");
            return;
        }
        
        try {
            int expenseId = Integer.parseInt(expenseIdStr);
            
            boolean approved = expenseDAO.approveExpense(expenseId, loggedInUser.getUserId());
            
            if (approved) {
                response.sendRedirect(request.getContextPath() + "/admin/expenses.jsp?success=Expense approved successfully");
            } else {
                response.sendRedirect(request.getContextPath() + "/admin/expenses.jsp?error=Failed to approve expense");
            }
            
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/admin/expenses.jsp?error=Invalid expense ID");
        }
    }
}