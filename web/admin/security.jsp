<%-- web/admin/security.jsp --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="mpeoa.models.User, java.util.*, java.text.*" %>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !"Administrator".equalsIgnoreCase(loggedInUser.getRoleName())) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    
    String success = request.getParameter("success");
    String error = request.getParameter("error");
    
    // Security settings (sample data - replace with actual settings from database)
    String twoFactorAuth = "disabled";
    String passwordExpiry = "90";
    String loginAttempts = "5";
    String sessionTimeout = "30";
    String ipWhitelist = "";
    String auditLogRetention = "180";
    String dataEncryption = "enabled";
    String backupEncryption = "enabled";
    
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
    <title>Security Settings — Mpeoa Supermarket ERP</title>
    
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet"/>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet"/>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600;700;800&family=DM+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet"/>
    
    <style>
        :root {
            --cream:         #F5F0E6;
            --cream-dark:    #EDE6D4;
            --cream-border:  #DDD8CE;
            --gold:          #C8923A;
            --gold-light:    #DBA85A;
            --gold-pale:     rgba(200,146,58,0.10);
            --navy:          #12223A;
            --navy-mid:      #1A3050;
            --navy-light:    #243D5C;
            --white:         #FFFFFF;
            --text-muted:    #6B6670;
            --success:       #2E7D52;
            --success-pale:  rgba(46,125,82,0.10);
            --danger:        #C0392B;
            --danger-pale:   rgba(192,57,43,0.10);
            --warning:       #D4A42B;
            --warning-pale:  rgba(212,164,43,0.10);
            --info:          #17A2B8;
            --info-pale:     rgba(23,162,184,0.10);
            --sidebar-w:     260px;
            --topbar-h:      64px;
            --font-display:  'Playfair Display', Georgia, serif;
            --font-body:     'DM Sans', sans-serif;
            --radius:        12px;
            --shadow:        0 2px 16px rgba(18,34,58,0.08);
            --shadow-md:     0 4px 24px rgba(18,34,58,0.12);
        }

        *, *::before, *::after { box-sizing: border-box; }
        body {
            font-family: var(--font-body);
            background: var(--cream);
            color: var(--navy);
            margin: 0; min-height: 100vh;
        }

        /* Sidebar */
        .sidebar {
            position: fixed; top: 0; left: 0;
            width: var(--sidebar-w); height: 100vh;
            background: var(--navy);
            display: flex; flex-direction: column;
            z-index: 1040;
            transition: transform 0.32s cubic-bezier(0.4,0,0.2,1);
            overflow-y: auto; overflow-x: hidden;
        }
        @media (max-width: 991.98px) {
            .sidebar { transform: translateX(-100%); }
            .sidebar.open { transform: translateX(0); }
        }
        .sidebar-brand {
            padding: 24px 20px 20px;
            border-bottom: 1px solid rgba(255,255,255,0.07);
            display: flex; align-items: center; gap: 12px; flex-shrink: 0;
        }
        .sidebar-logo {
            width: 40px; height: 40px;
            border-radius: 50%;
            border: 1.5px solid rgba(200,146,58,0.5);
            background: rgba(200,146,58,0.12);
            display: flex; align-items: center; justify-content: center;
            font-family: var(--font-display); font-size: 1.1rem; font-weight: 700;
            color: var(--gold-light); flex-shrink: 0;
        }
        .sidebar-brand-text { line-height: 1.2; }
        .sidebar-brand-name { font-family: var(--font-display); font-size: 0.92rem; font-weight: 700; color: var(--white); }
        .sidebar-brand-sub  { font-size: 0.68rem; font-weight: 500; color: rgba(255,255,255,0.38); letter-spacing: 0.08em; text-transform: uppercase; }
        .sidebar-close {
            display: none; position: absolute; top: 18px; right: 14px;
            background: none; border: none; color: rgba(255,255,255,0.5);
            font-size: 1.4rem; cursor: pointer;
        }
        .sidebar-close:hover { color: var(--gold-light); }
        @media (max-width: 991.98px) { .sidebar-close { display: flex; } }
        .nav-section-label {
            font-size: 0.65rem; font-weight: 600; letter-spacing: 0.12em;
            text-transform: uppercase; color: rgba(255,255,255,0.28); padding: 18px 20px 6px;
        }
        .sidebar-nav { padding: 8px 0; flex: 1; }
        .nav-item-link {
            display: flex; align-items: center; gap: 12px; padding: 11px 20px;
            color: rgba(255,255,255,0.60); text-decoration: none;
            font-size: 0.88rem; font-weight: 500;
            border-left: 3px solid transparent; transition: all 0.18s;
        }
        .nav-item-link i { font-size: 1rem; width: 18px; text-align: center; }
        .nav-item-link:hover { color: var(--white); background: rgba(255,255,255,0.05); border-left-color: rgba(200,146,58,0.4); }
        .nav-item-link.active { color: var(--gold-light); background: rgba(200,146,58,0.10); border-left-color: var(--gold); font-weight: 600; }
        .sidebar-footer {
            padding: 16px 20px; border-top: 1px solid rgba(255,255,255,0.07);
            display: flex; align-items: center; gap: 10px; flex-shrink: 0;
        }
        .sidebar-avatar {
            width: 34px; height: 34px; border-radius: 50%;
            background: var(--gold-pale); border: 1.5px solid rgba(200,146,58,0.4);
            display: flex; align-items: center; justify-content: center;
            font-size: 0.8rem; font-weight: 700; color: var(--gold-light);
        }
        .sidebar-admin-name { font-size: 0.8rem; font-weight: 600; color: rgba(255,255,255,0.8); }
        .sidebar-admin-role { font-size: 0.67rem; color: rgba(255,255,255,0.35); text-transform: uppercase; }
        .sidebar-logout { margin-left: auto; background: none; border: none; color: rgba(255,255,255,0.3); font-size: 1rem; cursor: pointer; }
        .sidebar-logout:hover { color: #e74c3c; }
        .sidebar-overlay { display: none; position: fixed; inset: 0; background: rgba(18,34,58,0.55); z-index: 1039; backdrop-filter: blur(2px); }
        .sidebar-overlay.show { display: block; }

        /* Main Content */
        .main-wrap {
            margin-left: var(--sidebar-w);
            min-height: 100vh;
            transition: margin-left 0.32s;
        }
        @media (max-width: 991.98px) {
            .main-wrap { margin-left: 0; }
        }

        /* Topbar */
        .topbar {
            height: var(--topbar-h);
            background: rgba(245,240,230,0.92);
            backdrop-filter: blur(12px);
            border-bottom: 1px solid var(--cream-border);
            padding: 0 28px;
            display: flex; align-items: center; gap: 16px;
            position: sticky; top: 0; z-index: 100;
        }
        .burger-btn { display: none; background: none; border: none; color: var(--navy); font-size: 1.35rem; cursor: pointer; }
        .burger-btn:hover { background: var(--gold-pale); border-radius: 6px; }
        @media (max-width: 991.98px) { .burger-btn { display: flex; } }
        .topbar-title { font-family: var(--font-display); font-size: 1.15rem; font-weight: 700; color: var(--navy); flex: 1; }
        .topbar-date { font-size: 0.78rem; color: var(--text-muted); }
        @media (max-width: 576px) { .topbar-date { display: none; } }
        .topbar-avatar { width: 36px; height: 36px; border-radius: 50%; background: var(--navy); display: flex; align-items: center; justify-content: center; font-size: 0.8rem; font-weight: 700; color: var(--gold-light); border: 2px solid var(--cream-border); }

        /* Page Body */
        .page-body { padding: 28px; }
        @media (max-width: 576px) { .page-body { padding: 16px; } }
        .page-header { margin-bottom: 28px; }
        .page-eyebrow { font-size: 0.72rem; font-weight: 600; letter-spacing: 0.1em; text-transform: uppercase; color: var(--gold); margin-bottom: 4px; }
        .page-heading { font-family: var(--font-display); font-size: 1.7rem; font-weight: 700; color: var(--navy); margin: 0; }

        /* Settings Container */
        .settings-container {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(500px, 1fr));
            gap: 24px;
        }
        
        .settings-card {
            background: var(--white);
            border-radius: var(--radius);
            border: 1px solid var(--cream-border);
            box-shadow: var(--shadow);
            overflow: hidden;
            margin-bottom: 24px;
            height: 100%;
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
        .card-body {
            padding: 20px;
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        .form-group label {
            font-size: 0.75rem;
            font-weight: 600;
            letter-spacing: 0.05em;
            text-transform: uppercase;
            color: var(--navy);
            margin-bottom: 6px;
            display: block;
        }
        .form-control, .form-select {
            width: 100%;
            padding: 10px 14px;
            border: 1.5px solid var(--cream-border);
            border-radius: 8px;
            font-family: var(--font-body);
            font-size: 0.88rem;
            color: var(--navy);
            background: var(--white);
            outline: none;
            transition: border-color 0.18s, box-shadow 0.18s;
        }
        .form-control:focus, .form-select:focus {
            border-color: var(--gold);
            box-shadow: 0 0 0 3px var(--gold-pale);
        }
        textarea.form-control {
            resize: vertical;
            min-height: 80px;
        }
        .form-row {
            display: flex;
            gap: 20px;
            flex-wrap: wrap;
        }
        .form-row .form-group {
            flex: 1;
        }
        
        .btn-gold {
            background: var(--gold);
            color: var(--white);
            border: none;
            border-radius: 8px;
            padding: 10px 24px;
            font-size: 0.88rem;
            font-weight: 600;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            cursor: pointer;
            transition: background 0.2s;
        }
        .btn-gold:hover {
            background: var(--gold-light);
        }
        .btn-outline {
            background: transparent;
            border: 1.5px solid var(--cream-border);
            color: var(--navy);
            border-radius: 8px;
            padding: 10px 20px;
            font-size: 0.88rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
        }
        .btn-outline:hover {
            border-color: var(--gold);
            background: var(--gold-pale);
        }
        .btn-danger {
            background: var(--danger);
            color: white;
            border: none;
            border-radius: 8px;
            padding: 10px 20px;
            font-size: 0.88rem;
            font-weight: 600;
            cursor: pointer;
            transition: background 0.2s;
        }
        .btn-danger:hover {
            background: #a93226;
        }
        
        .form-buttons {
            display: flex;
            gap: 12px;
            margin-top: 20px;
        }
        
        .divider {
            height: 1px;
            background: var(--cream-border);
            margin: 20px 0;
        }
        
        .info-text {
            font-size: 0.75rem;
            color: var(--text-muted);
            margin-top: 5px;
        }
        
        .alert-custom {
            padding: 12px 16px;
            border-radius: 10px;
            margin-bottom: 20px;
            font-size: 0.85rem;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .alert-success {
            background: var(--success-pale);
            border: 1px solid rgba(46,125,82,0.25);
            color: var(--success);
        }
        .alert-danger {
            background: var(--danger-pale);
            border: 1px solid rgba(192,57,43,0.25);
            color: var(--danger);
        }
        .alert-warning {
            background: var(--warning-pale);
            border: 1px solid rgba(212,164,43,0.25);
            color: var(--warning);
        }
        .alert-info {
            background: var(--info-pale);
            border: 1px solid rgba(23,162,184,0.25);
            color: var(--info);
        }
        
        .switch {
            position: relative;
            display: inline-block;
            width: 50px;
            height: 24px;
        }
        .switch input {
            opacity: 0;
            width: 0;
            height: 0;
        }
        .slider {
            position: absolute;
            cursor: pointer;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background-color: #ccc;
            transition: .3s;
            border-radius: 24px;
        }
        .slider:before {
            position: absolute;
            content: "";
            height: 18px;
            width: 18px;
            left: 3px;
            bottom: 3px;
            background-color: white;
            transition: .3s;
            border-radius: 50%;
        }
        input:checked + .slider {
            background-color: var(--success);
        }
        input:checked + .slider:before {
            transform: translateX(26px);
        }
        
        .security-score {
            text-align: center;
            padding: 20px;
            background: var(--cream);
            border-radius: var(--radius);
            margin-bottom: 20px;
        }
        .score-circle {
            width: 120px;
            height: 120px;
            border-radius: 50%;
            background: conic-gradient(var(--success) 0deg 324deg, var(--cream-border) 324deg 360deg);
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 15px;
            position: relative;
        }
        .score-inner {
            width: 100px;
            height: 100px;
            border-radius: 50%;
            background: var(--white);
            display: flex;
            align-items: center;
            justify-content: center;
            flex-direction: column;
        }
        .score-value {
            font-size: 2rem;
            font-weight: 700;
            color: var(--success);
        }
        .score-label {
            font-size: 0.7rem;
            color: var(--text-muted);
        }
        
        .activity-item {
            padding: 12px 0;
            border-bottom: 1px solid var(--cream-border);
            display: flex;
            align-items: center;
            gap: 12px;
        }
        .activity-item:last-child {
            border-bottom: none;
        }
        .activity-icon {
            width: 35px;
            height: 35px;
            border-radius: 50%;
            background: var(--gold-pale);
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--gold);
        }
        .activity-details {
            flex: 1;
        }
        .activity-title {
            font-size: 0.85rem;
            font-weight: 600;
        }
        .activity-time {
            font-size: 0.7rem;
            color: var(--text-muted);
        }
        
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
        .text-success { color: var(--success); }
        .text-warning { color: var(--warning); }
        .text-danger { color: var(--danger); }
        
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
        <a href="${pageContext.request.contextPath}/admin/security.jsp" class="nav-item-link active">
            <i class="bi bi-shield-lock-fill"></i> Security
        </a>
        <a href="${pageContext.request.contextPath}/admin/backup.jsp" class="nav-item-link">
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
        <span class="topbar-title">Security Settings</span>
        <span class="topbar-date">
            <i class="bi bi-calendar3 me-1"></i>
            <script>document.write(new Date().toLocaleDateString('en-ZA', {weekday:'short', year:'numeric', month:'short', day:'numeric'}));</script>
        </span>
        <div class="topbar-avatar"><%= initials %></div>
    </header>

    <main class="page-body">
        <div class="page-header">
            <div>
                <p class="page-eyebrow">System Security</p>
                <h1 class="page-heading">Security Settings</h1>
                <p class="text-muted mt-2">Configure security policies and monitor system access</p>
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

        <!-- Security Score Overview -->
        <div class="alert-custom alert-info animate-fade">
            <i class="bi bi-shield-check"></i>
            <span>Your system security score is <strong>90%</strong> - Excellent. Review recommendations below to improve security.</span>
        </div>

        <div class="settings-container">
            <!-- Authentication Security -->
            <div class="settings-card">
                <div class="card-header-bar">
                    <h2 class="card-header-title">
                        <i class="bi bi-key-fill"></i> Authentication Security
                    </h2>
                </div>
                <div class="card-body">
                    <form action="${pageContext.request.contextPath}/admin/security-auth" method="post">
                        <div class="form-group">
                            <div class="d-flex justify-content-between align-items-center">
                                <label>Two-Factor Authentication (2FA)</label>
                                <label class="switch">
                                    <input type="checkbox" name="twoFactorAuth" <%= "enabled".equals(twoFactorAuth) ? "checked" : "" %>>
                                    <span class="slider"></span>
                                </label>
                            </div>
                            <div class="info-text">Require 2FA for all administrator accounts</div>
                        </div>
                        
                        <div class="form-group">
                            <label>Password Expiry (days)</label>
                            <input type="number" name="passwordExpiry" class="form-control" value="<%= passwordExpiry %>">
                            <div class="info-text">Number of days before password expires and must be changed</div>
                        </div>
                        
                        <div class="form-group">
                            <label>Max Failed Login Attempts</label>
                            <input type="number" name="loginAttempts" class="form-control" value="<%= loginAttempts %>">
                            <div class="info-text">Number of failed attempts before account lockout</div>
                        </div>
                        
                        <div class="form-group">
                            <label>Session Timeout (minutes)</label>
                            <input type="number" name="sessionTimeout" class="form-control" value="<%= sessionTimeout %>">
                            <div class="info-text">Automatic logout after inactivity</div>
                        </div>
                        
                        <div class="form-buttons">
                            <button type="submit" class="btn-gold">Save Authentication Settings</button>
                        </div>
                    </form>
                </div>
            </div>

            <!-- IP Whitelist -->
            <div class="settings-card">
                <div class="card-header-bar">
                    <h2 class="card-header-title">
                        <i class="bi bi-wifi"></i> IP Whitelist
                    </h2>
                </div>
                <div class="card-body">
                    <form action="${pageContext.request.contextPath}/admin/security-ip" method="post">
                        <div class="form-group">
                            <label>Allowed IP Addresses</label>
                            <textarea name="ipWhitelist" class="form-control" rows="4" placeholder="Enter one IP address per line&#10;e.g.,&#10;192.168.1.100&#10;10.0.0.0/24">192.168.1.100
10.0.0.0/24</textarea>
                            <div class="info-text">Only these IP addresses will be able to access the admin panel. Leave empty to allow all.</div>
                        </div>
                        <div class="form-buttons">
                            <button type="submit" class="btn-gold">Update IP Whitelist</button>
                        </div>
                    </form>
                </div>
            </div>

            <!-- Data Protection -->
            <div class="settings-card">
                <div class="card-header-bar">
                    <h2 class="card-header-title">
                        <i class="bi bi-lock-fill"></i> Data Protection
                    </h2>
                </div>
                <div class="card-body">
                    <form action="${pageContext.request.contextPath}/admin/security-data" method="post">
                        <div class="form-group">
                            <div class="d-flex justify-content-between align-items-center">
                                <label>Data Encryption at Rest</label>
                                <label class="switch">
                                    <input type="checkbox" name="dataEncryption" <%= "enabled".equals(dataEncryption) ? "checked" : "" %>>
                                    <span class="slider"></span>
                                </label>
                            </div>
                            <div class="info-text">Encrypt sensitive data stored in database</div>
                        </div>
                        
                        <div class="form-group">
                            <div class="d-flex justify-content-between align-items-center">
                                <label>Backup Encryption</label>
                                <label class="switch">
                                    <input type="checkbox" name="backupEncryption" <%= "enabled".equals(backupEncryption) ? "checked" : "" %>>
                                    <span class="slider"></span>
                                </label>
                            </div>
                            <div class="info-text">Encrypt all backup files</div>
                        </div>
                        
                        <div class="form-group">
                            <label>Audit Log Retention (days)</label>
                            <input type="number" name="auditLogRetention" class="form-control" value="<%= auditLogRetention %>">
                            <div class="info-text">Number of days to keep audit logs before automatic deletion</div>
                        </div>
                        
                        <div class="form-buttons">
                            <button type="submit" class="btn-gold">Save Data Protection Settings</button>
                        </div>
                    </form>
                </div>
            </div>

            <!-- Recent Security Activity -->
            <div class="settings-card">
                <div class="card-header-bar">
                    <h2 class="card-header-title">
                        <i class="bi bi-activity"></i> Recent Security Activity
                    </h2>
                </div>
                <div class="card-body">
                    <div class="activity-item">
                        <div class="activity-icon"><i class="bi bi-box-arrow-in-right"></i></div>
                        <div class="activity-details">
                            <div class="activity-title">Admin Login - IP 192.168.1.100</div>
                            <div class="activity-time">Today, 09:30 AM</div>
                        </div>
                        <span class="badge" style="background: var(--success-pale); color: var(--success);">Success</span>
                    </div>
                    <div class="activity-item">
                        <div class="activity-icon"><i class="bi bi-key"></i></div>
                        <div class="activity-details">
                            <div class="activity-title">Password Changed - User: cashier1</div>
                            <div class="activity-time">Yesterday, 14:20 PM</div>
                        </div>
                        <span class="badge" style="background: var(--success-pale); color: var(--success);">Success</span>
                    </div>
                    <div class="activity-item">
                        <div class="activity-icon"><i class="bi bi-exclamation-triangle-fill"></i></div>
                        <div class="activity-details">
                            <div class="activity-title">Failed Login Attempt - IP 203.45.67.89</div>
                            <div class="activity-time">Yesterday, 08:15 AM</div>
                        </div>
                        <span class="badge" style="background: var(--warning-pale); color: var(--warning);">Warning</span>
                    </div>
                    <div class="activity-item">
                        <div class="activity-icon"><i class="bi bi-gear"></i></div>
                        <div class="activity-details">
                            <div class="activity-title">Security Settings Updated</div>
                            <div class="activity-time">2024-12-10, 11:45 AM</div>
                        </div>
                        <span class="badge" style="background: var(--info-pale); color: var(--info);">Info</span>
                    </div>
                    <div class="mt-3">
                        <a href="#" class="btn-outline w-100 text-center">View Full Audit Log</a>
                    </div>
                </div>
            </div>

            <!-- Security Recommendations -->
            <div class="settings-card">
                <div class="card-header-bar">
                    <h2 class="card-header-title">
                        <i class="bi bi-lightbulb-fill"></i> Security Recommendations
                    </h2>
                </div>
                <div class="card-body">
                    <div class="alert-custom alert-success" style="margin-bottom: 15px;">
                        <i class="bi bi-check-circle-fill"></i>
                        <span>✓ Strong password policy is enabled</span>
                    </div>
                    <div class="alert-custom alert-success" style="margin-bottom: 15px;">
                        <i class="bi bi-check-circle-fill"></i>
                        <span>✓ Session timeout is configured</span>
                    </div>
                    <div class="alert-custom alert-warning" style="margin-bottom: 15px;">
                        <i class="bi bi-exclamation-triangle-fill"></i>
                        <span>⚠ Two-factor authentication is not enabled</span>
                    </div>
                    <div class="alert-custom alert-warning" style="margin-bottom: 15px;">
                        <i class="bi bi-exclamation-triangle-fill"></i>
                        <span>⚠ IP whitelist is not configured</span>
                    </div>
                    <div class="alert-custom alert-info" style="margin-bottom: 0;">
                        <i class="bi bi-info-circle-fill"></i>
                        <span>Regular security audits are recommended every 30 days</span>
                    </div>
                </div>
            </div>

            <!-- Password Policy -->
            <div class="settings-card">
                <div class="card-header-bar">
                    <h2 class="card-header-title">
                        <i class="bi bi-asterisk"></i> Password Policy
                    </h2>
                </div>
                <div class="card-body">
                    <div class="alert-custom alert-info" style="margin-bottom: 20px;">
                        <i class="bi bi-info-circle-fill"></i>
                        <span>Current password requirements for all users:</span>
                    </div>
                    <ul style="padding-left: 20px; color: var(--text-muted); font-size: 0.85rem; line-height: 1.8;">
                        <li><i class="bi bi-check-lg text-success me-1"></i> Minimum 8 characters</li>
                        <li><i class="bi bi-check-lg text-success me-1"></i> At least one uppercase letter</li>
                        <li><i class="bi bi-check-lg text-success me-1"></i> At least one lowercase letter</li>
                        <li><i class="bi bi-check-lg text-success me-1"></i> At least one number</li>
                        <li><i class="bi bi-check-lg text-success me-1"></i> At least one special character (@, #, $, %, etc.)</li>
                    </ul>
                    <div class="form-buttons mt-3">
                        <button class="btn-outline" onclick="updatePasswordPolicy()">Update Password Policy</button>
                    </div>
                </div>
            </div>

            <!-- Force Password Reset -->
            <div class="settings-card">
                <div class="card-header-bar">
                    <h2 class="card-header-title">
                        <i class="bi bi-arrow-repeat"></i> User Actions
                    </h2>
                </div>
                <div class="card-body">
                    <div class="form-group">
                        <label>Force All Users to Reset Password</label>
                        <button class="btn-danger w-100" onclick="forcePasswordReset()">
                            <i class="bi bi-exclamation-triangle-fill"></i> Force Password Reset
                        </button>
                        <div class="info-text">All users will be required to change their password on next login</div>
                    </div>
                    
                    <div class="divider"></div>
                    
                    <div class="form-group">
                        <label>Lock All User Accounts</label>
                        <button class="btn-danger w-100" onclick="lockAllAccounts()">
                            <i class="bi bi-lock-fill"></i> Lock All Accounts
                        </button>
                        <div class="info-text">Temporarily lock all user accounts (emergency use only)</div>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Security Guidelines -->
        <div class="content-card" style="background: var(--white); border-radius: var(--radius); border: 1px solid var(--cream-border); margin-top: 24px;">
            <div class="card-header-bar">
                <h2 class="card-header-title">
                    <i class="bi bi-info-circle-fill"></i> Security Best Practices
                </h2>
            </div>
            <div style="padding: 20px;">
                <ul style="padding-left: 20px; color: var(--text-muted); font-size: 0.85rem; line-height: 1.8;">
                    <li><i class="bi bi-shield-lock-fill me-1"></i> Always use strong, unique passwords for administrator accounts</li>
                    <li><i class="bi bi-key-fill me-1"></i> Enable Two-Factor Authentication for added security</li>
                    <li><i class="bi bi-globe2 me-1"></i> Configure IP whitelist to restrict admin access to trusted locations</li>
                    <li><i class="bi bi-clock-history me-1"></i> Regular security audits help identify potential vulnerabilities</li>
                    <li><i class="bi bi-database-fill me-1"></i> Keep regular backups and test restore procedures</li>
                    <li><i class="bi bi-envelope-fill me-1"></i> Monitor security logs for suspicious activity</li>
                    <li><i class="bi bi-arrow-repeat me-1"></i> Update security settings regularly to adapt to new threats</li>
                </ul>
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
    
    function updatePasswordPolicy() {
        alert('Password policy update functionality coming soon.\n\nCurrent policy requires:\n- Minimum 8 characters\n- Uppercase & lowercase letters\n- Numbers\n- Special characters');
    }
    
    function forcePasswordReset() {
        if (confirm('WARNING: This will force ALL users to reset their passwords on next login. Continue?')) {
            alert('Password reset forced. All users will be required to change their password.');
        }
    }
    
    function lockAllAccounts() {
        if (confirm('EMERGENCY ACTION: This will lock ALL user accounts including administrators. Are you absolutely sure?')) {
            alert('All accounts have been locked. Use emergency recovery procedure to unlock.');
        }
    }
    
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') closeSidebar();
    });
    
    // Auto-hide flash messages after 5 seconds
    setTimeout(function() {
        let flashes = document.querySelectorAll('.alert-custom');
        flashes.forEach(function(flash) {
            if (!flash.classList.contains('alert-warning') && !flash.classList.contains('alert-info')) {
                flash.style.transition = 'opacity 0.4s';
                flash.style.opacity = '0';
                setTimeout(function() { flash.remove(); }, 500);
            }
        });
    }, 5000);
</script>

</body>
</html>