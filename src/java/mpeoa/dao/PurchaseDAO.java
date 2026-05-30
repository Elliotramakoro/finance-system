// src/java/mpeoa/dao/PurchaseDAO.java
package mpeoa.dao;

import mpeoa.models.Purchase;
import mpeoa.utils.DatabaseUtil;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class PurchaseDAO {
    
    public List<Purchase> getAllPurchases() {
        List<Purchase> purchases = new ArrayList<>();
        String sql = "SELECT p.*, s.supplier_name, u.username as received_by_name " +
                    "FROM purchases p " +
                    "LEFT JOIN suppliers s ON p.supplier_id = s.supplier_id " +
                    "LEFT JOIN users u ON p.received_by = u.user_id " +
                    "ORDER BY p.purchase_date DESC";
        
        try (Connection conn = DatabaseUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            
            while (rs.next()) {
                Purchase purchase = new Purchase();
                purchase.setPurchaseId(rs.getInt("purchase_id"));
                purchase.setPurchaseOrderNumber(rs.getString("purchase_order_number"));
                purchase.setSupplierId(rs.getInt("supplier_id"));
                purchase.setSupplierName(rs.getString("supplier_name"));
                purchase.setTotalAmount(rs.getBigDecimal("total_amount"));
                purchase.setPurchaseDate(rs.getDate("purchase_date"));
                purchase.setPaymentStatus(rs.getString("payment_status"));
                purchase.setDeliveredBy(rs.getString("delivered_by"));
                purchase.setReceivedBy(rs.getInt("received_by"));
                purchase.setReceivedByName(rs.getString("received_by_name"));
                purchase.setCreatedAt(rs.getTimestamp("created_at"));
                purchases.add(purchase);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return purchases;
    }
    
    public Purchase getPurchaseById(int purchaseId) {
        String sql = "SELECT p.*, s.supplier_name, u.username as received_by_name " +
                    "FROM purchases p " +
                    "LEFT JOIN suppliers s ON p.supplier_id = s.supplier_id " +
                    "LEFT JOIN users u ON p.received_by = u.user_id " +
                    "WHERE p.purchase_id = ?";
        
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, purchaseId);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                Purchase purchase = new Purchase();
                purchase.setPurchaseId(rs.getInt("purchase_id"));
                purchase.setPurchaseOrderNumber(rs.getString("purchase_order_number"));
                purchase.setSupplierId(rs.getInt("supplier_id"));
                purchase.setSupplierName(rs.getString("supplier_name"));
                purchase.setTotalAmount(rs.getBigDecimal("total_amount"));
                purchase.setPurchaseDate(rs.getDate("purchase_date"));
                purchase.setPaymentStatus(rs.getString("payment_status"));
                purchase.setDeliveredBy(rs.getString("delivered_by"));
                purchase.setReceivedBy(rs.getInt("received_by"));
                purchase.setReceivedByName(rs.getString("received_by_name"));
                purchase.setCreatedAt(rs.getTimestamp("created_at"));
                return purchase;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
    
    public int getPurchaseCount() {
        String sql = "SELECT COUNT(*) FROM purchases";
        try (Connection conn = DatabaseUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }
    
    public boolean createPurchase(Purchase purchase) {
        String sql = "INSERT INTO purchases (purchase_order_number, supplier_id, total_amount, purchase_date, payment_status, delivered_by, received_by) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?)";
        
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            
            // Generate purchase order number if not set
            if (purchase.getPurchaseOrderNumber() == null || purchase.getPurchaseOrderNumber().isEmpty()) {
                String poNumber = generatePONumber();
                purchase.setPurchaseOrderNumber(poNumber);
            }
            
            pstmt.setString(1, purchase.getPurchaseOrderNumber());
            pstmt.setInt(2, purchase.getSupplierId());
            pstmt.setBigDecimal(3, purchase.getTotalAmount());
            pstmt.setDate(4, purchase.getPurchaseDate());
            pstmt.setString(5, purchase.getPaymentStatus());
            pstmt.setString(6, purchase.getDeliveredBy());
            pstmt.setInt(7, purchase.getReceivedBy());
            
            int affectedRows = pstmt.executeUpdate();
            
            if (affectedRows > 0) {
                ResultSet rs = pstmt.getGeneratedKeys();
                if (rs.next()) {
                    purchase.setPurchaseId(rs.getInt(1));
                }
                return true;
            }
            return false;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    public boolean updatePurchase(Purchase purchase) {
        String sql = "UPDATE purchases SET supplier_id = ?, total_amount = ?, purchase_date = ?, " +
                    "payment_status = ?, delivered_by = ?, received_by = ? WHERE purchase_id = ?";
        
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, purchase.getSupplierId());
            pstmt.setBigDecimal(2, purchase.getTotalAmount());
            pstmt.setDate(3, purchase.getPurchaseDate());
            pstmt.setString(4, purchase.getPaymentStatus());
            pstmt.setString(5, purchase.getDeliveredBy());
            pstmt.setInt(6, purchase.getReceivedBy());
            pstmt.setInt(7, purchase.getPurchaseId());
            
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    public boolean updatePaymentStatus(int purchaseId, String status) {
        String sql = "UPDATE purchases SET payment_status = ? WHERE purchase_id = ?";
        
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, status);
            pstmt.setInt(2, purchaseId);
            
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    public boolean markAsPaid(int purchaseId) {
        return updatePaymentStatus(purchaseId, "Paid");
    }
    
    public boolean deletePurchase(int purchaseId) {
        String sql = "DELETE FROM purchases WHERE purchase_id = ?";
        
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, purchaseId);
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    public List<Purchase> getPendingPurchases() {
        List<Purchase> purchases = new ArrayList<>();
        String sql = "SELECT p.*, s.supplier_name FROM purchases p " +
                     "LEFT JOIN suppliers s ON p.supplier_id = s.supplier_id " +
                     "WHERE p.payment_status = 'Pending' ORDER BY p.purchase_date ASC";
        try (Connection conn = DatabaseUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                Purchase purchase = new Purchase();
                purchase.setPurchaseId(rs.getInt("purchase_id"));
                purchase.setPurchaseOrderNumber(rs.getString("purchase_order_number"));
                purchase.setSupplierName(rs.getString("supplier_name"));
                purchase.setTotalAmount(rs.getBigDecimal("total_amount"));
                purchase.setPurchaseDate(rs.getDate("purchase_date"));
                purchase.setPaymentStatus(rs.getString("payment_status"));
                purchases.add(purchase);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return purchases;
    }
    
    public List<Purchase> getRecentPurchases(int limit) {
        List<Purchase> purchases = new ArrayList<>();
        String sql = "SELECT p.*, s.supplier_name FROM purchases p " +
                     "LEFT JOIN suppliers s ON p.supplier_id = s.supplier_id " +
                     "ORDER BY p.purchase_date DESC LIMIT ?";
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, limit);
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                Purchase purchase = new Purchase();
                purchase.setPurchaseId(rs.getInt("purchase_id"));
                purchase.setPurchaseOrderNumber(rs.getString("purchase_order_number"));
                purchase.setSupplierName(rs.getString("supplier_name"));
                purchase.setTotalAmount(rs.getBigDecimal("total_amount"));
                purchase.setPurchaseDate(rs.getDate("purchase_date"));
                purchase.setPaymentStatus(rs.getString("payment_status"));
                purchases.add(purchase);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return purchases;
    }
    
    private String generatePONumber() {
        String sql = "SELECT COUNT(*) FROM purchases";
        try (Connection conn = DatabaseUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            if (rs.next()) {
                int count = rs.getInt(1) + 1;
                return "PO-" + System.currentTimeMillis() + "-" + count;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return "PO-" + System.currentTimeMillis();
    }
}