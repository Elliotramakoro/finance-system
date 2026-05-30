<%-- web/admin/expenses.jsp --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="mpeoa.models.User, mpeoa.dao.ExpenseDAO, mpeoa.models.Expense, java.util.*, java.text.*, java.math.BigDecimal" %>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !"Administrator".equalsIgnoreCase(loggedInUser.getRoleName())) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    
    ExpenseDAO expenseDAO = new ExpenseDAO();
    List<Expense> expenses = expenseDAO.getAllExpenses();
    
    String success = request.getParameter("success");
    String error = request.getParameter("error");
    
    DecimalFormat df = new DecimalFormat("#,##0.00");
    
    // Role-based permissions
    String userRole = loggedInUser.getRoleName();
    boolean canRecordExpense = "Administrator".equalsIgnoreCase(userRole) || 
                               "Accountant".equalsIgnoreCase(userRole) || 
                               "Manager".equalsIgnoreCase(userRole);
    
    boolean canApproveExpense = "Administrator".equalsIgnoreCase(userRole) || 
                                "Manager".equalsIgnoreCase(userRole);
    
    // Calculate totals
    BigDecimal totalExpenses = BigDecimal.ZERO;
    BigDecimal pendingExpenses = BigDecimal.ZERO;
    BigDecimal approvedExpenses = BigDecimal.ZERO;
    
    for (Expense expense : expenses) {
        if (expense.getAmount() != null) {
            totalExpenses = totalExpenses.add(expense.getAmount());
            if ("Approved".equalsIgnoreCase(expense.getStatus())) {
                approvedExpenses = approvedExpenses.add(expense.getAmount());
            } else if ("Pending".equalsIgnoreCase(expense.getStatus())) {
                pendingExpenses = pendingExpenses.add(expense.getAmount());
            }
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
    <title>Expense Management — Mpeoa Supermarket ERP</title>
    
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

        /* Role Badge */
        .role-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.7rem;
            font-weight: 600;
            margin-left: 10px;
        }
        .role-admin { background: var(--navy); color: var(--gold-light); }
        .role-manager { background: var(--navy-mid); color: white; }
        .role-accountant { background: var(--gold-pale); color: var(--gold); }

        /* Stat Cards */
        .stat-card {
            background: var(--white);
            border-radius: var(--radius);
            padding: 20px;
            border: 1px solid var(--cream-border);
            transition: transform 0.2s, box-shadow 0.2s;
            height: 100%;
        }
        .stat-card:hover {
            transform: translateY(-3px);
            box-shadow: var(--shadow-md);
        }
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
        .stat-value {
            font-family: var(--font-display);
            font-size: 1.5rem;
            font-weight: 700;
            margin-bottom: 4px;
            color: var(--navy);
        }
        .stat-label { font-size: 0.75rem; color: var(--text-muted); }
        .stat-sub {
            font-size: 0.7rem;
            color: var(--text-muted);
            margin-top: 5px;
        }

        /* Add Expense Form */
        .add-expense-form {
            padding: 20px;
            background: var(--white);
            border-bottom: 1px solid var(--cream-border);
        }
        .form-row {
            display: flex;
            gap: 20px;
            flex-wrap: wrap;
        }
        .form-group {
            flex: 1;
            min-width: 180px;
            margin-bottom: 20px;
        }
        .form-group label {
            font-size: 0.7rem;
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
        .form-buttons {
            display: flex;
            gap: 12px;
            align-items: center;
            margin-top: 20px;
        }

        /* Content Cards */
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
        .btn-sm-outline:hover {
            border-color: var(--gold);
            background: var(--gold-pale);
            color: var(--gold);
        }
        .btn-sm-success {
            background: var(--success);
            color: white;
            border: none;
            border-radius: 6px;
            padding: 5px 12px;
            font-size: 0.7rem;
            cursor: pointer;
            transition: background 0.2s;
        }
        .btn-sm-success:hover {
            background: #1e5a3e;
        }
        .btn-sm-danger {
            background: var(--danger);
            color: white;
            border: none;
            border-radius: 6px;
            padding: 5px 12px;
            font-size: 0.7rem;
            cursor: pointer;
            transition: background 0.2s;
        }
        .btn-sm-danger:hover {
            background: #a93226;
        }

        /* Tables */
        .table-responsive { overflow-x: auto; }
        .data-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 0.8rem;
        }
        .data-table thead th {
            background: var(--cream);
            padding: 12px 16px;
            text-align: left;
            font-size: 0.7rem;
            font-weight: 600;
            text-transform: uppercase;
            color: var(--navy);
            border-bottom: 1px solid var(--cream-border);
        }
        .data-table tbody td {
            padding: 12px 16px;
            border-bottom: 1px solid var(--cream-border);
            color: var(--navy);
        }
        .data-table tbody tr:hover {
            background: var(--cream);
        }

        /* Badges */
        .badge-approved {
            background: var(--success-pale);
            color: var(--success);
            padding: 4px 8px;
            border-radius: 12px;
            font-size: 0.65rem;
            font-weight: 600;
        }
        .badge-pending {
            background: var(--warning-pale);
            color: var(--warning);
            padding: 4px 8px;
            border-radius: 12px;
            font-size: 0.65rem;
            font-weight: 600;
        }
        .badge-rejected {
            background: var(--danger-pale);
            color: var(--danger);
            padding: 4px 8px;
            border-radius: 12px;
            font-size: 0.65rem;
            font-weight: 600;
        }

        /* Empty State */
        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: var(--text-muted);
        }
        .empty-state i {
            font-size: 4rem;
            margin-bottom: 20px;
            opacity: 0.3;
            color: var(--gold);
        }
        .empty-state h4 {
            font-family: var(--font-display);
            font-size: 1.3rem;
            margin-bottom: 10px;
            color: var(--navy);
        }

        /* Alerts */
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
        .alert-info {
            background: var(--info-pale);
            border: 1px solid rgba(23,162,184,0.25);
            color: var(--info);
        }

        /* Modal */
        .modal-content {
            border-radius: var(--radius);
        }
        .modal-header {
            background: var(--cream);
            border-bottom: 1px solid var(--cream-border);
        }
        .modal-footer {
            background: var(--cream);
            border-top: 1px solid var(--cream-border);
        }

        /* Utilities */
        .d-flex { display: flex; }
        .align-items-center { align-items: center; }
        .justify-content-between { justify-content: space-between; }
        .gap-2 { gap: 8px; }
        .gap-3 { gap: 16px; }
        .mb-4 { margin-bottom: 24px; }
        .mt-2 { margin-top: 8px; }
        .mt-4 { margin-top: 24px; }
        .fw-bold { font-weight: 700; }
        .text-center { text-align: center; }
        .text-success { color: var(--success); }
        .text-warning { color: var(--warning); }
        .me-1 { margin-right: 4px; }
        
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
        <a href="${pageContext.request.contextPath}/admin/expenses.jsp" class="nav-item-link active">
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
        <a href="${pageContext.request.contextPath}/admin/backup.jsp" class="nav-item-link">
            <i class="bi bi-database-fill"></i> Backup & Recovery
        </a>
    </nav>
    <div class="sidebar-footer">
        <div class="sidebar-avatar"><%= initials %></div>
        <div>
            <div class="sidebar-admin-name"><%= adminName != null ? adminName : "Administrator" %></div>
            <div class="sidebar-admin-role">
                <%= userRole %>
                <% if ("Accountant".equalsIgnoreCase(userRole)) { %>
                    <span class="role-badge role-accountant">Can Record Only</span>
                <% } else if ("Manager".equalsIgnoreCase(userRole)) { %>
                    <span class="role-badge role-manager">Can Record & Approve</span>
                <% } else if ("Administrator".equalsIgnoreCase(userRole)) { %>
                    <span class="role-badge role-admin">Full Access</span>
                <% } %>
            </div>
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
        <span class="topbar-title">Expense Management</span>
        <span class="topbar-date">
            <i class="bi bi-calendar3 me-1"></i>
            <script>document.write(new Date().toLocaleDateString('en-ZA', {weekday:'short', year:'numeric', month:'short', day:'numeric'}));</script>
        </span>
        <div class="topbar-avatar"><%= initials %></div>
    </header>

    <main class="page-body">
        <div class="page-header">
            <div>
                <p class="page-eyebrow">Financial Management</p>
                <h1 class="page-heading">Expenses</h1>
                <p class="text-muted mt-2">Track and manage all business expenses</p>
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

        <!-- Role Information Alert -->
        <% if ("Accountant".equalsIgnoreCase(userRole)) { %>
            <div class="alert-custom alert-info animate-fade">
                <i class="bi bi-info-circle-fill"></i>
                <span>As an Accountant, you can record expenses. They will need to be approved by a Manager.</span>
            </div>
        <% } else if ("Manager".equalsIgnoreCase(userRole)) { %>
            <div class="alert-custom alert-info animate-fade">
                <i class="bi bi-info-circle-fill"></i>
                <span>As a Manager, you can record AND approve expenses.</span>
            </div>
        <% } %>

        <!-- Statistics Cards -->
        <div class="row g-3 mb-4">
            <div class="col-md-4">
                <div class="stat-card animate-fade">
                    <div class="stat-icon"><i class="bi bi-calculator-fill"></i></div>
                    <div class="stat-value">R <%= df.format(totalExpenses) %></div>
                    <div class="stat-label">Total Expenses</div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="stat-card animate-fade">
                    <div class="stat-icon"><i class="bi bi-check-circle-fill"></i></div>
                    <div class="stat-value">R <%= df.format(approvedExpenses) %></div>
                    <div class="stat-label">Approved Expenses</div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="stat-card animate-fade">
                    <div class="stat-icon"><i class="bi bi-clock-fill"></i></div>
                    <div class="stat-value">R <%= df.format(pendingExpenses) %></div>
                    <div class="stat-label">Pending Approval</div>
                    <% if (pendingExpenses.compareTo(BigDecimal.ZERO) > 0 && canApproveExpense) { %>
                        <div class="stat-sub text-warning">Awaiting your approval</div>
                    <% } %>
                </div>
            </div>
        </div>

        <!-- Add Expense Form - Only for users who can record expenses -->
        <% if (canRecordExpense) { %>
            <div class="content-card">
                <div class="card-header-bar">
                    <h2 class="card-header-title">
                        <i class="bi bi-plus-circle-fill"></i> Record New Expense
                    </h2>
                </div>
                <div class="add-expense-form">
                    <form action="${pageContext.request.contextPath}/admin/expense-add" method="post">
                        <div class="form-row">
                            <div class="form-group">
                                <label>Category</label>
                                <select name="expenseCategory" class="form-select" required>
                                    <option value="">Select Category</option>
                                    <option value="Utilities">Utilities (Electricity, Water)</option>
                                    <option value="Rent">Rent / Lease</option>
                                    <option value="Salaries">Salaries & Wages</option>
                                    <option value="Supplies">Office / Store Supplies</option>
                                    <option value="Maintenance">Maintenance & Repairs</option>
                                    <option value="Marketing">Marketing & Advertising</option>
                                    <option value="Transport">Transport & Logistics</option>
                                    <option value="Other">Other Expenses</option>
                                </select>
                            </div>
                            <div class="form-group">
                                <label>Amount (R)</label>
                                <input type="number" step="0.01" name="amount" class="form-control" placeholder="0.00" required>
                            </div>
                            <div class="form-group">
                                <label>Expense Date</label>
                                <input type="date" name="expenseDate" class="form-control" required>
                            </div>
                            <div class="form-group">
                                <label>Payment Method</label>
                                <select name="paymentMethod" class="form-select">
                                    <option value="Cash">Cash</option>
                                    <option value="Bank Transfer">Bank Transfer</option>
                                    <option value="Credit Card">Credit Card</option>
                                    <option value="Cheque">Cheque</option>
                                </select>
                            </div>
                        </div>
                        <div class="form-row">
                            <div class="form-group" style="flex: 2;">
                                <label>Description</label>
                                <textarea name="description" class="form-control" rows="2" placeholder="Describe the expense..."></textarea>
                            </div>
                            <div class="form-group">
                                <label>Receipt Number</label>
                                <input type="text" name="receiptNumber" class="form-control" placeholder="Receipt / Reference #">
                            </div>
                            <div class="form-group" style="flex: 0;">
                                <div class="form-buttons">
                                    <button type="submit" class="btn-gold">
                                        <i class="bi bi-check-lg"></i> Record Expense
                                    </button>
                                    <button type="reset" class="btn-outline">
                                        <i class="bi bi-arrow-repeat"></i> Clear
                                    </button>
                                </div>
                            </div>
                        </div>
                    </form>
                </div>
            </div>
        <% } %>

        <!-- Expenses Table -->
        <div class="content-card">
            <div class="card-header-bar">
                <h2 class="card-header-title">
                    <i class="bi bi-list-ul"></i> Expense History
                </h2>
                <span class="btn-sm-outline">Total: <%= expenses.size() %> records</span>
            </div>
            <div class="table-responsive">
                <% if (expenses != null && !expenses.isEmpty()) { %>
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Date</th>
                                <th>Category</th>
                                <th>Description</th>
                                <th>Amount</th>
                                <th>Payment Method</th>
                                <th>Recorded By</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </thead>
                        <tbody>
                            <% for (Expense expense : expenses) { %>
                                <tr>
                                    <td><%= expense.getExpenseDate() != null ? expense.getExpenseDate() : "-" %></td>
                                    <td><strong><%= expense.getExpenseCategory() %></strong></td>
                                    <td><%= expense.getDescription() != null && expense.getDescription().length() > 40 ? expense.getDescription().substring(0, 40) + "..." : expense.getDescription() %></td>
                                    <td class="fw-bold">R <%= df.format(expense.getAmount()) %></td>
                                    <td><%= expense.getPaymentMethod() != null ? expense.getPaymentMethod() : "-" %></td>
                                    <td><%= expense.getRecordedByName() != null ? expense.getRecordedByName() : "Staff" %></td>
                                    <td>
                                        <% if ("Approved".equalsIgnoreCase(expense.getStatus())) { %>
                                            <span class="badge-approved">Approved</span>
                                        <% } else if ("Pending".equalsIgnoreCase(expense.getStatus())) { %>
                                            <span class="badge-pending">Pending</span>
                                        <% } else { %>
                                            <span class="badge-rejected"><%= expense.getStatus() %></span>
                                        <% } %>
                                    </td>
                                    <td>
                                        <div class="d-flex gap-2">
                                            <!-- Approve button only visible to Admin and Manager for pending expenses -->
                                            <% if (canApproveExpense && "Pending".equalsIgnoreCase(expense.getStatus())) { %>
                                                <button class="btn-sm-success" onclick="approveExpense(<%= expense.getExpenseId() %>)">
                                                    <i class="bi bi-check-lg"></i> Approve
                                                </button>
                                            <% } %>
                                            <button class="btn-sm-outline" onclick="viewExpense(<%= expense.getExpenseId() %>)">
                                                <i class="bi bi-eye"></i> View
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            <% } %>
                        </tbody>
                    </table>
                <% } else { %>
                    <div class="empty-state">
                        <i class="bi bi-wallet2"></i>
                        <h4>No Expenses Recorded</h4>
                        <p>Record your first expense using the form above.</p>
                    </div>
                <% } %>
            </div>
        </div>
        
        <!-- Guidelines -->
        <div class="content-card">
            <div class="card-header-bar">
                <h2 class="card-header-title">
                    <i class="bi bi-info-circle-fill"></i> Expense Management Guidelines
                </h2>
            </div>
            <div style="padding: 20px;">
                <ul style="padding-left: 20px; color: var(--text-muted); font-size: 0.85rem; line-height: 1.8;">
                    <li><i class="bi bi-receipt me-1"></i> Always keep receipts for all business expenses</li>
                    <li><i class="bi bi-clock-history me-1"></i> Expenses need to be approved by a Manager</li>
                    <li><i class="bi bi-tags-fill me-1"></i> Categorize expenses properly for accurate financial reporting</li>
                    <li><i class="bi bi-calculator-fill me-1"></i> Track expenses to monitor profitability</li>
                    <li><i class="bi bi-graph-up me-1"></i> Regular expense reviews help identify cost-saving opportunities</li>
                    <% if ("Accountant".equalsIgnoreCase(userRole)) { %>
                        <li class="mt-2 text-warning"><i class="bi bi-shield-lock-fill me-1"></i> <strong>Your Role:</strong> You can record expenses, but they require Manager approval.</li>
                    <% } else if ("Manager".equalsIgnoreCase(userRole)) { %>
                        <li class="mt-2 text-success"><i class="bi bi-check-circle-fill me-1"></i> <strong>Your Role:</strong> You can record AND approve expenses.</li>
                    <% } else if ("Administrator".equalsIgnoreCase(userRole)) { %>
                        <li class="mt-2 text-gold"><i class="bi bi-star-fill me-1"></i> <strong>Your Role:</strong> Full access to all expense functions.</li>
                    <% } %>
                </ul>
            </div>
        </div>
    </main>
