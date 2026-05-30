<%-- web/admin/settings.jsp --%>
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
    
    // Get current system settings (sample data - replace with actual settings from database)
    String systemName = "Mpeoa Supermarket ERP";
    String systemEmail = "admin@mpeoa.com";
    String systemPhone = "+26659436321";
    String systemAddress = "Maseru, Naleli";
    String taxRate = "15";
    String currency = "ZAR";
    String dateFormat = "dd/MM/yyyy";
    String timezone = "Africa/Maseru";
    String lowStockAlert = "10";
    String autoBackup = "true";
    String sessionTimeout = "30";
    
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
    <title>System Settings — Mpeoa Supermarket ERP</title>
    
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
        .text-success { color: var(--success); }
        .text-warning { color: var(--warning); }
        
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
        <a href="${pageContext.request.contextPath}/admin/settings.jsp" class="nav-item-link active">
            <i class="bi bi-gear-fill"></i> Settings
        </a>
        <a href="${pageContext.request.contextPath}/admin/security.jsp" class="nav-item-link">
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
        <span class="topbar-title">System Settings</span>
        <span class="topbar-date">
            <i class="bi bi-calendar3 me-1"></i>
            <script>document.write(new Date().toLocaleDateString('en-ZA', {weekday:'short', year:'numeric', month:'short', day:'numeric'}));</script>
        </span>
        <div class="topbar-avatar"><%= initials %></div>
    </header>

    <main class="page-body">
        <div class="page-header">
            <div>
                <p class="page-eyebrow">System Administration</p>
                <h1 class="page-heading">Settings</h1>
                <p class="text-muted mt-2">Configure system preferences and business information</p>
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

        <div class="settings-container">
            <!-- General Settings -->
            <div class="settings-card">
                <div class="card-header-bar">
                    <h2 class="card-header-title">
                        <i class="bi bi-building"></i> General Settings
                    </h2>
                </div>
                <div class="card-body">
                    <form action="${pageContext.request.contextPath}/admin/settings-general" method="post">
                        <div class="form-group">
                            <label>System Name</label>
                            <input type="text" name="systemName" class="form-control" value="<%= systemName %>">
                        </div>
                        <div class="form-group">
                            <label>System Email</label>
                            <input type="email" name="systemEmail" class="form-control" value="<%= systemEmail %>">
                        </div>
                        <div class="form-group">
                            <label>Phone Number</label>
                            <input type="tel" name="systemPhone" class="form-control" value="<%= systemPhone %>">
                        </div>
                        <div class="form-group">
                            <label>Business Address</label>
                            <textarea name="systemAddress" class="form-control" rows="3"><%= systemAddress %></textarea>
                        </div>
                        <div class="form-buttons">
                            <button type="submit" class="btn-gold">Save Changes</button>
                        </div>
                    </form>
                </div>
            </div>

            <!-- Financial Settings -->
            <div class="settings-card">
                <div class="card-header-bar">
                    <h2 class="card-header-title">
                        <i class="bi bi-currency-exchange"></i> Financial Settings
                    </h2>
                </div>
                <div class="card-body">
                    <form action="${pageContext.request.contextPath}/admin/settings-financial" method="post">
                        <div class="form-group">
                            <label>Tax Rate (%)</label>
                            <input type="number" step="0.01" name="taxRate" class="form-control" value="<%= taxRate %>">
                            <div class="info-text">Default VAT / Sales tax rate applied to all transactions</div>
                        </div>
                        <div class="form-group">
                            <label>Currency</label>
                            <select name="currency" class="form-select">
                                <option value="ZAR" <%= "ZAR".equals(currency) ? "selected" : "" %>>South African Rand (ZAR)</option>
                                <option value="USD" <%= "USD".equals(currency) ? "selected" : "" %>>US Dollar (USD)</option>
                                <option value="EUR" <%= "EUR".equals(currency) ? "selected" : "" %>>Euro (EUR)</option>
                                <option value="GBP" <%= "GBP".equals(currency) ? "selected" : "" %>>British Pound (GBP)</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label>Low Stock Alert Threshold</label>
                            <input type="number" name="lowStockAlert" class="form-control" value="<%= lowStockAlert %>">
                            <div class="info-text">Number of units before triggering low stock alert</div>
                        </div>
                        <div class="form-buttons">
                            <button type="submit" class="btn-gold">Save Changes</button>
                        </div>
                    </form>
                </div>
            </div>

            <!-- Regional Settings -->
            <div class="settings-card">
                <div class="card-header-bar">
                    <h2 class="card-header-title">
                        <i class="bi bi-globe2"></i> Regional Settings
                    </h2>
                </div>
                <div class="card-body">
                    <form action="${pageContext.request.contextPath}/admin/settings-regional" method="post">
                        <div class="form-group">
                            <label>Date Format</label>
                            <select name="dateFormat" class="form-select">
                                <option value="dd/MM/yyyy" <%= "dd/MM/yyyy".equals(dateFormat) ? "selected" : "" %>>DD/MM/YYYY</option>
                                <option value="MM/dd/yyyy" <%= "MM/dd/yyyy".equals(dateFormat) ? "selected" : "" %>>MM/DD/YYYY</option>
                                <option value="yyyy-MM-dd" <%= "yyyy-MM-dd".equals(dateFormat) ? "selected" : "" %>>YYYY-MM-DD</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label>Time Zone</label>
                            <select name="timezone" class="form-select">
                                <option value="Africa/Maseru" <%= "Africa/Maseru".equals(timezone) ? "selected" : "" %>>Lesotho Standard Time</option>
                                <option value="Africa/Johannesburg" <%= "Africa/Johannesburg".equals(timezone) ? "selected" : "" %>>South Africa Standard Time</option>
                                <option value="UTC">UTC</option>
                                <option value="America/New_York">Eastern Time</option>
                                <option value="Europe/London">GMT (London)</option>
                            </select>
                        </div>
                        <div class="form-buttons">
                            <button type="submit" class="btn-gold">Save Changes</button>
                        </div>
                    </form>
                </div>
            </div>

            <!-- Security Settings -->
            <div class="settings-card">
                <div class="card-header-bar">
                    <h2 class="card-header-title">
                        <i class="bi bi-shield-lock-fill"></i> Security Settings
                    </h2>
                </div>
                <div class="card-body">
                    <form action="${pageContext.request.contextPath}/admin/settings-security" method="post">
                        <div class="form-group">
                            <label>Session Timeout (minutes)</label>
                            <input type="number" name="sessionTimeout" class="form-control" value="<%= sessionTimeout %>">
                            <div class="info-text">Time before automatic logout due to inactivity</div>
                        </div>
                        <div class="form-group">
                            <div class="d-flex justify-content-between align-items-center">
                                <label>Auto Backup</label>
                                <label class="switch">
                                    <input type="checkbox" name="autoBackup" <%= "true".equals(autoBackup) ? "checked" : "" %>>
                                    <span class="slider"></span>
                                </label>
                            </div>
                            <div class="info-text">Automatically backup database daily</div>
                        </div>
                        <div class="form-buttons">
                            <button type="submit" class="btn-gold">Save Changes</button>
                        </div>
                    </form>
                </div>
            </div>

            <!-- System Actions -->
            <div class="settings-card">
                <div class="card-header-bar">
                    <h2 class="card-header-title">
                        <i class="bi bi-tools"></i> System Actions
                    </h2>
                </div>
                <div class="card-body">
                    <div class="alert-custom alert-warning" style="margin-bottom: 20px;">
                        <i class="bi bi-exclamation-triangle-fill"></i>
                        <span>These actions can affect system functionality. Use with caution.</span>
                    </div>
                    
                    <div class="form-group">
                        <label>Clear System Cache</label>
                        <button class="btn-outline w-100" onclick="clearCache()">
                            <i class="bi bi-arrow-repeat"></i> Clear Cache
                        </button>
                        <div class="info-text">Clear temporary system data and refresh configurations</div>
                    </div>
                    
                    <div class="divider"></div>
                    
                    <div class="form-group">
                        <label>Export System Data</label>
                        <button class="btn-outline w-100" onclick="exportData()">
                            <i class="bi bi-download"></i> Export All Data
                        </button>
                        <div class="info-text">Export all system data to CSV/Excel format</div>
                    </div>
                    
                    <div class="divider"></div>
                    
                    <div class="form-group">
                        <label>System Maintenance Mode</label>
                        <button class="btn-warning w-100" style="background: var(--warning); border: none; padding: 10px; border-radius: 8px;" onclick="maintenanceMode()">
                            <i class="bi bi-gear"></i> Enable Maintenance Mode
                        </button>
                        <div class="info-text">Temporarily restrict user access for maintenance</div>
                    </div>
                </div>
            </div>

            <!-- About -->
            <div class="settings-card">
                <div class="card-header-bar">
                    <h2 class="card-header-title">
                        <i class="bi bi-info-circle-fill"></i> About
                    </h2>
                </div>
                <div class="card-body">
                    <div class="text-center mb-3">
                        <i class="bi bi-shop" style="font-size: 3rem; color: var(--gold);"></i>
                    </div>
                    <h5 class="text-center mb-2" style="font-family: var(--font-display);">Mpeoa Supermarket ERP</h5>
                    <p class="text-center text-muted small">Version 1.0.0</p>
                    <div class="divider"></div>
                    <div class="info-text">
                        <strong>© 2024 Mpeoa Supermarket</strong><br>
                        Complete Enterprise Resource Planning System<br>
                        Built with Java Enterprise Edition<br>
                        GlassFish Server 6.2.5 | MySQL Database
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
    
    function clearCache() {
        if (confirm('Are you sure you want to clear the system cache? This may temporarily slow down the system.')) {
            alert('Cache cleared successfully!');
        }
    }
    
    function exportData() {
        alert('Data export functionality will be available soon.\n\nYou will be able to export all system data to CSV/Excel format.');
    }
    
    function maintenanceMode() {
        if (confirm('WARNING: Enabling maintenance mode will restrict user access. Are you sure?')) {
            alert('Maintenance mode enabled. Users will be notified.');
        }
    }
    
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') closeSidebar();
    });
    
    // Auto-hide flash messages after 5 seconds
    setTimeout(function() {
        let flashes = document.querySelectorAll('.alert-custom');
        flashes.forEach(function(flash) {
            if (!flash.classList.contains('alert-warning')) {
                flash.style.transition = 'opacity 0.4s';
                flash.style.opacity = '0';
                setTimeout(function() { flash.remove(); }, 500);
            }
        });
    }, 5000);
</script>

</body>
</html>