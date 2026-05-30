// src/java/mpeoa/models/Sale.java
package mpeoa.models;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

public class Sale {
    private int saleId;
    private String invoiceNumber;
    private int userId;
    private String userName;
    private BigDecimal totalAmount;
    private BigDecimal discount;
    private BigDecimal tax;
    private BigDecimal finalAmount;
    private String paymentMethod;
    private Timestamp saleDate;
    private int itemCount;  // NEW: Number of items in the sale
    private List<SaleItem> items;
    
    public Sale() {
        this.discount = BigDecimal.ZERO;
        this.tax = BigDecimal.ZERO;
        this.totalAmount = BigDecimal.ZERO;
        this.finalAmount = BigDecimal.ZERO;
        this.itemCount = 0;
        this.items = new ArrayList<>();
    }
    
    public Sale(String invoiceNumber, int userId, String paymentMethod) {
        this.invoiceNumber = invoiceNumber;
        this.userId = userId;
        this.paymentMethod = paymentMethod;
        this.discount = BigDecimal.ZERO;
        this.tax = BigDecimal.ZERO;
        this.totalAmount = BigDecimal.ZERO;
        this.finalAmount = BigDecimal.ZERO;
        this.itemCount = 0;
        this.items = new ArrayList<>();
    }
    
    // Getters and Setters
    public int getSaleId() {
        return saleId;
    }
    
    public void setSaleId(int saleId) {
        this.saleId = saleId;
    }
    
    public String getInvoiceNumber() {
        return invoiceNumber;
    }
    
    public void setInvoiceNumber(String invoiceNumber) {
        this.invoiceNumber = invoiceNumber;
    }
    
    public int getUserId() {
        return userId;
    }
    
    public void setUserId(int userId) {
        this.userId = userId;
    }
    
    public String getUserName() {
        return userName;
    }
    
    public void setUserName(String userName) {
        this.userName = userName;
    }
    
    public BigDecimal getTotalAmount() {
        return totalAmount;
    }
    
    public void setTotalAmount(BigDecimal totalAmount) {
        this.totalAmount = totalAmount;
    }
    
    public BigDecimal getDiscount() {
        return discount;
    }
    
    public void setDiscount(BigDecimal discount) {
        this.discount = discount;
    }
    
    public BigDecimal getTax() {
        return tax;
    }
    
    public void setTax(BigDecimal tax) {
        this.tax = tax;
    }
    
    public BigDecimal getFinalAmount() {
        return finalAmount;
    }
    
    public void setFinalAmount(BigDecimal finalAmount) {
        this.finalAmount = finalAmount;
    }
    
    public String getPaymentMethod() {
        return paymentMethod;
    }
    
    public void setPaymentMethod(String paymentMethod) {
        this.paymentMethod = paymentMethod;
    }
    
    public Timestamp getSaleDate() {
        return saleDate;
    }
    
    public void setSaleDate(Timestamp saleDate) {
        this.saleDate = saleDate;
    }
    
    public int getItemCount() {
        return itemCount;
    }
    
    public void setItemCount(int itemCount) {
        this.itemCount = itemCount;
    }
    
    public List<SaleItem> getItems() {
        return items;
    }
    
    public void setItems(List<SaleItem> items) {
        this.items = items;
        this.itemCount = items.size();
        // Recalculate total amount from items
        BigDecimal newTotal = BigDecimal.ZERO;
        for (SaleItem item : items) {
            newTotal = newTotal.add(item.getTotalPrice());
        }
        this.totalAmount = newTotal;
        recalculateFinalAmount();
    }
    
    public void addItem(SaleItem item) {
        this.items.add(item);
        this.itemCount = this.items.size();
        this.totalAmount = this.totalAmount.add(item.getTotalPrice());
        recalculateFinalAmount();
    }
    
    public void recalculateFinalAmount() {
        BigDecimal afterDiscount = this.totalAmount.subtract(this.discount);
        this.finalAmount = afterDiscount.add(this.tax);
    }
    
    @Override
    public String toString() {
        return "Sale{" +
                "saleId=" + saleId +
                ", invoiceNumber='" + invoiceNumber + '\'' +
                ", finalAmount=" + finalAmount +
                ", paymentMethod='" + paymentMethod + '\'' +
                ", saleDate=" + saleDate +
                ", itemCount=" + itemCount +
                '}';
    }
}