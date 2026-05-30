// src/java/mpeoa/controllers/AddExpenseServlet.java
package mpeoa.controllers;

import mpeoa.dao.ExpenseDAO;
import mpeoa.models.Expense;
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

@WebServlet("/admin/expense-add")
public class AddExpenseServlet extends HttpServlet {
    
    private ExpenseDAO expenseDAO;
    
    @Override
    public void init() throws ServletException {
        super.init();
        expenseDAO = new ExpenseDAO();
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
        
        // Allow only Administrator, Accountant, and Manager to add expenses
        if (!"Administrator".equalsIgnoreCase(role) && !"Accountant".equalsIgnoreCase(role) && !"Manager".equalsIgnoreCase(role)) {
            response.sendError(403, "Access Denied");
            return;
        }
        
        // Get form parameters
        String expenseCategory = request.getParameter("expenseCategory");
        String description = request.getParameter("description");
        String amountStr = request.getParameter("amount");
        String expenseDateStr = request.getParameter("expenseDate");
        String paymentMethod = request.getParameter("paymentMethod");
        String receiptNumber = request.getParameter("receiptNumber");
        
        // Validate input
        if (expenseCategory == null || expenseCategory.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/expenses.jsp?error=Expense category is required");
            return;
        }
        
        if (amountStr == null || amountStr.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/expenses.jsp?error=Amount is required");
            return;
        }
        
        if (expenseDateStr == null || expenseDateStr.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/admin/expenses.jsp?error=Expense date is required");
            return;
        }
        
        try {
            BigDecimal amount = new BigDecimal(amountStr);
            Date expenseDate = Date.valueOf(expenseDateStr);
            
            Expense expense = new Expense();
            expense.setExpenseCategory(expenseCategory);
            expense.setDescription(description != null ? description.trim() : "");
            expense.setAmount(amount);
            expense.setExpenseDate(expenseDate);
            expense.setPaymentMethod(paymentMethod != null ? paymentMethod : "Cash");
            expense.setReceiptNumber(receiptNumber != null ? receiptNumber.trim() : "");
            expense.setRecordedBy(loggedInUser.getUserId());
            
            // If user is Administrator or Manager, auto-approve
            if ("Administrator".equalsIgnoreCase(role) || "Manager".equalsIgnoreCase(role)) {
                expense.setStatus("Approved");
                expense.setApprovedBy(loggedInUser.getUserId());
            } else {
                expense.setStatus("Pending");
            }
            
            boolean created = expenseDAO.createExpense(expense);
            
            if (created) {
                response.sendRedirect(request.getContextPath() + "/admin/expenses.jsp?success=Expense recorded successfully");
            } else {
                response.sendRedirect(request.getContextPath() + "/admin/expenses.jsp?error=Failed to record expense");
            }
            
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/admin/expenses.jsp?error=Invalid amount format");
        } catch (IllegalArgumentException e) {
            response.sendRedirect(request.getContextPath() + "/admin/expenses.jsp?error=Invalid date format");
        } catch (Exception e) {
            response.sendRedirect(request.getContextPath() + "/admin/expenses.jsp?error=An error occurred: " + e.getMessage());
        }
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect(request.getContextPath() + "/admin/expenses.jsp");
    }
}