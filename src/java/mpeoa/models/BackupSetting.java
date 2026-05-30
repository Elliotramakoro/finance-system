// src/java/mpeoa/models/BackupSetting.java
package mpeoa.models;

import java.sql.Time;
import java.sql.Timestamp;

public class BackupSetting {
    private int settingId;
    private String backupFrequency;
    private Time backupTime;
    private int retentionDays;
    private String backupLocation;
    private boolean encryptBackup;
    private boolean autoBackup;
    private Timestamp lastBackup;
    private Timestamp updatedAt;
    
    public BackupSetting() {}
    
    // Getters and Setters
    public int getSettingId() {
        return settingId;
    }
    
    public void setSettingId(int settingId) {
        this.settingId = settingId;
    }
    
    public String getBackupFrequency() {
        return backupFrequency;
    }
    
    public void setBackupFrequency(String backupFrequency) {
        this.backupFrequency = backupFrequency;
    }
    
    public Time getBackupTime() {
        return backupTime;
    }
    
    public void setBackupTime(Time backupTime) {
        this.backupTime = backupTime;
    }
    
    public int getRetentionDays() {
        return retentionDays;
    }
    
    public void setRetentionDays(int retentionDays) {
        this.retentionDays = retentionDays;
    }
    
    public String getBackupLocation() {
        return backupLocation;
    }
    
    public void setBackupLocation(String backupLocation) {
        this.backupLocation = backupLocation;
    }
    
    public boolean isEncryptBackup() {
        return encryptBackup;
    }
    
    public void setEncryptBackup(boolean encryptBackup) {
        this.encryptBackup = encryptBackup;
    }
    
    public boolean isAutoBackup() {
        return autoBackup;
    }
    
    public void setAutoBackup(boolean autoBackup) {
        this.autoBackup = autoBackup;
    }
    
    public Timestamp getLastBackup() {
        return lastBackup;
    }
    
    public void setLastBackup(Timestamp lastBackup) {
        this.lastBackup = lastBackup;
    }
    
    public Timestamp getUpdatedAt() {
        return updatedAt;
    }
    
    public void setUpdatedAt(Timestamp updatedAt) {
        this.updatedAt = updatedAt;
    }
}