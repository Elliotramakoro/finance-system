// src/java/mpeoa/dao/ProductDAO.java
package mpeoa.dao;

import mpeoa.models.Product;
import mpeoa.utils.DatabaseUtil;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ProductDAO {
    
    public List<Product> getAllProducts() {
        List<Product> products = new ArrayList<>();
        String sql = "SELECT p.*, c.category_name, COALESCE(i.quantity, 0) as stock, COALESCE(i.reorder_level, 10) as reorder_level " +
                    "FROM products p " +
                    "LEFT JOIN categories c ON p.category_id = c.category_id " +
                    "LEFT JOIN inventory i ON p.product_id = i.product_id " +
                    "ORDER BY p.created_at DESC";
        
        try (Connection conn = DatabaseUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            
            while (rs.next()) {
                Product product = new Product();
                product.setProductId(rs.getInt("product_id"));
                product.setProductCode(rs.getString("product_code"));
                product.setProductName(rs.getString("product_name"));
                product.setCategoryId(rs.getInt("category_id"));
                product.setCategoryName(rs.getString("category_name"));
                product.setUnitPrice(rs.getBigDecimal("unit_price"));
                product.setCostPrice(rs.getBigDecimal("cost_price"));
                product.setDescription(rs.getString("description"));
                product.setStockQuantity(rs.getInt("stock"));
                product.setReorderLevel(rs.getInt("reorder_level"));
                products.add(product);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return products;
    }
    
    public int getProductCount() {
        String sql = "SELECT COUNT(*) FROM products";
        try (Connection conn = DatabaseUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }
    
    public Product getProductById(int productId) {
        String sql = "SELECT p.*, c.category_name, COALESCE(i.quantity, 0) as stock " +
                    "FROM products p " +
                    "LEFT JOIN categories c ON p.category_id = c.category_id " +
                    "LEFT JOIN inventory i ON p.product_id = i.product_id " +
                    "WHERE p.product_id = ?";
        
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, productId);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                Product product = new Product();
                product.setProductId(rs.getInt("product_id"));
                product.setProductCode(rs.getString("product_code"));
                product.setProductName(rs.getString("product_name"));
                product.setCategoryId(rs.getInt("category_id"));
                product.setCategoryName(rs.getString("category_name"));
                product.setUnitPrice(rs.getBigDecimal("unit_price"));
                product.setCostPrice(rs.getBigDecimal("cost_price"));
                product.setDescription(rs.getString("description"));
                product.setStockQuantity(rs.getInt("stock"));
                return product;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
    
    public List<Product> getLowStockProducts() {
        List<Product> products = new ArrayList<>();
        String sql = "SELECT p.*, c.category_name, i.quantity as stock, i.reorder_level " +
                    "FROM products p " +
                    "JOIN categories c ON p.category_id = c.category_id " +
                    "JOIN inventory i ON p.product_id = i.product_id " +
                    "WHERE i.quantity <= i.reorder_level " +
                    "ORDER BY i.quantity ASC";
        
        try (Connection conn = DatabaseUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            
            while (rs.next()) {
                Product product = new Product();
                product.setProductId(rs.getInt("product_id"));
                product.setProductCode(rs.getString("product_code"));
                product.setProductName(rs.getString("product_name"));
                product.setStockQuantity(rs.getInt("stock"));
                product.setReorderLevel(rs.getInt("reorder_level"));
                products.add(product);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return products;
    }
    // Add these methods to ProductDAO.java

public boolean updateProduct(Product product) {
    String sql = "UPDATE products SET product_name = ?, unit_price = ?, cost_price = ?, description = ? WHERE product_id = ?";
    
    try (Connection conn = DatabaseUtil.getConnection();
         PreparedStatement pstmt = conn.prepareStatement(sql)) {
        
        pstmt.setString(1, product.getProductName());
        pstmt.setBigDecimal(2, product.getUnitPrice());
        pstmt.setBigDecimal(3, product.getCostPrice());
        pstmt.setString(4, product.getDescription());
        pstmt.setInt(5, product.getProductId());
        
        return pstmt.executeUpdate() > 0;
    } catch (SQLException e) {
        e.printStackTrace();
        return false;
    }
}

public boolean deleteProduct(int productId) {
    Connection conn = null;
    try {
        conn = DatabaseUtil.getConnection();
        conn.setAutoCommit(false);
        
        // First delete from inventory
        String sqlInventory = "DELETE FROM inventory WHERE product_id = ?";
        PreparedStatement pstmtInventory = conn.prepareStatement(sqlInventory);
        pstmtInventory.setInt(1, productId);
        pstmtInventory.executeUpdate();
        
        // Then delete from sales_items
        String sqlSalesItems = "DELETE FROM sales_items WHERE product_id = ?";
        PreparedStatement pstmtSalesItems = conn.prepareStatement(sqlSalesItems);
        pstmtSalesItems.setInt(1, productId);
        pstmtSalesItems.executeUpdate();
        
        // Finally delete the product
        String sqlProduct = "DELETE FROM products WHERE product_id = ?";
        PreparedStatement pstmtProduct = conn.prepareStatement(sqlProduct);
        pstmtProduct.setInt(1, productId);
        int result = pstmtProduct.executeUpdate();
        
        conn.commit();
        return result > 0;
        
    } catch (SQLException e) {
        if (conn != null) {
            try {
                conn.rollback();
            } catch (SQLException ex) {
                ex.printStackTrace();
            }
        }
        e.printStackTrace();
        return false;
    } finally {
        if (conn != null) {
            try {
                conn.setAutoCommit(true);
                conn.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }
}
    public boolean updateStock(int productId, int quantity, boolean isAdd) {
        String sql = "UPDATE inventory SET quantity = quantity " + (isAdd ? "+" : "-") + " ?, last_updated = CURRENT_TIMESTAMP WHERE product_id = ?";
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, quantity);
            pstmt.setInt(2, productId);
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    public boolean createProduct(Product product) {
        Connection conn = null;
        try {
            conn = DatabaseUtil.getConnection();
            conn.setAutoCommit(false);
            
            String sqlProduct = "INSERT INTO products (product_code, product_name, category_id, unit_price, cost_price, description) VALUES (?, ?, ?, ?, ?, ?)";
            PreparedStatement pstmtProduct = conn.prepareStatement(sqlProduct, Statement.RETURN_GENERATED_KEYS);
            pstmtProduct.setString(1, product.getProductCode());
            pstmtProduct.setString(2, product.getProductName());
            pstmtProduct.setInt(3, product.getCategoryId());
            pstmtProduct.setBigDecimal(4, product.getUnitPrice());
            pstmtProduct.setBigDecimal(5, product.getCostPrice());
            pstmtProduct.setString(6, product.getDescription());
            
            int affectedRows = pstmtProduct.executeUpdate();
            
            if (affectedRows > 0) {
                ResultSet generatedKeys = pstmtProduct.getGeneratedKeys();
                if (generatedKeys.next()) {
                    int productId = generatedKeys.getInt(1);
                    
                    String sqlInventory = "INSERT INTO inventory (product_id, quantity, reorder_level) VALUES (?, ?, ?)";
                    PreparedStatement pstmtInventory = conn.prepareStatement(sqlInventory);
                    pstmtInventory.setInt(1, productId);
                    pstmtInventory.setInt(2, product.getStockQuantity());
                    pstmtInventory.setInt(3, product.getReorderLevel());
                    pstmtInventory.executeUpdate();
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
    public List<Product> getTopStockValueProducts(int limit) {
    List<Product> products = new ArrayList<>();
    String sql = "SELECT p.*, c.category_name, i.quantity as stock, i.reorder_level, " +
                 "(p.cost_price * i.quantity) as stock_value " +
                 "FROM products p " +
                 "LEFT JOIN categories c ON p.category_id = c.category_id " +
                 "JOIN inventory i ON p.product_id = i.product_id " +
                 "ORDER BY stock_value DESC LIMIT ?";
    try (Connection conn = DatabaseUtil.getConnection();
         PreparedStatement pstmt = conn.prepareStatement(sql)) {
        pstmt.setInt(1, limit);
        ResultSet rs = pstmt.executeQuery();
        while (rs.next()) {
            Product product = new Product();
            product.setProductId(rs.getInt("product_id"));
            product.setProductCode(rs.getString("product_code"));
            product.setProductName(rs.getString("product_name"));
            product.setCategoryName(rs.getString("category_name"));
            product.setUnitPrice(rs.getBigDecimal("unit_price"));
            product.setCostPrice(rs.getBigDecimal("cost_price"));
            product.setStockQuantity(rs.getInt("stock"));
            product.setReorderLevel(rs.getInt("reorder_level"));
            products.add(product);
        }
    } catch (SQLException e) {
        e.printStackTrace();
    }
    return products;
}
    // ==================== METHOD FOR ANALYTICS ====================
    
    public List<Product> getTopSellingProducts(int limit) {
        List<Product> products = new ArrayList<>();
        String sql = "SELECT p.product_id, p.product_name, p.product_code, p.unit_price, " +
                     "COALESCE(SUM(si.quantity), 0) as total_sold " +
                     "FROM products p " +
                     "LEFT JOIN sales_items si ON p.product_id = si.product_id " +
                     "LEFT JOIN sales s ON si.sale_id = s.sale_id " +
                     "GROUP BY p.product_id, p.product_name, p.product_code, p.unit_price " +
                     "ORDER BY total_sold DESC LIMIT ?";
        
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, limit);
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                Product product = new Product();
                product.setProductId(rs.getInt("product_id"));
                product.setProductName(rs.getString("product_name"));
                product.setProductCode(rs.getString("product_code"));
                product.setUnitPrice(rs.getBigDecimal("unit_price"));
                product.setStockQuantity(rs.getInt("total_sold"));
                products.add(product);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return products;
    }
}