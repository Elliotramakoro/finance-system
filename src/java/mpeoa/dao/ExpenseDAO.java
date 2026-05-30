// src/java/mpeoa/dao/ExpenseDAO.java
package mpeoa.dao;

import mpeoa.models.Expense;
import mpeoa.utils.DatabaseUtil;
import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ExpenseDAO {
    
    public boolean createExpense(Expense expense) {
        String sql = "INSERT INTO expenses (expense_category, description, amount, expense_date, payment_method, receipt_number, recorded_by, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, expense.getExpenseCategory());
            pstmt.setString(2, expense.getDescription());
            pstmt.setBigDecimal(3, expense.getAmount());
            pstmt.setDate(4, expense.getExpenseDate());
            pstmt.setString(5, expense.getPaymentMethod());
            pstmt.setString(6, expense.getReceiptNumber());
            pstmt.setInt(7, expense.getRecordedBy());
            pstmt.setString(8, "Pending");
            
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    public List<Expense> getAllExpenses() {
        List<Expense> expenses = new ArrayList<>();
        String sql = "SELECT e.*, u1.username as recorded_by_name, u2.username as approved_by_name " +
                    "FROM expenses e " +
                    "LEFT JOIN users u1 ON e.recorded_by = u1.user_id " +
                    "LEFT JOIN users u2 ON e.approved_by = u2.user_id " +
                    "ORDER BY e.expense_date DESC";
        
        try (Connection conn = DatabaseUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            
            while (rs.next()) {
                Expense expense = new Expense();
                expense.setExpenseId(rs.getInt("expense_id"));
                expense.setExpenseCategory(rs.getString("expense_category"));
                expense.setDescription(rs.getString("description"));
                expense.setAmount(rs.getBigDecimal("amount"));
                expense.setExpenseDate(rs.getDate("expense_date"));
                expense.setPaymentMethod(rs.getString("payment_method"));
                expense.setReceiptNumber(rs.getString("receipt_number"));
                expense.setStatus(rs.getString("status"));
                expense.setRecordedByName(rs.getString("recorded_by_name"));
                expense.setApprovedByName(rs.getString("approved_by_name"));
                expense.setCreatedAt(rs.getTimestamp("created_at"));
                expenses.add(expense);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return expenses;
    }
    
    public int getExpenseCount() {
        String sql = "SELECT COUNT(*) FROM expenses";
        try (Connection conn = DatabaseUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }
    
    public BigDecimal getTotalExpensesToday() {
        String sql = "SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE DATE(expense_date) = CURDATE() AND status = 'Approved'";
        try (Connection conn = DatabaseUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            if (rs.next()) return rs.getBigDecimal("total");
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return BigDecimal.ZERO;
    }
    
    // This is the method your dashboard is trying to use
    public BigDecimal getTotalExpensesByDateRange(Date startDate, Date endDate) {
        String sql = "SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE expense_date BETWEEN ? AND ? AND status = 'Approved'";
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setDate(1, startDate);
            pstmt.setDate(2, endDate);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return rs.getBigDecimal("total");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return BigDecimal.ZERO;
    }
    
    public BigDecimal getTotalExpensesByMonth() {
        String sql = "SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE MONTH(expense_date) = MONTH(CURDATE()) AND YEAR(expense_date) = YEAR(CURDATE()) AND status = 'Approved'";
        try (Connection conn = DatabaseUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            if (rs.next()) return rs.getBigDecimal("total");
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return BigDecimal.ZERO;
    }
    public List<Object[]> getDailyExpensesForPeriod(java.sql.Date startDate, java.sql.Date endDate) {
    List<Object[]> dailyExpenses = new ArrayList<>();
    String sql = "SELECT DATE(expense_date) as expense_date, COALESCE(SUM(amount), 0) as total " +
                 "FROM expenses WHERE DATE(expense_date) BETWEEN ? AND ? " +
                 "GROUP BY DATE(expense_date) ORDER BY expense_date ASC";
    try (Connection conn = DatabaseUtil.getConnection();
         PreparedStatement pstmt = conn.prepareStatement(sql)) {
        pstmt.setDate(1, startDate);
        pstmt.setDate(2, endDate);
        ResultSet rs = pstmt.executeQuery();
        while (rs.next()) {
            Object[] row = new Object[2];
            row[0] = rs.getDate("expense_date").toString();
            row[1] = rs.getBigDecimal("total");
            dailyExpenses.add(row);
        }
    } catch (SQLException e) {
        e.printStackTrace();
    }
    return dailyExpenses;
}
    public List<Object[]> getExpensesByCategoryForPeriod(java.sql.Date startDate, java.sql.Date endDate) {
    List<Object[]> expenses = new ArrayList<>();
    String sql = "SELECT expense_category, COALESCE(SUM(amount), 0) as total " +
                 "FROM expenses WHERE expense_date BETWEEN ? AND ? AND status = 'Approved' " +
                 "GROUP BY expense_category ORDER BY total DESC";
    try (Connection conn = DatabaseUtil.getConnection();
         PreparedStatement pstmt = conn.prepareStatement(sql)) {
        pstmt.setDate(1, startDate);
        pstmt.setDate(2, endDate);
        ResultSet rs = pstmt.executeQuery();
        while (rs.next()) {
            Object[] row = new Object[2];
            row[0] = rs.getString("expense_category");
            row[1] = rs.getBigDecimal("total");
            expenses.add(row);
        }
    } catch (SQLException e) {
        e.printStackTrace();
    }
    return expenses;
}
    public List<Expense> getRecentExpenses(int limit) {
        List<Expense> expenses = new ArrayList<>();
        String sql = "SELECT e.*, u1.username as recorded_by_name FROM expenses e " +
                    "LEFT JOIN users u1 ON e.recorded_by = u1.user_id " +
                    "ORDER BY e.expense_date DESC LIMIT ?";
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, limit);
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                Expense expense = new Expense();
                expense.setExpenseId(rs.getInt("expense_id"));
                expense.setExpenseCategory(rs.getString("expense_category"));
                expense.setDescription(rs.getString("description"));
                expense.setAmount(rs.getBigDecimal("amount"));
                expense.setExpenseDate(rs.getDate("expense_date"));
                expense.setStatus(rs.getString("status"));
                expense.setRecordedByName(rs.getString("recorded_by_name"));
                expenses.add(expense);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return expenses;
    }
    public int getPendingExpensesCount() {
    String sql = "SELECT COUNT(*) FROM expenses WHERE status = 'Pending'";
    try (Connection conn = DatabaseUtil.getConnection();
         Statement stmt = conn.createStatement();
         ResultSet rs = stmt.executeQuery(sql)) {
        if (rs.next()) return rs.getInt(1);
    } catch (SQLException e) {
        e.printStackTrace();
    }
    return 0;
}

public List<Expense> getPendingExpenses() {
    List<Expense> expenses = new ArrayList<>();
    String sql = "SELECT e.*, u1.username as recorded_by_name FROM expenses e " +
                "LEFT JOIN users u1 ON e.recorded_by = u1.user_id " +
                "WHERE e.status = 'Pending' ORDER BY e.expense_date ASC LIMIT 5";
    try (Connection conn = DatabaseUtil.getConnection();
         Statement stmt = conn.createStatement();
         ResultSet rs = stmt.executeQuery(sql)) {
        while (rs.next()) {
            Expense expense = new Expense();
            expense.setExpenseId(rs.getInt("expense_id"));
            expense.setExpenseCategory(rs.getString("expense_category"));
            expense.setDescription(rs.getString("description"));
            expense.setAmount(rs.getBigDecimal("amount"));
            expense.setExpenseDate(rs.getDate("expense_date"));
            expense.setStatus(rs.getString("status"));
            expense.setRecordedByName(rs.getString("recorded_by_name"));
            expenses.add(expense);
        }
    } catch (SQLException e) {
        e.printStackTrace();
    }
    return expenses;
}
    public boolean approveExpense(int expenseId, int approvedBy) {
        String sql = "UPDATE expenses SET status = 'Approved', approved_by = ? WHERE expense_id = ?";
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, approvedBy);
            pstmt.setInt(2, expenseId);
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    public int getApprovedExpensesCount() {
    String sql = "SELECT COUNT(*) FROM expenses WHERE status = 'Approved'";
    try (Connection conn = DatabaseUtil.getConnection();
         Statement stmt = conn.createStatement();
         ResultSet rs = stmt.executeQuery(sql)) {
        if (rs.next()) return rs.getInt(1);
    } catch (SQLException e) {
        e.printStackTrace();
    }
    return 0;
}
    
    public BigDecimal getTotalExpensesByCategory(String category, Date startDate, Date endDate) {
        String sql = "SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE expense_category = ? AND expense_date BETWEEN ? AND ? AND status = 'Approved'";
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, category);
            pstmt.setDate(2, startDate);
            pstmt.setDate(3, endDate);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return rs.getBigDecimal("total");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return BigDecimal.ZERO;
    }
}