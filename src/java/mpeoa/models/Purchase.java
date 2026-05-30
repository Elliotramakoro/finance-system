// src/java/mpeoa/models/Purchase.java
package mpeoa.models;

import java.math.BigDecimal;
import java.sql.Date;
import java.sql.Timestamp;

public class Purchase {
    private int purchaseId;
    private String purchaseOrderNumber;
    private int supplierId;
    private String supplierName;
    private BigDecimal totalAmount;
    private Date purchaseDate;
    private String paymentStatus;
    private String deliveredBy;
    private int receivedBy;
    private String receivedByName;
    private Timestamp createdAt;
    
    public Purchase() {
        this.paymentStatus = "Pending";
    }
    
    public Purchase(int supplierId, BigDecimal totalAmount, Date purchaseDate) {
        this.supplierId = supplierId;
        this.totalAmount = totalAmount;
        this.purchaseDate = purchaseDate;
        this.paymentStatus = "Pending";
    }
    
    // Getters and Setters
    public int getPurchaseId() {
        return purchaseId;
    }
    
    public void setPurchaseId(int purchaseId) {
        this.purchaseId = purchaseId;
    }
    
    public String getPurchaseOrderNumber() {
        return purchaseOrderNumber;
    }
    
    public void setPurchaseOrderNumber(String purchaseOrderNumber) {
        this.purchaseOrderNumber = purchaseOrderNumber;
    }
    
    public int getSupplierId() {
        return supplierId;
    }
    
    public void setSupplierId(int supplierId) {
        this.supplierId = supplierId;
    }
    
    public String getSupplierName() {
        return supplierName;
    }
    
    public void setSupplierName(String supplierName) {
        this.supplierName = supplierName;
    }
    
    public BigDecimal getTotalAmount() {
        return totalAmount;
    }
    
    public void setTotalAmount(BigDecimal totalAmount) {
        this.totalAmount = totalAmount;
    }
    
    public Date getPurchaseDate() {
        return purchaseDate;
    }
    
    public void setPurchaseDate(Date purchaseDate) {
        this.purchaseDate = purchaseDate;
    }
    
    public String getPaymentStatus() {
        return paymentStatus;
    }
    
    public void setPaymentStatus(String paymentStatus) {
        this.paymentStatus = paymentStatus;
    }
    
    public String getDeliveredBy() {
        return deliveredBy;
    }
    
    public void setDeliveredBy(String deliveredBy) {
        this.deliveredBy = deliveredBy;
    }
    
    public int getReceivedBy() {
        return receivedBy;
    }
    
    public void setReceivedBy(int receivedBy) {
        this.receivedBy = receivedBy;
    }
    
    public String getReceivedByName() {
        return receivedByName;
    }
    
    public void setReceivedByName(String receivedByName) {
        this.receivedByName = receivedByName;
    }
    
    public Timestamp getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
    
    public boolean isPaid() {
        return "Paid".equalsIgnoreCase(paymentStatus);
    }
    
    public boolean isPending() {
        return "Pending".equalsIgnoreCase(paymentStatus);
    }
    
    @Override
    public String toString() {
        return "Purchase{" +
                "purchaseId=" + purchaseId +
                ", purchaseOrderNumber='" + purchaseOrderNumber + '\'' +
                ", supplierName='" + supplierName + '\'' +
                ", totalAmount=" + totalAmount +
                ", paymentStatus='" + paymentStatus + '\'' +
                '}';
    }
}