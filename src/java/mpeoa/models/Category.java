// src/java/mpeoa/models/Category.java
package mpeoa.models;

import java.sql.Timestamp;

public class Category {
    private int categoryId;
    private String categoryName;
    private String description;
    private Timestamp createdAt;
    private int productCount;  // New field for product count
    
    public Category() {
        this.productCount = 0;
    }
    
    public Category(String categoryName, String description) {
        this.categoryName = categoryName;
        this.description = description;
        this.productCount = 0;
    }
    
    // Getters and Setters
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
    
    public String getDescription() {
        return description;
    }
    
    public void setDescription(String description) {
        this.description = description;
    }
    
    public Timestamp getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
    
    public int getProductCount() {
        return productCount;
    }
    
    public void setProductCount(int productCount) {
        this.productCount = productCount;
    }
    
    @Override
    public String toString() {
        return "Category{" +
                "categoryId=" + categoryId +
                ", categoryName='" + categoryName + '\'' +
                ", productCount=" + productCount +
                '}';
    }
}