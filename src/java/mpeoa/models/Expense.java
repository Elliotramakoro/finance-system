// src/java/mpeoa/models/Expense.java
package mpeoa.models;

import java.math.BigDecimal;
import java.sql.Date;
import java.sql.Timestamp;

public class Expense {
    private int expenseId;
    private String expenseCategory;
    private String description;
    private BigDecimal amount;
    private Date expenseDate;
    private String paymentMethod;
    private String receiptNumber;
    private int approvedBy;
    private String approvedByName;
    private int recordedBy;
    private String recordedByName;
    private String status;
    private Timestamp createdAt;
    
    public Expense() {
        this.status = "Pending";
    }
    
    public Expense(String expenseCategory, String description, BigDecimal amount, Date expenseDate, int recordedBy) {
        this.expenseCategory = expenseCategory;
        this.description = description;
        this.amount = amount;
        this.expenseDate = expenseDate;
        this.recordedBy = recordedBy;
        this.status = "Pending";
    }
    
    // Getters and Setters
    public int getExpenseId() {
        return expenseId;
    }
    
    public void setExpenseId(int expenseId) {
        this.expenseId = expenseId;
    }
    
    public String getExpenseCategory() {
        return expenseCategory;
    }
    
    public void setExpenseCategory(String expenseCategory) {
        this.expenseCategory = expenseCategory;
    }
    
    public String getDescription() {
        return description;
    }
    
    public void setDescription(String description) {
        this.description = description;
    }
    
    public BigDecimal getAmount() {
        return amount;
    }
    
    public void setAmount(BigDecimal amount) {
        this.amount = amount;
    }
    
    public Date getExpenseDate() {
        return expenseDate;
    }
    
    public void setExpenseDate(Date expenseDate) {
        this.expenseDate = expenseDate;
    }
    
    public String getPaymentMethod() {
        return paymentMethod;
    }
    
    public void setPaymentMethod(String paymentMethod) {
        this.paymentMethod = paymentMethod;
    }
    
    public String getReceiptNumber() {
        return receiptNumber;
    }
    
    public void setReceiptNumber(String receiptNumber) {
        this.receiptNumber = receiptNumber;
    }
    
    public int getApprovedBy() {
        return approvedBy;
    }
    
    public void setApprovedBy(int approvedBy) {
        this.approvedBy = approvedBy;
    }
    
    public String getApprovedByName() {
        return approvedByName;
    }
    
    public void setApprovedByName(String approvedByName) {
        this.approvedByName = approvedByName;
    }
    
    public int getRecordedBy() {
        return recordedBy;
    }
    
    public void setRecordedBy(int recordedBy) {
        this.recordedBy = recordedBy;
    }
    
    public String getRecordedByName() {
        return recordedByName;
    }
    
    public void setRecordedByName(String recordedByName) {
        this.recordedByName = recordedByName;
    }
    
    public String getStatus() {
        return status;
    }
    
    public void setStatus(String status) {
        this.status = status;
    }
    
    public Timestamp getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
    
    public boolean isApproved() {
        return "Approved".equalsIgnoreCase(status);
    }
    
    public boolean isPending() {
        return "Pending".equalsIgnoreCase(status);
    }
    
    @Override
    public String toString() {
        return "Expense{" +
                "expenseId=" + expenseId +
                ", expenseCategory='" + expenseCategory + '\'' +
                ", amount=" + amount +
                ", status='" + status + '\'' +
                '}';
    }
}