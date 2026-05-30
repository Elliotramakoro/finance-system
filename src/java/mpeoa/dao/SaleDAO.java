// src/java/mpeoa/dao/SaleDAO.java
package mpeoa.dao;

import mpeoa.models.Sale;
import mpeoa.models.SaleItem;
import mpeoa.utils.DatabaseUtil;
import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class SaleDAO {
    
    public boolean createSale(Sale sale) {
        Connection conn = null;
        try {
            conn = DatabaseUtil.getConnection();
            conn.setAutoCommit(false);
            
            String sqlSale = "INSERT INTO sales (invoice_number, user_id, total_amount, discount, tax, final_amount, payment_method) VALUES (?, ?, ?, ?, ?, ?, ?)";
            PreparedStatement pstmtSale = conn.prepareStatement(sqlSale, Statement.RETURN_GENERATED_KEYS);
            pstmtSale.setString(1, sale.getInvoiceNumber());
            pstmtSale.setInt(2, sale.getUserId());
            pstmtSale.setBigDecimal(3, sale.getTotalAmount());
            pstmtSale.setBigDecimal(4, sale.getDiscount());
            pstmtSale.setBigDecimal(5, sale.getTax());
            pstmtSale.setBigDecimal(6, sale.getFinalAmount());
            pstmtSale.setString(7, sale.getPaymentMethod());
            
            int affectedRows = pstmtSale.executeUpdate();
            
            if (affectedRows > 0) {
                ResultSet generatedKeys = pstmtSale.getGeneratedKeys();
                if (generatedKeys.next()) {
                    int saleId = generatedKeys.getInt(1);
                    
                    for (SaleItem item : sale.getItems()) {
                        String sqlItem = "INSERT INTO sales_items (sale_id, product_id, quantity, unit_price, total_price) VALUES (?, ?, ?, ?, ?)";
                        PreparedStatement pstmtItem = conn.prepareStatement(sqlItem);
                        pstmtItem.setInt(1, saleId);
                        pstmtItem.setInt(2, item.getProductId());
                        pstmtItem.setInt(3, item.getQuantity());
                        pstmtItem.setBigDecimal(4, item.getUnitPrice());
                        pstmtItem.setBigDecimal(5, item.getTotalPrice());
                        pstmtItem.executeUpdate();
                        
                        String sqlUpdateInventory = "UPDATE inventory SET quantity = quantity - ? WHERE product_id = ?";
                        PreparedStatement pstmtInventory = conn.prepareStatement(sqlUpdateInventory);
                        pstmtInventory.setInt(1, item.getQuantity());
                        pstmtInventory.setInt(2, item.getProductId());
                        pstmtInventory.executeUpdate();
                    }
                }
            }
            
            conn.commit();
            return true;
            
        } catch (SQLException e) {
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ex) { ex.printStackTrace(); }
            }
            e.printStackTrace();
            return false;
        } finally {
            if (conn != null) {
                try { conn.setAutoCommit(true); conn.close(); } catch (SQLException e) { e.printStackTrace(); }
            }
        }
    }
    
    public List<Sale> getAllSales() {
        List<Sale> sales = new ArrayList<>();
        String sql = "SELECT s.*, u.username as user_name FROM sales s " +
                    "JOIN users u ON s.user_id = u.user_id " +
                    "ORDER BY s.sale_date DESC";
        
        try (Connection conn = DatabaseUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            
            while (rs.next()) {
                Sale sale = new Sale();
                sale.setSaleId(rs.getInt("sale_id"));
                sale.setInvoiceNumber(rs.getString("invoice_number"));
                sale.setUserId(rs.getInt("user_id"));
                sale.setUserName(rs.getString("user_name"));
                sale.setTotalAmount(rs.getBigDecimal("total_amount"));
                sale.setDiscount(rs.getBigDecimal("discount"));
                sale.setTax(rs.getBigDecimal("tax"));
                sale.setFinalAmount(rs.getBigDecimal("final_amount"));
                sale.setPaymentMethod(rs.getString("payment_method"));
                sale.setSaleDate(rs.getTimestamp("sale_date"));
                sales.add(sale);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return sales;
    }
    
    public int getSaleCount() {
        String sql = "SELECT COUNT(*) FROM sales";
        try (Connection conn = DatabaseUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }
    
    public BigDecimal getTotalSalesToday() {
        String sql = "SELECT COALESCE(SUM(final_amount), 0) as total FROM sales WHERE DATE(sale_date) = CURDATE()";
        try (Connection conn = DatabaseUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            if (rs.next()) return rs.getBigDecimal("total");
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return BigDecimal.ZERO;
    }
    
    public BigDecimal getTotalSalesByMonth() {
        String sql = "SELECT COALESCE(SUM(final_amount), 0) as total FROM sales WHERE MONTH(sale_date) = MONTH(CURDATE()) AND YEAR(sale_date) = YEAR(CURDATE())";
        try (Connection conn = DatabaseUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            if (rs.next()) return rs.getBigDecimal("total");
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return BigDecimal.ZERO;
    }
    
    public List<Sale> getRecentSales(int limit) {
        List<Sale> sales = new ArrayList<>();
        String sql = "SELECT s.*, u.username as user_name FROM sales s " +
                    "JOIN users u ON s.user_id = u.user_id " +
                    "ORDER BY s.sale_date DESC LIMIT ?";
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, limit);
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                Sale sale = new Sale();
                sale.setSaleId(rs.getInt("sale_id"));
                sale.setInvoiceNumber(rs.getString("invoice_number"));
                sale.setFinalAmount(rs.getBigDecimal("final_amount"));
                sale.setPaymentMethod(rs.getString("payment_method"));
                sale.setSaleDate(rs.getTimestamp("sale_date"));
                sale.setUserName(rs.getString("user_name"));
                sales.add(sale);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return sales;
    }
    
    // ==================== METHODS FOR ANALYTICS ====================
    
    public BigDecimal getTotalSalesByDateRange(java.sql.Date startDate, java.sql.Date endDate) {
        String sql = "SELECT COALESCE(SUM(final_amount), 0) as total FROM sales WHERE DATE(sale_date) BETWEEN ? AND ?";
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
    
    public List<Object[]> getDailySalesForPeriod(java.sql.Date startDate, java.sql.Date endDate) {
        List<Object[]> dailySales = new ArrayList<>();
        String sql = "SELECT DATE(sale_date) as sale_date, COALESCE(SUM(final_amount), 0) as total " +
                     "FROM sales WHERE DATE(sale_date) BETWEEN ? AND ? " +
                     "GROUP BY DATE(sale_date) ORDER BY sale_date ASC";
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setDate(1, startDate);
            pstmt.setDate(2, endDate);
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                Object[] row = new Object[2];
                row[0] = rs.getDate("sale_date").toString();
                row[1] = rs.getBigDecimal("total");
                dailySales.add(row);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return dailySales;
    }
    
    /**
     * Get hourly sales distribution for a date range
     * This method groups sales by hour of day (0-23)
     * 
     * @param startDate Start date for the query
     * @param endDate End date for the query
     * @return List of Object[] where each array contains [hour (0-23), total_amount]
     */
    public List<Object[]> getHourlySalesForPeriod(java.sql.Date startDate, java.sql.Date endDate) {
        List<Object[]> hourlySales = new ArrayList<>();
        
        // MySQL version using HOUR() function
        String sql = "SELECT HOUR(sale_date) as hour, COALESCE(SUM(final_amount), 0) as total " +
                     "FROM sales WHERE DATE(sale_date) BETWEEN ? AND ? " +
                     "GROUP BY HOUR(sale_date) " +
                     "ORDER BY hour ASC";
        
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setDate(1, startDate);
            pstmt.setDate(2, endDate);
            ResultSet rs = pstmt.executeQuery();
            
            // Initialize all hours 0-23 with zero values
            // This ensures we have data for every hour even if no sales occurred
            for (int hour = 0; hour <= 23; hour++) {
                Object[] row = new Object[2];
                row[0] = hour;
                row[1] = BigDecimal.ZERO;
                hourlySales.add(row);
            }
            
            // Override with actual sales data
            while (rs.next()) {
                int hour = rs.getInt("hour");
                BigDecimal total = rs.getBigDecimal("total");
                // Find and update the corresponding hour
                for (Object[] row : hourlySales) {
                    if ((Integer)row[0] == hour) {
                        row[1] = total;
                        break;
                    }
                }
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return hourlySales;
    }
    
    /**
     * Alternative version for PostgreSQL/other databases using EXTRACT
     * Uncomment and use if you're not using MySQL
     */
    /*
    public List<Object[]> getHourlySalesForPeriod(java.sql.Date startDate, java.sql.Date endDate) {
        List<Object[]> hourlySales = new ArrayList<>();
        String sql = "SELECT EXTRACT(HOUR FROM sale_date) as hour, COALESCE(SUM(final_amount), 0) as total " +
                     "FROM sales WHERE DATE(sale_date) BETWEEN ? AND ? " +
                     "GROUP BY EXTRACT(HOUR FROM sale_date) " +
                     "ORDER BY hour ASC";
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setDate(1, startDate);
            pstmt.setDate(2, endDate);
            ResultSet rs = pstmt.executeQuery();
            for (int hour = 0; hour <= 23; hour++) {
                Object[] row = new Object[2];
                row[0] = hour;
                row[1] = BigDecimal.ZERO;
                hourlySales.add(row);
            }
            while (rs.next()) {
                int hour = rs.getInt("hour");
                BigDecimal total = rs.getBigDecimal("total");
                for (Object[] row : hourlySales) {
                    if ((Integer)row[0] == hour) {
                        row[1] = total;
                        break;
                    }
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return hourlySales;
    }
    */
    
    /**
     * Get sales by category for a date range
     * 
     * @param startDate Start date for the query
     * @param endDate End date for the query
     * @return List of Object[] where each array contains [category_name, total_sales]
     */
    public List<Object[]> getSalesByCategoryForPeriod(java.sql.Date startDate, java.sql.Date endDate) {
        List<Object[]> categorySales = new ArrayList<>();
        String sql = "SELECT c.category_name, COALESCE(SUM(si.total_price), 0) as total " +
                     "FROM sales s " +
                     "JOIN sales_items si ON s.sale_id = si.sale_id " +
                     "JOIN products p ON si.product_id = p.product_id " +
                     "JOIN categories c ON p.category_id = c.category_id " +
                     "WHERE DATE(s.sale_date) BETWEEN ? AND ? " +
                     "GROUP BY c.category_id, c.category_name " +
                     "ORDER BY total DESC";
        
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setDate(1, startDate);
            pstmt.setDate(2, endDate);
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                Object[] row = new Object[2];
                row[0] = rs.getString("category_name");
                row[1] = rs.getBigDecimal("total");
                categorySales.add(row);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return categorySales;
    }
    
    /**
     * Get top selling products for a date range
     * 
     * @param startDate Start date for the query
     * @param endDate End date for the query
     * @param limit Maximum number of products to return
     * @return List of Object[] where each array contains [product_name, total_sales, quantity_sold]
     */
    public List<Object[]> getTopSellingProducts(java.sql.Date startDate, java.sql.Date endDate, int limit) {
        List<Object[]> topProducts = new ArrayList<>();
        String sql = "SELECT p.product_name, COALESCE(SUM(si.total_price), 0) as total_sales, COALESCE(SUM(si.quantity), 0) as total_quantity " +
                     "FROM sales s " +
                     "JOIN sales_items si ON s.sale_id = si.sale_id " +
                     "JOIN products p ON si.product_id = p.product_id " +
                     "WHERE DATE(s.sale_date) BETWEEN ? AND ? " +
                     "GROUP BY p.product_id, p.product_name " +
                     "ORDER BY total_sales DESC LIMIT ?";
        
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setDate(1, startDate);
            pstmt.setDate(2, endDate);
            pstmt.setInt(3, limit);
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                Object[] row = new Object[3];
                row[0] = rs.getString("product_name");
                row[1] = rs.getBigDecimal("total_sales");
                row[2] = rs.getInt("total_quantity");
                topProducts.add(row);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return topProducts;
    }
    
    /**
     * Get total cost for sales in a date range
     * 
     * @param startDate Start date for the query
     * @param endDate End date for the query
     * @return Total cost of goods sold
     */
    public BigDecimal getTotalCostByDateRange(java.sql.Date startDate, java.sql.Date endDate) {
        String sql = "SELECT COALESCE(SUM(p.cost_price * si.quantity), 0) as total_cost " +
                     "FROM sales s " +
                     "JOIN sales_items si ON s.sale_id = si.sale_id " +
                     "JOIN products p ON si.product_id = p.product_id " +
                     "WHERE DATE(s.sale_date) BETWEEN ? AND ?";
        
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setDate(1, startDate);
            pstmt.setDate(2, endDate);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return rs.getBigDecimal("total_cost");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return BigDecimal.ZERO;
    }
    
    /**
     * Get transaction count for a date range
     * 
     * @param startDate Start date for the query
     * @param endDate End date for the query
     * @return Number of transactions in the date range
     */
    public int getTransactionCountByDateRange(java.sql.Date startDate, java.sql.Date endDate) {
        String sql = "SELECT COUNT(*) as count FROM sales WHERE DATE(sale_date) BETWEEN ? AND ?";
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setDate(1, startDate);
            pstmt.setDate(2, endDate);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return rs.getInt("count");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }
    
    /**
     * Get sales by cashier for a date range
     * 
     * @param startDate Start date for the query
     * @param endDate End date for the query
     * @return List of Object[] where each array contains [cashier_name, total_sales, transaction_count]
     */
    public List<Object[]> getSalesByCashierForPeriod(java.sql.Date startDate, java.sql.Date endDate) {
        List<Object[]> cashierSales = new ArrayList<>();
        String sql = "SELECT u.full_name, COALESCE(SUM(s.final_amount), 0) as total_sales, COUNT(s.sale_id) as transaction_count " +
                     "FROM sales s " +
                     "JOIN users u ON s.user_id = u.user_id " +
                     "WHERE DATE(s.sale_date) BETWEEN ? AND ? " +
                     "GROUP BY u.user_id, u.full_name " +
                     "ORDER BY total_sales DESC";
        
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setDate(1, startDate);
            pstmt.setDate(2, endDate);
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                Object[] row = new Object[3];
                row[0] = rs.getString("full_name");
                row[1] = rs.getBigDecimal("total_sales");
                row[2] = rs.getInt("transaction_count");
                cashierSales.add(row);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return cashierSales;
    }
    
    // ==================== METHODS FOR CASHIER ====================
    
    public int getTodayTransactionCount() {
        String sql = "SELECT COUNT(*) FROM sales WHERE DATE(sale_date) = CURDATE()";
        try (Connection conn = DatabaseUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }
    
    public int getWeekTransactionCount() {
        String sql = "SELECT COUNT(*) FROM sales WHERE DATE(sale_date) >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)";
        try (Connection conn = DatabaseUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }
    
    public List<Sale> getSalesByCashier(int userId, int limit) {
        List<Sale> sales = new ArrayList<>();
        String sql = "SELECT s.*, u.username as user_name FROM sales s " +
                    "JOIN users u ON s.user_id = u.user_id " +
                    "WHERE s.user_id = ? " +
                    "ORDER BY s.sale_date DESC LIMIT ?";
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, userId);
            pstmt.setInt(2, limit);
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                Sale sale = new Sale();
                sale.setSaleId(rs.getInt("sale_id"));
                sale.setInvoiceNumber(rs.getString("invoice_number"));
                sale.setFinalAmount(rs.getBigDecimal("final_amount"));
                sale.setPaymentMethod(rs.getString("payment_method"));
                sale.setSaleDate(rs.getTimestamp("sale_date"));
                sale.setUserName(rs.getString("user_name"));
                sale.setItemCount(getItemCount(sale.getSaleId()));
                sales.add(sale);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return sales;
    }
    
    public int getItemCount(int saleId) {
        String sql = "SELECT COUNT(*) FROM sales_items WHERE sale_id = ?";
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, saleId);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }
    
    public List<Sale> getSalesByCashierAndDateRange(int userId, java.sql.Date startDate, java.sql.Date endDate) {
        List<Sale> sales = new ArrayList<>();
        String sql = "SELECT s.*, u.username as user_name FROM sales s " +
                    "JOIN users u ON s.user_id = u.user_id " +
                    "WHERE s.user_id = ? AND DATE(s.sale_date) BETWEEN ? AND ? " +
                    "ORDER BY s.sale_date DESC";
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, userId);
            pstmt.setDate(2, startDate);
            pstmt.setDate(3, endDate);
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                Sale sale = new Sale();
                sale.setSaleId(rs.getInt("sale_id"));
                sale.setInvoiceNumber(rs.getString("invoice_number"));
                sale.setTotalAmount(rs.getBigDecimal("total_amount"));
                sale.setTax(rs.getBigDecimal("tax"));
                sale.setFinalAmount(rs.getBigDecimal("final_amount"));
                sale.setPaymentMethod(rs.getString("payment_method"));
                sale.setSaleDate(rs.getTimestamp("sale_date"));
                sale.setUserName(rs.getString("user_name"));
                sale.setItemCount(getItemCount(sale.getSaleId()));
                sales.add(sale);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return sales;
    }
}