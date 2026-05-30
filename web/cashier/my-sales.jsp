<%-- web/cashier/my-sales.jsp --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="mpeoa.models.User, mpeoa.dao.SaleDAO, mpeoa.models.Sale, java.util.*, java.text.*, java.math.BigDecimal" %>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    
    // Allow only Cashier and Administrator
    String role = loggedInUser.getRoleName();
    if (!"Cashier".equalsIgnoreCase(role) && !"Administrator".equalsIgnoreCase(role)) {
        response.sendError(403, "Access Denied. Cashier access required.");
        return;
    }
    
    SaleDAO saleDAO = new SaleDAO();
    int userId = loggedInUser.getUserId();
    
    // Get date range filter
    String filter = request.getParameter("filter");
    if (filter == null) filter = "all";
    
    java.sql.Date startDate = null;
    java.sql.Date endDate = new java.sql.Date(System.currentTimeMillis());
    Calendar cal = Calendar.getInstance();
    String periodLabel = "All Time";
    
    switch (filter) {
        case "today":
            startDate = endDate;
            periodLabel = "Today";
            break;
        case "week":
            cal.add(Calendar.DAY_OF_MONTH, -7);
            startDate = new java.sql.Date(cal.getTimeInMillis());
            periodLabel = "Last 7 Days";
            break;
        case "month":
            cal.add(Calendar.MONTH, -1);
            startDate = new java.sql.Date(cal.getTimeInMillis());
            periodLabel = "Last 30 Days";
            break;
        default:
            startDate = null;
            periodLabel = "All Time";
            break;
    }
    
    // Get sales by cashier with date filter
    List<Sale> mySales;
    if (startDate != null) {
        mySales = saleDAO.getSalesByCashierAndDateRange(userId, startDate, endDate);
    } else {
        mySales = saleDAO.getSalesByCashier(userId, 100);
    }
    
    // Calculate totals
    BigDecimal totalSalesAmount = BigDecimal.ZERO;
    int totalTransactions = mySales.size();
    for (Sale sale : mySales) {
        if (sale.getFinalAmount() != null) {
            totalSalesAmount = totalSalesAmount.add(sale.getFinalAmount());
        }
    }
    
    DecimalFormat df = new DecimalFormat("#,##0.00");
    
    // Build initials
    String initials = "A";
    String cashierName = loggedInUser.getFullName();
    if (cashierName != null && !cashierName.trim().isEmpty()) {
        String[] parts = cashierName.trim().split("\\s+");
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
    <title>My Sales — Mpeoa Supermarket ERP</title>
    
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

        /* Sidebar */
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
        .page-header { margin-bottom: 28px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 16px; }
        .page-eyebrow { font-size: 0.72rem; font-weight: 600; letter-spacing: 0.1em; text-transform: uppercase; color: var(--gold); margin-bottom: 4px; }
        .page-heading { font-family: var(--font-display); font-size: 1.7rem; font-weight: 700; color: var(--navy); margin: 0; }

        .role-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.7rem;
            font-weight: 600;
            margin-left: 10px;
            background: var(--gold-pale);
            color: var(--gold);
        }

        /* Filter Bar */
        .filter-bar {
            background: var(--white);
            border-radius: var(--radius);
            padding: 12px 20px;
            margin-bottom: 24px;
            border: 1px solid var(--cream-border);
            display: flex;
            justify-content: flex-end;
            gap: 10px;
            flex-wrap: wrap;
        }
        .filter-btn {
            padding: 6px 18px;
            border-radius: 20px;
            text-decoration: none;
            font-size: 0.8rem;
            font-weight: 500;
            transition: all 0.2s;
            border: 1px solid var(--cream-border);
            color: var(--navy);
            background: var(--white);
        }
        .filter-btn:hover { border-color: var(--gold); background: var(--gold-pale); }
        .filter-btn.active { background: var(--gold); color: white; border-color: var(--gold); }

        /* Stat Cards */
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
        .stat-value { font-family: var(--font-display); font-size: 1.8rem; font-weight: 700; margin-bottom: 4px; color: var(--navy); }
        .stat-label { font-size: 0.75rem; color: var(--text-muted); }

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
        .btn-sm-outline:hover { border-color: var(--gold); background: var(--gold-pale); color: var(--gold); }

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

        .badge-success {
            background: var(--success-pale);
            color: var(--success);
            padding: 4px 8px;
            border-radius: 12px;
            font-size: 0.65rem;
            font-weight: 600;
        }

        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: var(--text-muted);
        }
        .empty-state i {
            font-size: 3rem;
            margin-bottom: 15px;
            opacity: 0.5;
        }
        .empty-state h4 {
            font-family: var(--font-display);
            font-size: 1.2rem;
            margin-bottom: 10px;
            color: var(--navy);
        }

        .d-flex { display: flex; }
        .align-items-center { align-items: center; }
        .justify-content-between { justify-content: space-between; }
        .gap-2 { gap: 8px; }
        .gap-3 { gap: 16px; }
        .mb-4 { margin-bottom: 24px; }
        .mt-2 { margin-top: 8px; }
        .fw-bold { font-weight: 700; }
        .text-center { text-align: center; }
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
            <div class="sidebar-brand-sub">Cashier Portal</div>
        </div>
    </div>
    <nav class="sidebar-nav">
        <div class="nav-section-label">Main</div>
        <a href="${pageContext.request.contextPath}/cashier/dashboard.jsp" class="nav-item-link">
            <i class="bi bi-grid-1x2-fill"></i> Dashboard
        </a>
        
        <div class="nav-section-label">Operations</div>
        <a href="${pageContext.request.contextPath}/cashier/pos.jsp" class="nav-item-link">
            <i class="bi bi-cash-register"></i> Point of Sale
        </a>
        <a href="${pageContext.request.contextPath}/cashier/my-sales.jsp" class="nav-item-link active">
            <i class="bi bi-receipt"></i> My Sales
        </a>

        <div class="nav-section-label">Products</div>
        <a href="${pageContext.request.contextPath}/cashier/products.jsp" class="nav-item-link">
            <i class="bi bi-box-seam-fill"></i> View Products
        </a>
    </nav>
    <div class="sidebar-footer">
        <div class="sidebar-avatar"><%= initials %></div>
        <div>
            <div class="sidebar-admin-name"><%= cashierName != null ? cashierName : "Cashier" %></div>
            <div class="sidebar-admin-role">Cashier</div>
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
        <span class="topbar-title">My Sales</span>
        <span class="topbar-date">
            <i class="bi bi-calendar3 me-1"></i>
            <script>document.write(new Date().toLocaleDateString('en-ZA'));</script>
        </span>
        <div class="topbar-avatar"><%= initials %></div>
    </header>

    <main class="page-body">
        <div class="page-header">
            <div>
                <p class="page-eyebrow">Transaction History</p>
                <h1 class="page-heading">My Sales</h1>
                <p class="text-muted mt-2">View your sales history and transaction details.</p>
            </div>
            <div>
                <span class="role-badge"><i class="bi bi-cash-stack"></i> Cashier</span>
                <a href="${pageContext.request.contextPath}/cashier/pos.jsp" class="btn-sm-outline ms-2">
                    <i class="bi bi-cash-register"></i> New Sale
                </a>
            </div>
        </div>

        <!-- Filter Bar -->
        <div class="filter-bar">
            <a href="?filter=all" class="filter-btn <%= "all".equals(filter) ? "active" : "" %>">All Time</a>
            <a href="?filter=today" class="filter-btn <%= "today".equals(filter) ? "active" : "" %>">Today</a>
            <a href="?filter=week" class="filter-btn <%= "week".equals(filter) ? "active" : "" %>">Last 7 Days</a>
            <a href="?filter=month" class="filter-btn <%= "month".equals(filter) ? "active" : "" %>">Last 30 Days</a>
        </div>

        <!-- Statistics Cards -->
        <div class="row g-3 mb-4">
            <div class="col-md-6">
                <div class="stat-card animate-fade">
                    <div class="stat-icon"><i class="bi bi-receipt"></i></div>
                    <div class="stat-value"><%= totalTransactions %></div>
                    <div class="stat-label">Total Transactions (<%= periodLabel %>)</div>
                </div>
            </div>
            <div class="col-md-6">
                <div class="stat-card animate-fade">
                    <div class="stat-icon"><i class="bi bi-currency-exchange"></i></div>
                    <div class="stat-value">R <%= df.format(totalSalesAmount) %></div>
                    <div class="stat-label">Total Sales (<%= periodLabel %>)</div>
                </div>
            </div>
        </div>

        <!-- Sales Table -->
        <div class="content-card">
            <div class="card-header-bar">
                <h2 class="card-header-title">
                    <i class="bi bi-clock-history"></i> Sales Transactions
                </h2>
                <span class="btn-sm-outline">Total: <%= totalTransactions %> records</span>
            </div>
            <div class="table-responsive">
                <% if (mySales != null && !mySales.isEmpty()) { %>
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Invoice No.</th>
                                <th>Date & Time</th>
                                <th>Items</th>
                                <th>Subtotal</th>
                                <th>Tax</th>
                                <th>Total</th>
                                <th>Payment</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% for (Sale sale : mySales) { %>
                                <tr>
                                    <td><strong><%= sale.getInvoiceNumber() %></strong></td>
                                    <td><%= sale.getSaleDate() != null ? sale.getSaleDate().toString() : "-" %></td>
                                    <td><%= sale.getItemCount() %> items</td>
                                    <td>R <%= df.format(sale.getTotalAmount()) %></td>
                                    <td>R <%= df.format(sale.getTax()) %></td>
                                    <td class="fw-bold">R <%= df.format(sale.getFinalAmount()) %></td>
                                    <td><%= sale.getPaymentMethod() != null ? sale.getPaymentMethod() : "Cash" %></td>
                                    <td><span class="badge-success">Completed</span></td>
                                    <td>
                                        <button class="btn-sm-outline" onclick="viewReceipt('<%= sale.getInvoiceNumber() %>')">
                                            <i class="bi bi-receipt"></i> Receipt
                                        </button>
                                    </td>
                                </tr>
                            <% } %>
                        </tbody>
                    </table>
                <% } else { %>
                    <div class="empty-state">
                        <i class="bi bi-receipt"></i>
                        <h4>No Sales Found</h4>
                        <p>You haven't processed any sales yet.</p>
                        <a href="${pageContext.request.contextPath}/cashier/pos.jsp" class="btn-sm-outline mt-2">
                            <i class="bi bi-cash-register"></i> Start a New Sale
                        </a>
                    </div>
                <% } %>
            </div>
        </div>
        
        <!-- Receipt Modal -->
        <div class="modal fade" id="receiptModal" tabindex="-1">
            <div class="modal-dialog modal-sm">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title"><i class="bi bi-receipt"></i> Receipt</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body receipt-content" id="receiptContent" style="font-family: monospace; font-size: 0.8rem;">
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn-sm-outline" data-bs-dismiss="modal">Close</button>
                        <button type="button" class="btn-gold" onclick="window.print()" style="background: var(--gold); color: white; border: none; border-radius: 8px; padding: 8px 16px;">Print</button>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Guidelines -->
        <div class="content-card">
            <div class="card-header-bar">
                <h2 class="card-header-title">
                    <i class="bi bi-info-circle-fill"></i> Sales Information
                </h2>
            </div>
            <div style="padding: 20px;">
                <ul style="padding-left: 20px; color: var(--text-muted); font-size: 0.85rem; line-height: 1.8;">
                    <li><i class="bi bi-receipt me-1"></i> Each sale generates a unique invoice number for tracking</li>
                    <li><i class="bi bi-calculator-fill me-1"></i> Tax is calculated at 15% on all sales</li>
                    <li><i class="bi bi-box-seam-fill me-1"></i> Inventory is automatically updated when a sale is completed</li>
                    <li><i class="bi bi-printer-fill me-1"></i> Click "Receipt" to view or print a customer receipt</li>
                    <li><i class="bi bi-graph-up me-1"></i> Use the date filters to view sales for different periods</li>
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
    
    function viewReceipt(invoiceNumber) {
        // Fetch receipt details from server
        fetch('${pageContext.request.contextPath}/receipt?invoice=' + invoiceNumber)
            .then(response => response.text())
            .then(data => {
                document.getElementById('receiptContent').innerHTML = data;
                new bootstrap.Modal(document.getElementById('receiptModal')).show();
            })
            .catch(error => {
                alert('Error loading receipt: ' + error);
            });
    }
    
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') closeSidebar();
    });
</script>

</body>
</html>