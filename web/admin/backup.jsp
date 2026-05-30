<%-- web/admin/backup.jsp --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="mpeoa.models.User, mpeoa.dao.BackupDAO, mpeoa.models.BackupRecord, mpeoa.models.BackupSetting, java.util.*, java.text.*, java.time.*, java.sql.Timestamp" %>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !"Administrator".equalsIgnoreCase(loggedInUser.getRoleName())) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    
    String success = request.getParameter("success");
    String error = request.getParameter("error");
    
    BackupDAO backupDAO = new BackupDAO();
    List<BackupRecord> backups = backupDAO.getAllBackupRecords();
    BackupSetting backupSettings = backupDAO.getBackupSettings();
    
    DecimalFormat df = new DecimalFormat("#,##0.00");
    
    // Calculate total size
    int totalBackups = backups.size();
    double totalSizeMB = 0;
    for (BackupRecord backup : backups) {
        String sizeStr = backup.getBackupSize();
        if (sizeStr != null && !sizeStr.isEmpty()) {
            try {
                String numericSize = sizeStr.replace(" MB", "").trim();
                totalSizeMB += Double.parseDouble(numericSize);
            } catch (NumberFormatException e) {
                totalSizeMB += 0;
            }
        }
    }
    String formattedTotalSize = String.format("%.1f", totalSizeMB);
    
    // Get schedule info - FIXED: handle null properly
    String backupFrequency = "daily";
    String backupTime = "02:00:00";
    int retentionDays = 30;
    String backupLocation = "/var/backups/mpeoa/";
    boolean autoBackup = true;
    boolean encryptBackup = true;
    String lastBackupStr = "Never";
    
    if (backupSettings != null) {
        backupFrequency = backupSettings.getBackupFrequency() != null ? backupSettings.getBackupFrequency() : "daily";
        backupTime = backupSettings.getBackupTime() != null ? backupSettings.getBackupTime().toString() : "02:00:00";
        retentionDays = backupSettings.getRetentionDays() > 0 ? backupSettings.getRetentionDays() : 30;
        backupLocation = backupSettings.getBackupLocation() != null ? backupSettings.getBackupLocation() : "/var/backups/mpeoa/";
        autoBackup = backupSettings.isAutoBackup();
        encryptBackup = backupSettings.isEncryptBackup();
        if (backupSettings.getLastBackup() != null) {
            lastBackupStr = backupSettings.getLastBackup().toString();
        }
    }
    
    // Build initials
    String initials = "A";
    String adminName = loggedInUser.getFullName();
    if (adminName != null && !adminName.trim().isEmpty()) {
        String[] parts = adminName.trim().split("\\s+");
        if (parts.length >= 2) initials = "" + parts[0].charAt(0) + parts[1].charAt(0);
        else initials = "" + parts[0].charAt(0);
        initials = initials.toUpperCase();
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Backup & Recovery — Mpeoa Supermarket ERP</title>
    
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet"/>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet"/>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600;700;800&family=DM+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet"/>
    
    <style>
        :root {
            --cream: #F5F0E6;
            --cream-dark: #EDE6D4;
            --cream-border: #DDD8CE;
            --gold: #C8923A;
            --gold-light: #DBA85A;
            --gold-pale: rgba(200,146,58,0.10);
            --navy: #12223A;
            --navy-mid: #1A3050;
            --white: #FFFFFF;
            --text-muted: #6B6670;
            --success: #2E7D52;
            --success-pale: rgba(46,125,82,0.10);
            --danger: #C0392B;
            --danger-pale: rgba(192,57,43,0.10);
            --warning: #D4A42B;
            --warning-pale: rgba(212,164,43,0.10);
            --info: #17A2B8;
            --info-pale: rgba(23,162,184,0.10);
            --sidebar-w: 260px;
            --topbar-h: 64px;
            --radius: 12px;
            --shadow: 0 2px 16px rgba(18,34,58,0.08);
            --shadow-md: 0 4px 24px rgba(18,34,58,0.12);
            --font-display: 'Playfair Display', Georgia, serif;
            --font-body: 'DM Sans', sans-serif;
        }

        *, *::before, *::after { box-sizing: border-box; }
        body {
            font-family: var(--font-body);
            background: var(--cream);
            color: var(--navy);
            margin: 0; min-height: 100vh;
        }
        
        /* Sidebar styles */
        .sidebar {
            position: fixed; top: 0; left: 0;
            width: var(--sidebar-w); height: 100vh;
            background: var(--navy);
            display: flex; flex-direction: column;
            z-index: 1040;
            transition: transform 0.32s;
            overflow-y: auto;
        }
        @media (max-width: 991.98px) {
            .sidebar { transform: translateX(-100%); }
            .sidebar.open { transform: translateX(0); }
        }
        .sidebar-brand {
            padding: 24px 20px;
            border-bottom: 1px solid rgba(255,255,255,0.07);
            display: flex;
            align-items: center;
            gap: 12px;
        }
        .sidebar-logo {
            width: 40px; height: 40px;
            border-radius: 50%;
            border: 1.5px solid rgba(200,146,58,0.5);
            background: rgba(200,146,58,0.12);
            display: flex;
            align-items: center;
            justify-content: center;
            font-family: var(--font-display);
            font-size: 1.1rem;
            font-weight: 700;
            color: var(--gold-light);
        }
        .sidebar-brand-name {
            font-family: var(--font-display);
            font-size: 0.92rem;
            font-weight: 700;
            color: var(--white);
        }
        .sidebar-brand-sub {
            font-size: 0.68rem;
            color: rgba(255,255,255,0.38);
            text-transform: uppercase;
        }
        .sidebar-close {
            display: none;
            position: absolute;
            top: 18px; right: 14px;
            background: none;
            border: none;
            color: rgba(255,255,255,0.5);
            font-size: 1.4rem;
            cursor: pointer;
        }
        @media (max-width: 991.98px) { .sidebar-close { display: flex; } }
        .nav-section-label {
            font-size: 0.65rem;
            font-weight: 600;
            letter-spacing: 0.12em;
            text-transform: uppercase;
            color: rgba(255,255,255,0.28);
            padding: 18px 20px 6px;
        }
        .sidebar-nav { padding: 8px 0; flex: 1; }
        .nav-item-link {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 11px 20px;
            color: rgba(255,255,255,0.60);
            text-decoration: none;
            font-size: 0.88rem;
            font-weight: 500;
            border-left: 3px solid transparent;
            transition: all 0.18s;
        }
        .nav-item-link i { font-size: 1rem; width: 18px; }
        .nav-item-link:hover { color: var(--white); background: rgba(255,255,255,0.05); border-left-color: rgba(200,146,58,0.4); }
        .nav-item-link.active { color: var(--gold-light); background: rgba(200,146,58,0.10); border-left-color: var(--gold); font-weight: 600; }
        .sidebar-footer {
            padding: 16px 20px;
            border-top: 1px solid rgba(255,255,255,0.07);
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .sidebar-avatar {
            width: 34px; height: 34px;
            border-radius: 50%;
            background: var(--gold-pale);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 0.8rem;
            font-weight: 700;
            color: var(--gold-light);
        }
        .sidebar-admin-name { font-size: 0.8rem; font-weight: 600; color: rgba(255,255,255,0.8); }
        .sidebar-admin-role { font-size: 0.67rem; color: rgba(255,255,255,0.35); text-transform: uppercase; }
        .sidebar-logout { margin-left: auto; background: none; border: none; color: rgba(255,255,255,0.3); font-size: 1rem; cursor: pointer; }
        .sidebar-logout:hover { color: #e74c3c; }
        .sidebar-overlay { display: none; position: fixed; inset: 0; background: rgba(18,34,58,0.55); z-index: 1039; backdrop-filter: blur(2px); }
        .sidebar-overlay.show { display: block; }

        .main-wrap { margin-left: var(--sidebar-w); min-height: 100vh; }
        @media (max-width: 991.98px) { .main-wrap { margin-left: 0; } }

        .topbar {
            height: var(--topbar-h);
            background: rgba(245,240,230,0.92);
            backdrop-filter: blur(12px);
            border-bottom: 1px solid var(--cream-border);
            padding: 0 28px;
            display: flex;
            align-items: center;
            gap: 16px;
            position: sticky;
            top: 0;
            z-index: 100;
        }
        .burger-btn { display: none; background: none; border: none; font-size: 1.35rem; cursor: pointer; }
        .burger-btn:hover { background: var(--gold-pale); border-radius: 6px; }
        @media (max-width: 991.98px) { .burger-btn { display: flex; } }
        .topbar-title { font-family: var(--font-display); font-size: 1.15rem; font-weight: 700; color: var(--navy); flex: 1; }
        .topbar-date { font-size: 0.78rem; color: var(--text-muted); }
        @media (max-width: 576px) { .topbar-date { display: none; } }
        .topbar-avatar { width: 36px; height: 36px; border-radius: 50%; background: var(--navy); display: flex; align-items: center; justify-content: center; font-size: 0.8rem; font-weight: 700; color: var(--gold-light); border: 2px solid var(--cream-border); }

        .page-body { padding: 28px; }
        @media (max-width: 576px) { .page-body { padding: 16px; } }
        .page-header { margin-bottom: 28px; }
        .page-eyebrow { font-size: 0.72rem; font-weight: 600; letter-spacing: 0.1em; text-transform: uppercase; color: var(--gold); margin-bottom: 4px; }
        .page-heading { font-family: var(--font-display); font-size: 1.7rem; font-weight: 700; color: var(--navy); margin: 0; }

        .stat-card {
            background: var(--white);
            border-radius: var(--radius);
            padding: 20px;
            border: 1px solid var(--cream-border);
            transition: transform 0.2s;
            height: 100%;
        }
        .stat-card:hover { transform: translateY(-3px); box-shadow: var(--shadow-md); }
        .stat-icon {
            width: 44px; height: 44px;
            border-radius: 10px;
            background: var(--gold-pale);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.2rem;
            margin-bottom: 12px;
            color: var(--gold);
        }
        .stat-value { font-family: var(--font-display); font-size: 1.5rem; font-weight: 700; margin-bottom: 4px; color: var(--navy); }
        .stat-label { font-size: 0.75rem; color: var(--text-muted); }

        .backup-actions {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 24px;
        }
        .action-card {
            background: var(--white);
            border-radius: var(--radius);
            padding: 20px;
            text-align: center;
            border: 1px solid var(--cream-border);
            transition: all 0.3s;
            cursor: pointer;
        }
        .action-card:hover { transform: translateY(-5px); box-shadow: var(--shadow-md); border-color: var(--gold); }
        .action-icon { font-size: 2.5rem; color: var(--gold); margin-bottom: 12px; }
        .action-title { font-weight: 700; font-size: 1rem; margin-bottom: 5px; }
        .action-desc { font-size: 0.7rem; color: var(--text-muted); }

        .content-card {
            background: var(--white);
            border-radius: var(--radius);
            border: 1px solid var(--cream-border);
            box-shadow: var(--shadow);
            overflow: hidden;
            margin-bottom: 24px;
        }
        .card-header-bar {
            padding: 16px 20px;
            border-bottom: 1px solid var(--cream-border);
            background: var(--cream-dark);
        }
        .card-header-title {
            font-family: var(--font-display);
            font-size: 0.95rem;
            font-weight: 700;
            margin: 0;
            display: flex;
            align-items: center;
            gap: 8px;
            color: var(--navy);
        }
        .btn-sm-outline {
            background: transparent;
            border: 1px solid var(--cream-border);
            color: var(--navy);
            padding: 5px 12px;
            border-radius: 6px;
            font-size: 0.7rem;
            font-weight: 600;
            text-decoration: none;
            transition: all 0.2s;
        }
        .btn-sm-outline:hover { border-color: var(--gold); background: var(--gold-pale); color: var(--gold); }
        .btn-gold {
            background: var(--gold);
            color: white;
            border: none;
            border-radius: 8px;
            padding: 10px 20px;
            font-size: 0.85rem;
            font-weight: 600;
            cursor: pointer;
        }
        .btn-gold:hover { background: var(--gold-light); }
        .btn-outline {
            background: transparent;
            border: 1.5px solid var(--cream-border);
            color: var(--navy);
            border-radius: 8px;
            padding: 10px 20px;
            font-size: 0.85rem;
            font-weight: 600;
            cursor: pointer;
        }
        .btn-outline:hover { border-color: var(--gold); background: var(--gold-pale); }

        .data-table { width: 100%; border-collapse: collapse; font-size: 0.8rem; }
        .data-table thead th { background: var(--cream); padding: 12px 16px; text-align: left; font-size: 0.7rem; font-weight: 600; text-transform: uppercase; color: var(--navy); border-bottom: 1px solid var(--cream-border); }
        .data-table tbody td { padding: 12px 16px; border-bottom: 1px solid var(--cream-border); color: var(--navy); }
        .data-table tbody tr:hover { background: var(--cream); }

        .badge-complete { background: var(--success-pale); color: var(--success); padding: 4px 8px; border-radius: 12px; font-size: 0.65rem; font-weight: 600; }
        
        .form-group { margin-bottom: 20px; }
        .form-group label { font-size: 0.75rem; font-weight: 600; letter-spacing: 0.05em; text-transform: uppercase; color: var(--navy); margin-bottom: 6px; display: block; }
        .form-control, .form-select { width: 100%; padding: 10px 14px; border: 1.5px solid var(--cream-border); border-radius: 8px; font-size: 0.88rem; color: var(--navy); background: var(--white); outline: none; }
        .form-control:focus, .form-select:focus { border-color: var(--gold); box-shadow: 0 0 0 3px var(--gold-pale); }
        .info-text { font-size: 0.7rem; color: var(--text-muted); margin-top: 5px; }
        .form-buttons { margin-top: 20px; }

        .alert-custom { padding: 12px 16px; border-radius: 10px; margin-bottom: 20px; font-size: 0.85rem; display: flex; align-items: center; gap: 10px; }
        .alert-success { background: var(--success-pale); border: 1px solid rgba(46,125,82,0.25); color: var(--success); }
        .alert-info { background: var(--info-pale); border: 1px solid rgba(23,162,184,0.25); color: var(--info); }
        .alert-warning { background: var(--warning-pale); border: 1px solid rgba(212,164,43,0.25); color: var(--warning); }
        .alert-danger { background: var(--danger-pale); border: 1px solid rgba(192,57,43,0.25); color: var(--danger); }

        .divider { height: 1px; background: var(--cream-border); margin: 15px 0; }

        .d-flex { display: flex; }
        .align-items-center { align-items: center; }
        .justify-content-between { justify-content: space-between; }
        .gap-2 { gap: 8px; }
        .gap-3 { gap: 16px; }
        .mb-4 { margin-bottom: 24px; }
        .mt-2 { margin-top: 8px; }
        .mt-4 { margin-top: 24px; }
        .fw-bold { font-weight: 700; }
        .me-1 { margin-right: 4px; }
        .text-center { text-align: center; }
        
        @keyframes fadeUp {
            from { opacity: 0; transform: translateY(16px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .animate-fade { animation: fadeUp 0.4s ease both; }
    </style>
</head>
<body>

<div class="sidebar-overlay" id="sidebarOverlay" onclick="closeSidebar()"></div>

<!-- Sidebar -->
<aside class="sidebar" id="sidebar">
    <button class="sidebar-close" onclick="closeSidebar()">
        <i class="bi bi-x-lg"></i>
    </button>
    <div class="sidebar-brand">
        <div class="sidebar-logo">MS</div>
        <div class="sidebar-brand-text">
            <div class="sidebar-brand-name">Mpeoa Supermarket</div>
            <div class="sidebar-brand-sub">ERP System</div>
        </div>
    </div>
    <nav class="sidebar-nav">
        <div class="nav-section-label">Main</div>
        <a href="${pageContext.request.contextPath}/admin/dashboard.jsp" class="nav-item-link">
            <i class="bi bi-grid-1x2-fill"></i> Dashboard
        </a>
        
        <div class="nav-section-label">Management</div>
        <a href="${pageContext.request.contextPath}/admin/users.jsp" class="nav-item-link">
            <i class="bi bi-people-fill"></i> User Management
        </a>
        <a href="${pageContext.request.contextPath}/admin/products.jsp" class="nav-item-link">
            <i class="bi bi-box-seam-fill"></i> Products
        </a>
        <a href="${pageContext.request.contextPath}/admin/inventory.jsp" class="nav-item-link">
            <i class="bi bi-archive-fill"></i> Inventory
        </a>
        <a href="${pageContext.request.contextPath}/admin/categories.jsp" class="nav-item-link">
            <i class="bi bi-tags-fill"></i> Categories
        </a>

        <div class="nav-section-label">Operations</div>
        <a href="${pageContext.request.contextPath}/admin/sales.jsp" class="nav-item-link">
            <i class="bi bi-receipt"></i> Sales
        </a>
        <a href="${pageContext.request.contextPath}/admin/expenses.jsp" class="nav-item-link">
            <i class="bi bi-wallet2"></i> Expenses
        </a>
        <a href="${pageContext.request.contextPath}/admin/suppliers.jsp" class="nav-item-link">
            <i class="bi bi-truck"></i> Suppliers
        </a>
        <a href="${pageContext.request.contextPath}/admin/purchases.jsp" class="nav-item-link">
            <i class="bi bi-cart-fill"></i> Purchases
        </a>

        <div class="nav-section-label">Reports & Analytics</div>
        <a href="${pageContext.request.contextPath}/admin/reports.jsp" class="nav-item-link">
            <i class="bi bi-graph-up"></i> Reports
        </a>
        <a href="${pageContext.request.contextPath}/admin/analytics.jsp" class="nav-item-link">
            <i class="bi bi-bar-chart-steps"></i> Analytics
        </a>

        <div class="nav-section-label">System</div>
        <a href="${pageContext.request.contextPath}/admin/settings.jsp" class="nav-item-link">
            <i class="bi bi-gear-fill"></i> Settings
        </a>
        <a href="${pageContext.request.contextPath}/admin/security.jsp" class="nav-item-link">
            <i class="bi bi-shield-lock-fill"></i> Security
        </a>
        <a href="${pageContext.request.contextPath}/admin/backup.jsp" class="nav-item-link active">
            <i class="bi bi-database-fill"></i> Backup & Recovery
        </a>
    </nav>
    <div class="sidebar-footer">
        <div class="sidebar-avatar"><%= initials %></div>
        <div>
            <div class="sidebar-admin-name"><%= adminName != null ? adminName : "Administrator" %></div>
            <div class="sidebar-admin-role">Administrator</div>
        </div>
        <a href="${pageContext.request.contextPath}/logout" class="sidebar-logout" title="Logout">
            <i class="bi bi-box-arrow-right"></i>
        </a>
    </div>
</aside>

<!-- Main Content -->
<div class="main-wrap">
    <header class="topbar">
        <button class="burger-btn" onclick="openSidebar()"><i class="bi bi-list"></i></button>
        <span class="topbar-title">Backup & Recovery</span>
        <span class="topbar-date">
            <i class="bi bi-calendar3 me-1"></i>
            <script>document.write(new Date().toLocaleDateString('en-ZA'));</script>
        </span>
        <div class="topbar-avatar"><%= initials %></div>
    </header>

    <main class="page-body">
        <div class="page-header">
            <div>
                <p class="page-eyebrow">Data Protection</p>
                <h1 class="page-heading">Backup & Recovery</h1>
                <p class="text-muted mt-2">Manage database backups and restore points</p>
            </div>
        </div>
        
        <% if (success != null) { %>
            <div class="alert-custom alert-success animate-fade">
                <i class="bi bi-check-circle-fill"></i>
                <span><%= success %></span>
            </div>
        <% } %>
        
        <% if (error != null) { %>
            <div class="alert-custom alert-danger animate-fade">
                <i class="bi bi-exclamation-triangle-fill"></i>
                <span><%= error %></span>
            </div>
        <% } %>

        <!-- Statistics Cards -->
        <div class="row g-3 mb-4">
            <div class="col-md-3 col-6">
                <div class="stat-card animate-fade">
                    <div class="stat-icon"><i class="bi bi-database-fill"></i></div>
                    <div class="stat-value"><%= totalBackups %></div>
                    <div class="stat-label">Total Backups</div>
                </div>
            </div>
            <div class="col-md-3 col-6">
                <div class="stat-card animate-fade">
                    <div class="stat-icon"><i class="bi bi-hdd-stack-fill"></i></div>
                    <div class="stat-value"><%= formattedTotalSize %> MB</div>
                    <div class="stat-label">Total Storage Used</div>
                </div>
            </div>
            <div class="col-md-3 col-6">
                <div class="stat-card animate-fade">
                    <div class="stat-icon"><i class="bi bi-clock-history"></i></div>
                    <div class="stat-value"><%= backupFrequency.substring(0,1).toUpperCase() + backupFrequency.substring(1) %></div>
                    <div class="stat-label">Backup Schedule</div>
                </div>
            </div>
            <div class="col-md-3 col-6">
                <div class="stat-card animate-fade">
                    <div class="stat-icon"><i class="bi bi-shield-check"></i></div>
                    <div class="stat-value"><%= encryptBackup ? "Encrypted" : "Not Encrypted" %></div>
                    <div class="stat-label">Backup Security</div>
                </div>
            </div>
        </div>

        <!-- Backup Actions -->
        <div class="backup-actions">
            <div class="action-card" onclick="createBackup()">
                <div class="action-icon"><i class="bi bi-plus-circle-fill"></i></div>
                <div class="action-title">Create New Backup</div>
                <div class="action-desc">Create a full database backup</div>
            </div>
            <div class="action-card" onclick="scheduleBackup()">
                <div class="action-icon"><i class="bi bi-clock-fill"></i></div>
                <div class="action-title">Schedule Backup</div>
                <div class="action-desc">Configure automatic backups</div>
            </div>
            <div class="action-card" onclick="restoreBackup()">
                <div class="action-icon"><i class="bi bi-arrow-repeat"></i></div>
                <div class="action-title">Restore from Backup</div>
                <div class="action-desc">Restore database from a backup</div>
            </div>
            <div class="action-card" onclick="exportBackup()">
                <div class="action-icon"><i class="bi bi-download"></i></div>
                <div class="action-title">Export Backup</div>
                <div class="action-desc">Download backup to local machine</div>
            </div>
        </div>

        <!-- Backup Schedule Status -->
        <div class="alert-custom alert-info animate-fade">
            <i class="bi bi-info-circle-fill"></i>
            <span>Automatic backups are scheduled <strong><%= backupFrequency %></strong> at <strong><%= backupTime %></strong>. 
            Last backup: <strong><%= lastBackupStr %></strong>
            </span>
        </div>

        <!-- Backup Files Table -->
        <div class="content-card">
            <div class="card-header-bar">
                <h2 class="card-header-title">
                    <i class="bi bi-files"></i> Backup Files
                </h2>
                <span class="btn-sm-outline">Total: <%= totalBackups %> files</span>
            </div>
            <div class="table-responsive">
                <% if (backups != null && !backups.isEmpty()) { %>
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>File Name</th>
                                <th>Size</th>
                                <th>Created Date</th>
                                <th>Type</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </thead>
                        <tbody>
                            <% for (BackupRecord backup : backups) { %>
                                <tr>
                                    <td><strong><%= backup.getBackupFile() %></strong></td>
                                    <td><%= backup.getBackupSize() != null ? backup.getBackupSize() : "-" %></td>
                                    <td><%= backup.getBackupDate() != null ? backup.getBackupDate().toString() : "-" %></td>
                                    <td><%= backup.getBackupType() != null ? backup.getBackupType() : "manual" %></td>
                                    <td><span class="badge-complete"><%= backup.getBackupStatus() != null ? backup.getBackupStatus() : "Completed" %></span></td>
                                    <td>
                                        <div class="d-flex gap-2">
                                            <button class="btn-sm-outline" onclick="downloadBackup('<%= backup.getBackupFile() %>')">
                                                <i class="bi bi-download"></i> Download
                                            </button>
                                            <button class="btn-sm-outline" onclick="restoreBackupFile('<%= backup.getBackupFile() %>')">
                                                <i class="bi bi-arrow-repeat"></i> Restore
                                            </button>
                                            <button class="btn-sm-outline" onclick="deleteBackup(<%= backup.getBackupId() %>, '<%= backup.getBackupFile() %>')">
                                                <i class="bi bi-trash"></i> Delete
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            <% } %>
                        </tbody>
                    </table>
                <% } else { %>
                    <div class="text-center" style="padding: 60px 20px; color: var(--text-muted);">
                        <i class="bi bi-database" style="font-size: 3rem; opacity: 0.3; display: block; margin-bottom: 15px;"></i>
                        <h4>No Backups Found</h4>
                        <p>Click "Create New Backup" to create your first database backup.</p>
                    </div>
                <% } %>
            </div>
        </div>

        <!-- Backup Settings -->
        <div class="row g-3">
            <div class="col-md-6">
                <div class="content-card">
                    <div class="card-header-bar">
                        <h2 class="card-header-title">
                            <i class="bi bi-gear-fill"></i> Backup Settings
                        </h2>
                    </div>
                    <div class="card-body" style="padding: 20px;">
                        <form action="${pageContext.request.contextPath}/admin/backup-settings" method="post">
                            <div class="form-group">
                                <label>Auto Backup Frequency</label>
                                <select name="backupFrequency" class="form-control">
                                    <option value="daily" <%= "daily".equals(backupFrequency) ? "selected" : "" %>>Daily</option>
                                    <option value="weekly" <%= "weekly".equals(backupFrequency) ? "selected" : "" %>>Weekly</option>
                                    <option value="monthly" <%= "monthly".equals(backupFrequency) ? "selected" : "" %>>Monthly</option>
                                </select>
                            </div>
                            <div class="form-group">
                                <label>Backup Time</label>
                                <input type="time" name="backupTime" class="form-control" value="<%= backupTime %>">
                            </div>
                            <div class="form-group">
                                <label>Retention Period (days)</label>
                                <input type="number" name="retentionDays" class="form-control" value="<%= retentionDays %>">
                                <div class="info-text">Backups older than this will be automatically deleted</div>
                            </div>
                            <div class="form-group">
                                <label>Backup Location</label>
                                <input type="text" name="backupLocation" class="form-control" value="<%= backupLocation %>">
                                <div class="info-text">Directory where backup files will be stored</div>
                            </div>
                            <div class="form-group">
                                <div class="d-flex justify-content-between align-items-center">
                                    <label>Auto Backup Enabled</label>
                                    <div>
                                        <input type="checkbox" name="autoBackup" value="true" <%= autoBackup ? "checked" : "" %>>
                                    </div>
                                </div>
                            </div>
                            <div class="form-buttons">
                                <button type="submit" class="btn-gold">Save Backup Settings</button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
            
            <div class="col-md-6">
                <div class="content-card">
                    <div class="card-header-bar">
                        <h2 class="card-header-title">
                            <i class="bi bi-info-circle-fill"></i> Recovery Guide
                        </h2>
                    </div>
                    <div style="padding: 20px;">
                        <div class="alert-custom alert-warning" style="margin-bottom: 20px;">
                            <i class="bi bi-exclamation-triangle-fill"></i>
                            <span>Restoring a backup will overwrite current data. This action cannot be undone.</span>
                        </div>
                        <h6 style="font-weight: 700; margin-bottom: 15px;">How to restore from backup:</h6>
                        <ol style="padding-left: 20px; color: var(--text-muted); font-size: 0.85rem; line-height: 1.8;">
                            <li>Select the backup file you want to restore</li>
                            <li>Click the "Restore" button next to the file</li>
                            <li>Confirm the restore operation</li>
                            <li>Wait for the restoration to complete</li>
                            <li>Verify the restored data</li>
                        </ol>
                        <div class="divider"></div>
                        <h6 style="font-weight: 700; margin-bottom: 15px;">Best Practices:</h6>
                        <ul style="padding-left: 20px; color: var(--text-muted); font-size: 0.85rem; line-height: 1.8;">
                            <li>Keep at least 30 days of backup history</li>
                            <li>Store backups in a secure, off-site location</li>
                            <li>Test restore procedures regularly</li>
                            <li>Monitor backup success/failure notifications</li>
                            <li>Encrypt sensitive backup files</li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
    </main>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
    function openSidebar() {
        document.getElementById('sidebar').classList.add('open');
        document.getElementById('sidebarOverlay').classList.add('show');
        document.body.style.overflow = 'hidden';
    }
    function closeSidebar() {
        document.getElementById('sidebar').classList.remove('open');
        document.getElementById('sidebarOverlay').classList.remove('show');
        document.body.style.overflow = '';
    }
    
    function createBackup() {
        if (confirm('Create a new database backup? This may take a few minutes.')) {
            window.location.href = '${pageContext.request.contextPath}/admin/backup-create';
        }
    }
    
    function scheduleBackup() {
        alert('Schedule backup settings are available in the Backup Settings section below.');
    }
    
    function restoreBackup() {
        alert('Select a backup file from the list and click Restore.');
    }
    
    function exportBackup() {
        alert('Select a backup file from the list and click Download.');
    }
    
    function downloadBackup(filename) {
        alert('Downloading: ' + filename + '\n\nBackup download will start shortly.');
    }
    
    function restoreBackupFile(filename) {
        if (confirm('WARNING: Restoring this backup will overwrite ALL current data. Are you sure?')) {
            alert('Restoring from: ' + filename + '\n\nThis may take a few minutes.');
        }
    }
    
    function deleteBackup(backupId, filename) {
        if (confirm('Are you sure you want to delete ' + filename + '?')) {
            window.location.href = '${pageContext.request.contextPath}/admin/backup-delete?id=' + backupId;
        }
    }
    
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') closeSidebar();
    });
</script>

</body>
</html>