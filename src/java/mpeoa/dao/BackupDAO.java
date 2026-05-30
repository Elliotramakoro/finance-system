// src/java/mpeoa/dao/BackupDAO.java
package mpeoa.dao;

import mpeoa.models.BackupRecord;
import mpeoa.models.BackupSetting;
import mpeoa.utils.DatabaseUtil;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class BackupDAO {
    
    // ==================== Backup Records ====================
    
    public List<BackupRecord> getAllBackupRecords() {
        List<BackupRecord> backups = new ArrayList<>();
        String sql = "SELECT b.*, u.username as created_by_name FROM backup_records b " +
                    "LEFT JOIN users u ON b.created_by = u.user_id " +
                    "ORDER BY b.backup_date DESC";
        
        try (Connection conn = DatabaseUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            
            while (rs.next()) {
                BackupRecord backup = new BackupRecord();
                backup.setBackupId(rs.getInt("backup_id"));
                backup.setBackupName(rs.getString("backup_name"));
                backup.setBackupFile(rs.getString("backup_file"));
                backup.setBackupSize(rs.getString("backup_size"));
                backup.setBackupDate(rs.getTimestamp("backup_date"));
                backup.setBackupType(rs.getString("backup_type"));
                backup.setBackupStatus(rs.getString("backup_status"));
                backup.setCreatedBy(rs.getInt("created_by"));
                backup.setCreatedByName(rs.getString("created_by_name"));
                backup.setCreatedAt(rs.getTimestamp("created_at"));
                backups.add(backup);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return backups;
    }
    
    public int getBackupCount() {
        String sql = "SELECT COUNT(*) FROM backup_records";
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
    
    public boolean createBackupRecord(BackupRecord backup) {
        String sql = "INSERT INTO backup_records (backup_name, backup_file, backup_size, backup_type, backup_status, created_by) " +
                    "VALUES (?, ?, ?, ?, ?, ?)";
        
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, backup.getBackupName());
            pstmt.setString(2, backup.getBackupFile());
            pstmt.setString(3, backup.getBackupSize());
            pstmt.setString(4, backup.getBackupType());
            pstmt.setString(5, backup.getBackupStatus());
            pstmt.setInt(6, backup.getCreatedBy());
            
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    public boolean deleteBackupRecord(int backupId) {
        String sql = "DELETE FROM backup_records WHERE backup_id = ?";
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, backupId);
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    // ==================== Backup Settings ====================
    
    public BackupSetting getBackupSettings() {
        String sql = "SELECT * FROM backup_settings LIMIT 1";
        try (Connection conn = DatabaseUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            
            if (rs.next()) {
                BackupSetting setting = new BackupSetting();
                setting.setSettingId(rs.getInt("setting_id"));
                setting.setBackupFrequency(rs.getString("backup_frequency"));
                setting.setBackupTime(rs.getTime("backup_time"));
                setting.setRetentionDays(rs.getInt("retention_days"));
                setting.setBackupLocation(rs.getString("backup_location"));
                setting.setEncryptBackup(rs.getBoolean("encrypt_backup"));
                setting.setAutoBackup(rs.getBoolean("auto_backup"));
                setting.setLastBackup(rs.getTimestamp("last_backup"));
                setting.setUpdatedAt(rs.getTimestamp("updated_at"));
                return setting;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
    
    public boolean updateBackupSettings(BackupSetting setting) {
        String sql = "UPDATE backup_settings SET backup_frequency = ?, backup_time = ?, retention_days = ?, " +
                    "backup_location = ?, encrypt_backup = ?, auto_backup = ?, last_backup = ? WHERE setting_id = ?";
        
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, setting.getBackupFrequency());
            pstmt.setTime(2, setting.getBackupTime());
            pstmt.setInt(3, setting.getRetentionDays());
            pstmt.setString(4, setting.getBackupLocation());
            pstmt.setBoolean(5, setting.isEncryptBackup());
            pstmt.setBoolean(6, setting.isAutoBackup());
            pstmt.setTimestamp(7, setting.getLastBackup());
            pstmt.setInt(8, setting.getSettingId());
            
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    public boolean updateLastBackup(Timestamp lastBackup) {
        String sql = "UPDATE backup_settings SET last_backup = ?";
        try (Connection conn = DatabaseUtil.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setTimestamp(1, lastBackup);
            return pstmt.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
}