</div>

<!-- View Expense Modal -->
<div class="modal fade" id="viewExpenseModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" style="font-family: var(--font-display);"><i class="bi bi-receipt"></i> Expense Details</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <div class="row mb-2">
                    <div class="col-4 fw-bold">Category:</div>
                    <div class="col-8" id="viewCategory">-</div>
                </div>
                <div class="row mb-2">
                    <div class="col-4 fw-bold">Amount:</div>
                    <div class="col-8" id="viewAmount">-</div>
                </div>
                <div class="row mb-2">
                    <div class="col-4 fw-bold">Date:</div>
                    <div class="col-8" id="viewDate">-</div>
                </div>
                <div class="row mb-2">
                    <div class="col-4 fw-bold">Payment Method:</div>
                    <div class="col-8" id="viewPaymentMethod">-</div>
                </div>
                <div class="row mb-2">
                    <div class="col-4 fw-bold">Receipt #:</div>
                    <div class="col-8" id="viewReceiptNumber">-</div>
                </div>
                <div class="row mb-2">
                    <div class="col-4 fw-bold">Description:</div>
                    <div class="col-8" id="viewDescription">-</div>
                </div>
                <div class="row mb-2">
                    <div class="col-4 fw-bold">Recorded By:</div>
                    <div class="col-8" id="viewRecordedBy">-</div>
                </div>
                <div class="row mb-2">
                    <div class="col-4 fw-bold">Approved By:</div>
                    <div class="col-8" id="viewApprovedBy">-</div>
                </div>
                <div class="row mb-2">
                    <div class="col-4 fw-bold">Status:</div>
                    <div class="col-8" id="viewStatus">-</div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn-outline" data-bs-dismiss="modal">Close</button>
            </div>
        </div>
    </div>
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
    
    function approveExpense(expenseId) {
        if (confirm('Are you sure you want to approve this expense?')) {
            window.location.href = '${pageContext.request.contextPath}/admin/expense-approve?id=' + expenseId;
        }
    }
    
    function viewExpense(expenseId) {
        // This would typically fetch data via AJAX
        // For now, show a placeholder
        alert('View details for expense ID: ' + expenseId + '\n\nFull details coming soon!');
    }
    
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') closeSidebar();
    });
    
    // Set default date to today
    const today = new Date().toISOString().split('T')[0];
    const dateInput = document.querySelector('input[name="expenseDate"]');
    if (dateInput) {
        dateInput.value = today;
    }
    
    // Auto-hide flash messages after 5 seconds
    setTimeout(function() {
        let flashes = document.querySelectorAll('.alert-custom');
        flashes.forEach(function(flash) {
            flash.style.transition = 'opacity 0.4s';
            flash.style.opacity = '0';
            setTimeout(function() { flash.remove(); }, 500);
        });
    }, 5000);
</script>

</body>
</html>