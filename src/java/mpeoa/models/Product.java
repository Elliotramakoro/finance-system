// src/java/mpeoa/models/Product.java
package mpeoa.models;

import java.math.BigDecimal;
import java.sql.Timestamp;

public class Product {
    private int productId;
    private String productCode;
    private String productName;
    private int categoryId;
    private String categoryName;
    private BigDecimal unitPrice;
    private BigDecimal costPrice;
    private String description;
    private int stockQuantity;
    private int reorderLevel;
    private Timestamp createdAt;
    
    public Product() {
        this.stockQuantity = 0;
        this.reorderLevel = 10;
    }
    
    public Product(String productCode, String productName, int categoryId, BigDecimal unitPrice, BigDecimal costPrice) {
        this.productCode = productCode;
        this.productName = productName;
        this.categoryId = categoryId;
        this.unitPrice = unitPrice;
        this.costPrice = costPrice;
        this.stockQuantity = 0;
        this.reorderLevel = 10;
    }
    
    // Getters and Setters
    public int getProductId() {
        return productId;
    }
    
    public void setProductId(int productId) {
        this.productId = productId;
    }
    
    public String getProductCode() {
        return productCode;
    }
    
    public void setProductCode(String productCode) {
        this.productCode = productCode;
    }
    
    public String getProductName() {
        return productName;
    }
    
    public void setProductName(String productName) {
        this.productName = productName;
    }
    
    public int getCategoryId() {
        return categoryId;
    }
    
    public void setCategoryId(int categoryId) {
        this.categoryId = categoryId;
    }
    
    public String getCategoryName() {
        return categoryName;
    }
    
    public void setCategoryName(String categoryName) {
        this.categoryName = categoryName;
    }
    
    public BigDecimal getUnitPrice() {
        return unitPrice;
    }
    
    public void setUnitPrice(BigDecimal unitPrice) {
        this.unitPrice = unitPrice;
    }
    
    public BigDecimal getCostPrice() {
        return costPrice;
    }
    
    public void setCostPrice(BigDecimal costPrice) {
        this.costPrice = costPrice;
    }
    
    public String getDescription() {
        return description;
    }
    
    public void setDescription(String description) {
        this.description = description;
    }
    
    public int getStockQuantity() {
        return stockQuantity;
    }
    
    public void setStockQuantity(int stockQuantity) {
        this.stockQuantity = stockQuantity;
    }
    
    public int getReorderLevel() {
        return reorderLevel;
    }
    
    public void setReorderLevel(int reorderLevel) {
        this.reorderLevel = reorderLevel;
    }
    
    public Timestamp getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
    
    public BigDecimal getProfitMargin() {
        if (costPrice != null && unitPrice != null && costPrice.compareTo(BigDecimal.ZERO) > 0) {
            return unitPrice.subtract(costPrice);
        }
        return BigDecimal.ZERO;
    }
    
    @Override
    public String toString() {
        return "Product{" +
                "productId=" + productId +
                ", productCode='" + productCode + '\'' +
                ", productName='" + productName + '\'' +
                ", unitPrice=" + unitPrice +
                ", stockQuantity=" + stockQuantity +
                '}';
    }
}