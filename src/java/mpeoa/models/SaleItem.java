// src/java/mpeoa/models/SaleItem.java
package mpeoa.models;

import java.math.BigDecimal;

public class SaleItem {
    private int saleItemId;
    private int saleId;
    private int productId;
    private String productName;
    private String productCode;
    private int quantity;
    private BigDecimal unitPrice;
    private BigDecimal totalPrice;
    
    public SaleItem() {
        this.quantity = 0;
        this.unitPrice = BigDecimal.ZERO;
        this.totalPrice = BigDecimal.ZERO;
    }
    
    public SaleItem(int productId, int quantity, BigDecimal unitPrice) {
        this.productId = productId;
        this.quantity = quantity;
        this.unitPrice = unitPrice;
        this.totalPrice = unitPrice.multiply(new BigDecimal(quantity));
    }
    
    // Getters and Setters
    public int getSaleItemId() {
        return saleItemId;
    }
    
    public void setSaleItemId(int saleItemId) {
        this.saleItemId = saleItemId;
    }
    
    public int getSaleId() {
        return saleId;
    }
    
    public void setSaleId(int saleId) {
        this.saleId = saleId;
    }
    
    public int getProductId() {
        return productId;
    }
    
    public void setProductId(int productId) {
        this.productId = productId;
    }
    
    public String getProductName() {
        return productName;
    }
    
    public void setProductName(String productName) {
        this.productName = productName;
    }
    
    public String getProductCode() {
        return productCode;
    }
    
    public void setProductCode(String productCode) {
        this.productCode = productCode;
    }
    
    public int getQuantity() {
        return quantity;
    }
    
    public void setQuantity(int quantity) {
        this.quantity = quantity;
        if (this.unitPrice != null) {
            this.totalPrice = this.unitPrice.multiply(new BigDecimal(quantity));
        }
    }
    
    public BigDecimal getUnitPrice() {
        return unitPrice;
    }
    
    public void setUnitPrice(BigDecimal unitPrice) {
        this.unitPrice = unitPrice;
        if (this.unitPrice != null) {
            this.totalPrice = this.unitPrice.multiply(new BigDecimal(this.quantity));
        }
    }
    
    public BigDecimal getTotalPrice() {
        return totalPrice;
    }
    
    public void setTotalPrice(BigDecimal totalPrice) {
        this.totalPrice = totalPrice;
    }
    
    @Override
    public String toString() {
        return "SaleItem{" +
                "productId=" + productId +
                ", productName='" + productName + '\'' +
                ", quantity=" + quantity +
                ", unitPrice=" + unitPrice +
                ", totalPrice=" + totalPrice +
                '}';
    }
}