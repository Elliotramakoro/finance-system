<%-- web/admin/users.jsp --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="mpeoa.models.User, mpeoa.dao.UserDAO, java.util.*, java.text.*" %>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !"Administrator".equalsIgnoreCase(loggedInUser.getRoleName())) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    
    UserDAO userDAO = new UserDAO();
    List<User> users = userDAO.getAllUsers();
    
    String success = request.getParameter("success");
    String error = request.getParameter("error");
    
    // Debug - print to console
    System.out.println("=== User Management Page ===");
    System.out.println("Total users from DAO: " + (users != null ? users.size() : 0));
    if (users != null) {
        for (User u : users) {
            System.out.println("User: " + u.getUsername() + " - Role: " + u.getRoleName() + " - Active: " + u.isIsActive());
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
    <title>User Management — Mpeoa Supermarket ERP</title>
    
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
        .main-wrap { margin-left: var(--sidebar-w); min-height: 100vh; transition: margin-left 0.32s; }
        @media (max-width: 991.98px) { .main-wrap { margin-left: 0; } }

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

        /* Cards */
        .content-card { background: var(--white); border-radius: var(--radius); border: 1px solid var(--cream-border); box-shadow: var(--shadow); overflow: hidden; margin-bottom: 24px; }
        .card-header-bar { padding: 18px 22px; border-bottom: 1px solid var(--cream-border); background: var(--cream); }
        .card-header-title { font-family: var(--font-display); font-size: 1rem; font-weight: 700; color: var(--navy); margin: 0; display: flex; align-items: center; gap: 8px; }
        .card-body { padding: 26px 22px; }

        /* Form */
        .form-group { margin-bottom: 20px; }
        .form-label { display: block; font-size: 0.75rem; font-weight: 600; letter-spacing: 0.05em; text-transform: uppercase; color: var(--navy); margin-bottom: 7px; }
        .form-control, .form-select {
            width: 100%; padding: 10px 14px;
            border: 1.5px solid var(--cream-border); border-radius: 8px;
            font-family: var(--font-body); font-size: 0.88rem; color: var(--navy);
            background: var(--white); outline: none;
            transition: border-color 0.18s, box-shadow 0.18s;
        }
        .form-control:focus, .form-select:focus {
            border-color: var(--gold); box-shadow: 0 0 0 3px var(--gold-pale);
        }
        
        .form-row {
            display: flex;
            gap: 20px;
            flex-wrap: wrap;
        }
        .form-row .form-group {
            flex: 1;
            min-width: 180px;
        }

        /* Buttons */
        .btn-gold { background: var(--gold); color: var(--white); border: none; border-radius: 8px; padding: 10px 24px; font-size: 0.88rem; font-weight: 600; display: inline-flex; align-items: center; gap: 8px; cursor: pointer; transition: background 0.2s; }
        .btn-gold:hover { background: var(--gold-light); }
        .btn-outline { background: transparent; border: 1.5px solid var(--cream-border); color: var(--navy); border-radius: 8px; padding: 10px 20px; font-size: 0.88rem; font-weight: 600; cursor: pointer; transition: all 0.2s; }
        .btn-outline:hover { border-color: var(--gold); background: var(--gold-pale); }
        .form-buttons { display: flex; gap: 12px; margin-top: 24px; }
        
        /* Action Buttons */
        .action-buttons { display: flex; gap: 8px; }
        .action-btn { padding: 4px 12px; border-radius: 6px; text-decoration: none; font-size: 0.75rem; font-weight: 600; transition: all 0.2s; display: inline-flex; align-items: center; gap: 5px; cursor: pointer; border: none; }
        .edit-btn { background: var(--navy); color: white; }
        .edit-btn:hover { background: var(--navy-mid); }
        .delete-btn { background: transparent; color: var(--danger); border: 1px solid var(--danger); }
        .delete-btn:hover { background: var(--danger-pale); }

        /* Table */
        .data-table { width: 100%; border-collapse: collapse; }
        .data-table th { background: var(--cream-dark); padding: 12px 16px; text-align: left; font-size: 0.75rem; font-weight: 600; text-transform: uppercase; color: var(--navy); border-bottom: 1px solid var(--cream-border); }
        .data-table td { padding: 12px 16px; border-bottom: 1px solid var(--cream-border); font-size: 0.85rem; }
        .data-table tr:hover { background: var(--cream); }
        
        /* Badges */
        .badge-active { background: var(--success-pale); color: var(--success); padding: 4px 10px; border-radius: 20px; font-size: 0.7rem; font-weight: 600; }
        .badge-inactive { background: var(--danger-pale); color: var(--danger); padding: 4px 10px; border-radius: 20px; font-size: 0.7rem; font-weight: 600; }
        .badge-role { background: var(--gold-pale); color: var(--gold); padding: 4px 10px; border-radius: 20px; font-size: 0.7rem; font-weight: 600; }

        /* Alerts */
        .alert { padding: 12px 18px; border-radius: var(--radius); margin-bottom: 20px; display: flex; align-items: center; gap: 10px; }
        .alert-error { background: var(--danger-pale); border: 1px solid rgba(192,57,43,0.25); color: var(--danger); }
        .alert-success { background: var(--success-pale); border: 1px solid rgba(46,125,82,0.25); color: var(--success); }

        /* Guidelines */
        .guidelines-list { margin-left: 20px; color: var(--text-muted); font-size: 0.85rem; line-height: 1.6; }
        .guidelines-list li { margin-bottom: 8px; }

        /* Total Count Badge */
        .total-badge {
            background: var(--gold-pale);
            color: var(--gold);
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.75rem;
            font-weight: 600;
        }

        @media (max-width: 768px) {
            .data-table { display: block; overflow-x: auto; }
            .form-buttons { flex-direction: column; }
            .form-buttons button { width: 100%; }
            .form-row { flex-direction: column; gap: 0; }
        }
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
        <a href="${pageContext.request.contextPath}/admin/users.jsp" class="nav-item-link active">
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

        <div class="nav-section-label">Reports</div>
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
            <i class="bi bi-database-fill"></i> Backup
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
        <span class="topbar-title">User Management</span>
        <span class="topbar-date">
            <i class="bi bi-calendar3 me-1"></i>
            <script>document.write(new Date().toLocaleDateString('en-ZA', {weekday:'short', year:'numeric', month:'short', day:'numeric'}));</script>
        </span>
        <div class="topbar-avatar"><%= initials %></div>
    </header>

    <main class="page-body">
        <div class="page-header">
            <div>
                <p class="page-eyebrow">Administration</p>
                <h1 class="page-heading">User Management</h1>
                <p class="text-muted mt-2">Manage system users, roles, and permissions</p>
            </div>
        </div>

        <!-- Success/Error Messages -->
        <% if (success != null) { %>
            <div class="alert alert-success"><i class="bi bi-check-circle-fill"></i> <%= success %></div>
        <% } %>
        <% if (error != null) { %>
            <div class="alert alert-error"><i class="bi bi-exclamation-circle-fill"></i> <%= error %></div>
        <% } %>

        <!-- Add New User Form -->
        <div class="content-card">
            <div class="card-header-bar">
                <h2 class="card-header-title"><i class="bi bi-person-plus-fill"></i> Add New User</h2>
            </div>
            <div class="card-body">
                <form action="${pageContext.request.contextPath}/admin/user-add" method="post">
                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">Username <span style="color:var(--gold)">*</span></label>
                            <input type="text" name="username" class="form-control" placeholder="Enter username" required>
                        </div>
                        <div class="form-group">
                            <label class="form-label">Full Name <span style="color:var(--gold)">*</span></label>
                            <input type="text" name="fullName" class="form-control" placeholder="Enter full name" required>
                        </div>
                        <div class="form-group">
                            <label class="form-label">Email <span style="color:var(--gold)">*</span></label>
                            <input type="email" name="email" class="form-control" placeholder="user@example.com" required>
                        </div>
                    </div>
                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">Password <span style="color:var(--gold)">*</span></label>
                            <input type="password" name="password" class="form-control" placeholder="Create password (min 8 characters)" required>
                        </div>
                        <div class="form-group">
                            <label class="form-label">Role <span style="color:var(--gold)">*</span></label>
                            <select name="roleId" class="form-select" required>
                                <option value="">Select Role</option>
                                <option value="2">Manager</option>
                                <option value="3">Accountant</option>
                                <option value="4">Cashier</option>
                                <option value="5">Inventory Officer</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label class="form-label">Status</label>
                            <select name="isActive" class="form-select">
                                <option value="true">Active</option>
                                <option value="false">Inactive</option>
                            </select>
                        </div>
                    </div>
                    <div class="form-buttons">
                        <button type="submit" class="btn-gold"><i class="bi bi-check-lg"></i> Create User</button>
                        <button type="reset" class="btn-outline"><i class="bi bi-arrow-repeat"></i> Clear Form</button>
                    </div>
                </form>
            </div>
        </div>
<!-- Existing Users Table -->
<div class="content-card">
    <div class="card-header-bar">
        <h2 class="card-header-title"><i class="bi bi-people-fill"></i> System Users</h2>
        <span class="total-badge">Total: <%= users != null ? users.size() : 0 %> users</span>
    </div>
    <div class="card-body" style="padding:0;">
        <div style="overflow-x: auto;">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Username</th>
                        <th>Full Name</th>
                        <th>Email</th>
                        <th>Role</th>
                        <th>Status</th>
                        <th>Last Login</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <% if (users == null || users.isEmpty()) { %>
                        <tr class="empty-state-row">
                            <td colspan="8" style="text-align: center; padding: 40px;">
                                <i class="bi bi-people" style="font-size: 2rem; opacity: 0.3; display: block; margin-bottom: 10px;"></i>
                                No users found. Add your first user above!
                            </td>
                        </tr>
                    <% } else { 
                        for (User user : users) { 
                    %>
                        <tr>
                            <td><%= user.getUserId() %></td>
                            <td><strong><%= user.getUsername() != null ? user.getUsername() : "-" %></strong></td>
                            <td><%= user.getFullName() != null ? user.getFullName() : "-" %></td>
                            <td><%= user.getEmail() != null ? user.getEmail() : "-" %></td>
                            <td><span class="badge-role"><%= user.getRoleName() != null ? user.getRoleName() : "Unknown" %></span></td>
                            <td>
                                <% if (user.isIsActive()) { %>
                                    <span class="badge-active">Active</span>
                                <% } else { %>
                                    <span class="badge-inactive">Inactive</span>
                                <% } %>
                            </td>
                            <td><%= user.getLastLogin() != null ? user.getLastLogin().toString() : "Never" %></td>
                            <td>
                                <div class="action-buttons">
                                    <button class="action-btn edit-btn" onclick="editUser(<%= user.getUserId() %>, '<%= user.getUsername() != null ? user.getUsername() : "" %>', '<%= user.getFullName() != null ? user.getFullName().replace("'", "\\'") : "" %>', '<%= user.getEmail() != null ? user.getEmail() : "" %>', <%= user.getRoleId() %>, <%= user.isIsActive() %>)">
                                        <i class="bi bi-pencil"></i> Edit
                                    </button>
                                    <% if (user.getUserId() != loggedInUser.getUserId()) { %>
                                        <button class="action-btn delete-btn" onclick="confirmDelete(<%= user.getUserId() %>, '<%= user.getUsername() %>')">
                                            <i class="bi bi-trash"></i> Delete
                                        </button>
                                    <% } else { %>
                                        <span class="text-muted" style="font-size: 0.7rem; padding: 5px 12px;">(Current)</span>
                                    <% } %>
                                </div>
                            </td>
                        </tr>
                    <% } 
                    } %>
                </tbody>
            </table>
        </div>
    </div>
</div>        <!-- Guidelines -->
        <div class="content-card">
            <div class="card-header-bar">
                <h2 class="card-header-title"><i class="bi bi-info-circle-fill"></i> User Management Guidelines</h2>
            </div>
            <div class="card-body">
                <ul class="guidelines-list">
                    <li><i class="bi bi-shield-lock"></i> Administrator accounts can only be created by existing administrators</li>
                    <li><i class="bi bi-key"></i> Password must be at least 8 characters</li>
                    <li><i class="bi bi-pencil"></i> Click "Edit" to modify user details or reset password</li>
                    <li><i class="bi bi-trash"></i> Click "Delete" to remove a user (this cannot be undone)</li>
                    <li><i class="bi bi-person-badge"></i> Each user can only have one role assigned</li>
                    <li><i class="bi bi-envelope"></i> New users will receive their login credentials via email</li>
                </ul>
            </div>
        </div>
    </main>
</div>

<!-- Edit User Modal -->
<div class="modal fade" id="editUserModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content" style="border-radius: var(--radius);">
            <div class="modal-header" style="background: var(--cream); border-bottom: 1px solid var(--cream-border);">
                <h5 class="modal-title" style="font-family: var(--font-display);"><i class="bi bi-pencil-square"></i> Edit User</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form action="${pageContext.request.contextPath}/admin/user-edit" method="post">
                <input type="hidden" name="userId" id="editUserId">
                <div class="modal-body">
                    <div class="form-group">
                        <label class="form-label">Username</label>
                        <input type="text" name="username" id="editUsername" class="form-control" readonly style="background: var(--cream);">
                    </div>
                    <div class="form-group">
                        <label class="form-label">Full Name <span style="color:var(--gold)">*</span></label>
                        <input type="text" name="fullName" id="editFullName" class="form-control" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Email <span style="color:var(--gold)">*</span></label>
                        <input type="email" name="email" id="editEmail" class="form-control" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label">New Password <span style="color:var(--text-muted); font-weight:normal;">(leave blank to keep same)</span></label>
                        <input type="password" name="password" class="form-control" placeholder="Enter new password (min 8 characters)">
                    </div>
                    <div class="form-group">
                        <label class="form-label">Role</label>
                        <select name="roleId" id="editRoleId" class="form-select">
                            <option value="2">Manager</option>
                            <option value="3">Accountant</option>
                            <option value="4">Cashier</option>
                            <option value="5">Inventory Officer</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Status</label>
                        <select name="isActive" id="editIsActive" class="form-select">
                            <option value="true">Active</option>
                            <option value="false">Inactive</option>
                        </select>
                    </div>
                </div>
                <div class="modal-footer" style="background: var(--cream); border-top: 1px solid var(--cream-border);">
                    <button type="button" class="btn-outline" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn-gold">Save Changes</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Delete Confirmation Modal -->
<div class="modal fade" id="deleteModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content" style="border-radius: var(--radius);">
            <div class="modal-header" style="background: var(--cream); border-bottom: 1px solid var(--cream-border);">
                <h5 class="modal-title"><i class="bi bi-exclamation-triangle-fill" style="color: var(--danger);"></i> Confirm Delete</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <p>Are you sure you want to delete user <strong id="deleteUsername"></strong>?</p>
                <p class="text-muted" style="font-size: 0.8rem;">This action cannot be undone.</p>
            </div>
            <div class="modal-footer" style="background: var(--cream); border-top: 1px solid var(--cream-border);">
                <form action="${pageContext.request.contextPath}/admin/user-delete" method="post">
                    <input type="hidden" name="userId" id="deleteUserId">
                    <button type="button" class="btn-outline" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="delete-btn" style="padding: 10px 20px;">Delete User</button>
                </form>
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
    
    function editUser(id, username, fullName, email, roleId, isActive) {
        document.getElementById('editUserId').value = id;
        document.getElementById('editUsername').value = username;
        document.getElementById('editFullName').value = fullName;
        document.getElementById('editEmail').value = email;
        document.getElementById('editRoleId').value = roleId;
        document.getElementById('editIsActive').value = isActive;
        new bootstrap.Modal(document.getElementById('editUserModal')).show();
    }
    
    function confirmDelete(id, username) {
        document.getElementById('deleteUserId').value = id;
        document.getElementById('deleteUsername').innerText = username;
        new bootstrap.Modal(document.getElementById('deleteModal')).show();
    }
    
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') closeSidebar();
    });
    
    // Auto-hide flash messages after 5 seconds
    setTimeout(function() {
        let flashes = document.querySelectorAll('.alert');
        flashes.forEach(function(flash) {
            flash.style.transition = 'opacity 0.4s';
            flash.style.opacity = '0';
            setTimeout(function() { flash.remove(); }, 500);
        });
    }, 5000);
</script>

</body>
</html>