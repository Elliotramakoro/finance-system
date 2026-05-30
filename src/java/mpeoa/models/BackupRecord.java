// src/java/mpeoa/models/BackupRecord.java
package mpeoa.models;

import java.sql.Timestamp;

public class BackupRecord {
    private int backupId;
    private String backupName;
    private String backupFile;
    private String backupSize;
    private Timestamp backupDate;
    private String backupType;
    private String backupStatus;
    private int createdBy;
    private String createdByName;
    private Timestamp createdAt;
    
    public BackupRecord() {}
    
    // Getters and Setters
    public int getBackupId() {
        return backupId;
    }
    
    public void setBackupId(int backupId) {
        this.backupId = backupId;
    }
    
    public String getBackupName() {
        return backupName;
    }
    
    public void setBackupName(String backupName) {
        this.backupName = backupName;
    }
    
    public String getBackupFile() {
        return backupFile;
    }
    
    public void setBackupFile(String backupFile) {
        this.backupFile = backupFile;
    }
    
    public String getBackupSize() {
        return backupSize;
    }
    
    public void setBackupSize(String backupSize) {
        this.backupSize = backupSize;
    }
    
    public Timestamp getBackupDate() {
        return backupDate;
    }
    
    public void setBackupDate(Timestamp backupDate) {
        this.backupDate = backupDate;
    }
    
    public String getBackupType() {
        return backupType;
    }
    
    public void setBackupType(String backupType) {
        this.backupType = backupType;
    }
    
    public String getBackupStatus() {
        return backupStatus;
    }
    
    public void setBackupStatus(String backupStatus) {
        this.backupStatus = backupStatus;
    }
    
    public int getCreatedBy() {
        return createdBy;
    }
    
    public void setCreatedBy(int createdBy) {
        this.createdBy = createdBy;
    }
    
    public String getCreatedByName() {
        return createdByName;
    }
    
    public void setCreatedByName(String createdByName) {
        this.createdByName = createdByName;
    }
    
    public Timestamp getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
}