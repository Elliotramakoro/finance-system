<%-- web/admin/pos.jsp --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="mpeoa.models.User, mpeoa.dao.ProductDAO, mpeoa.models.Product, java.util.*, java.text.*" %>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    
    // Allow only Administrator (Admin has full access)
    String role = loggedInUser.getRoleName();
    if (!"Administrator".equalsIgnoreCase(role)) {
        response.sendError(403, "Access Denied. Administrator access required.");
        return;
    }
    
    ProductDAO productDAO = new ProductDAO();
    List<Product> products = productDAO.getAllProducts();
    
    DecimalFormat df = new DecimalFormat("#,##0.00");
    
    // Build initials
    String initials = "A";
    String adminName = loggedInUser.getFullName();
    if (adminName != null && !adminName.trim().isEmpty()) {
        String[] parts = adminName.trim().split("\\s+");
        if (parts.length >= 2) initials = "" + parts[0].charAt(0) + parts[1].charAt(0);
        else initials = "" + parts[0].charAt(0);
        initials = initials.toUpperCase();
    }
    
    // Store admin name for JavaScript
    String jsAdminName = adminName != null ? adminName.replace("'", "\\'") : "Administrator";
    
    // Get context path
    String contextPath = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Point of Sale — Admin — Mpeoa Supermarket ERP</title>
    
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
            --danger: #C0392B;
            --warning: #D4A42B;
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
            margin: 0;
            min-height: 100vh;
            overflow: hidden;
        }

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

        .main-wrap { margin-left: var(--sidebar-w); height: 100vh; display: flex; flex-direction: column; }
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
            flex-shrink: 0;
        }
        .burger-btn { display: none; background: none; border: none; font-size: 1.35rem; cursor: pointer; }
        .burger-btn:hover { background: var(--gold-pale); border-radius: 6px; }
        @media (max-width: 991.98px) { .burger-btn { display: flex; } }
        .topbar-title { font-family: var(--font-display); font-size: 1.15rem; font-weight: 700; color: var(--navy); flex: 1; }
        .topbar-date { font-size: 0.78rem; color: var(--text-muted); }
        @media (max-width: 576px) { .topbar-date { display: none; } }
        .topbar-avatar { width: 36px; height: 36px; border-radius: 50%; background: var(--navy); display: flex; align-items: center; justify-content: center; font-size: 0.8rem; font-weight: 700; color: var(--gold-light); border: 2px solid var(--cream-border); }

        /* Role Badge */
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

        .pos-container {
            flex: 1;
            display: flex;
            overflow: hidden;
            padding: 20px;
            gap: 20px;
        }

        .products-section {
            flex: 2;
            display: flex;
            flex-direction: column;
            background: var(--white);
            border-radius: var(--radius);
            border: 1px solid var(--cream-border);
            overflow: hidden;
        }
        .search-bar {
            padding: 15px;
            border-bottom: 1px solid var(--cream-border);
            background: var(--cream-dark);
        }
        .search-bar input {
            width: 100%;
            padding: 10px 15px;
            border: 1.5px solid var(--cream-border);
            border-radius: 8px;
            font-size: 0.9rem;
            outline: none;
        }
        .search-bar input:focus {
            border-color: var(--gold);
            box-shadow: 0 0 0 3px var(--gold-pale);
        }
        .products-grid {
            flex: 1;
            overflow-y: auto;
            padding: 15px;
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
            gap: 15px;
        }
        .product-card {
            background: var(--cream);
            border-radius: 10px;
            padding: 12px;
            text-align: center;
            cursor: pointer;
            transition: all 0.2s;
            border: 1px solid var(--cream-border);
        }
        .product-card:hover:not(.disabled) {
            transform: translateY(-3px);
            border-color: var(--gold);
            box-shadow: var(--shadow-md);
        }
        .product-card.disabled {
            opacity: 0.5;
            cursor: not-allowed;
        }
        .product-name {
            font-weight: 600;
            font-size: 0.85rem;
            margin-bottom: 5px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        .product-price {
            color: var(--gold);
            font-weight: 700;
            font-size: 1rem;
        }
        .product-stock {
            font-size: 0.65rem;
            color: var(--text-muted);
            margin-top: 5px;
        }

        .cart-section {
            flex: 1.2;
            background: var(--white);
            border-radius: var(--radius);
            border: 1px solid var(--cream-border);
            display: flex;
            flex-direction: column;
            overflow: hidden;
        }
        .cart-header {
            padding: 15px;
            border-bottom: 1px solid var(--cream-border);
            background: var(--cream-dark);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .cart-header h3 {
            margin: 0;
            font-family: var(--font-display);
            font-size: 1rem;
            font-weight: 700;
        }
        .cart-items {
            flex: 1;
            overflow-y: auto;
            padding: 10px;
        }
        .cart-item {
            display: flex;
            align-items: flex-start;
            padding: 12px 8px;
            border-bottom: 1px solid var(--cream-border);
            gap: 8px;
            flex-wrap: wrap;
        }
        .cart-item-info {
            flex: 2;
            min-width: 120px;
        }
        .cart-item-name {
            font-weight: 600;
            font-size: 0.85rem;
        }
        .cart-item-details {
            color: var(--text-muted);
            font-size: 0.7rem;
            line-height: 1.2;
            margin-top: 2px;
        }
        .cart-item-quantity {
            display: flex;
            align-items: center;
            gap: 8px;
            background: var(--cream);
            padding: 4px 8px;
            border-radius: 20px;
        }
        .cart-item-quantity button {
            width: 26px;
            height: 26px;
            border-radius: 50%;
            border: none;
            background: var(--white);
            cursor: pointer;
            font-weight: bold;
            font-size: 1rem;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            transition: all 0.2s;
        }
        .cart-item-quantity button:hover {
            background: var(--gold);
            color: white;
        }
        .cart-item-quantity span {
            min-width: 30px;
            text-align: center;
            font-weight: 600;
        }
        .cart-item-total {
            font-weight: 700;
            min-width: 80px;
            text-align: right;
        }
        .cart-item-total small {
            font-weight: normal;
            font-size: 0.65rem;
        }
        .cart-item-remove {
            cursor: pointer;
            color: var(--text-muted);
            padding: 4px;
        }
        .cart-item-remove:hover {
            color: var(--danger);
        }
        .text-success { color: var(--success) !important; }
        .cart-summary {
            padding: 15px;
            border-top: 2px solid var(--cream-border);
            background: var(--cream);
        }
        .summary-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 8px;
            font-size: 0.85rem;
        }
        .summary-row.total {
            font-size: 1.1rem;
            font-weight: 700;
            border-top: 1px solid var(--cream-border);
            padding-top: 10px;
            margin-top: 5px;
        }
        .cart-actions {
            display: flex;
            gap: 10px;
            margin-top: 15px;
        }
        .btn-checkout {
            flex: 2;
            background: var(--gold);
            color: white;
            border: none;
            border-radius: 8px;
            padding: 12px;
            font-weight: 600;
            cursor: pointer;
        }
        .btn-checkout:hover {
            background: var(--gold-light);
        }
        .btn-clear {
            flex: 1;
            background: transparent;
            border: 1.5px solid var(--cream-border);
            border-radius: 8px;
            padding: 12px;
            font-weight: 600;
            cursor: pointer;
        }
        .btn-clear:hover {
            border-color: var(--danger);
            color: var(--danger);
        }

        .receipt-content {
            font-family: 'Courier New', monospace;
            font-size: 0.75rem;
        }
        .receipt-header {
            text-align: center;
            margin-bottom: 15px;
        }
        .receipt-divider {
            border-top: 1px dashed #000;
            margin: 8px 0;
        }
        .receipt-table {
            width: 100%;
            font-size: 0.7rem;
        }
        .receipt-table th, .receipt-table td {
            padding: 4px 0;
        }
        .btn-gold {
            background: var(--gold);
            color: white;
            border: none;
            border-radius: 8px;
            padding: 8px 16px;
        }
        .btn-outline {
            background: transparent;
            border: 1px solid var(--cream-border);
            border-radius: 8px;
            padding: 8px 16px;
        }

        @keyframes fadeUp {
            from { opacity: 0; transform: translateY(16px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .text-danger { color: var(--danger); }
        .text-gold { color: var(--gold); }
        .fw-bold { font-weight: 700; }
        .d-flex { display: flex; }
        .align-items-center { align-items: center; }
        .justify-content-between { justify-content: space-between; }
        .gap-2 { gap: 8px; }
        .mt-2 { margin-top: 8px; }
        .me-1 { margin-right: 4px; }
        .mb-0 { margin-bottom: 0; }
    </style>
</head>
<body>

<div class="sidebar-overlay" id="sidebarOverlay" onclick="closeSidebar()"></div>

<aside class="sidebar" id="sidebar">
    <button class="sidebar-close" onclick="closeSidebar()">
        <i class="bi bi-x-lg"></i>
    </button>
    <div class="sidebar-brand">
        <div class="sidebar-logo">MS</div>
        <div class="sidebar-brand-text">
            <div class="sidebar-brand-name">Mpeoa Supermarket</div>
            <div class="sidebar-brand-sub">Admin Portal</div>
        </div>
    </div>
    <nav class="sidebar-nav">
        <div class="nav-section-label">Main</div>
        <a href="<%= contextPath %>/admin/dashboard" class="nav-item-link">
            <i class="bi bi-grid-1x2-fill"></i> Dashboard
        </a>
        
        <div class="nav-section-label">Operations</div>
        <a href="<%= contextPath %>/admin/pos.jsp" class="nav-item-link active">
            <i class="bi bi-cash-register"></i> Point of Sale
        </a>
        <a href="<%= contextPath %>/admin/sales.jsp" class="nav-item-link">
            <i class="bi bi-receipt"></i> Sales
        </a>
        <a href="<%= contextPath %>/admin/expenses.jsp" class="nav-item-link">
            <i class="bi bi-wallet2"></i> Expenses
        </a>

        <div class="nav-section-label">Management</div>
        <a href="<%= contextPath %>/admin/users.jsp" class="nav-item-link">
            <i class="bi bi-people-fill"></i> Users
        </a>
        <a href="<%= contextPath %>/admin/products.jsp" class="nav-item-link">
            <i class="bi bi-box-seam-fill"></i> Products
        </a>
        <a href="<%= contextPath %>/admin/inventory.jsp" class="nav-item-link">
            <i class="bi bi-archive-fill"></i> Inventory
        </a>
    </nav>
    <div class="sidebar-footer">
        <div class="sidebar-avatar"><%= initials %></div>
        <div>
            <div class="sidebar-admin-name"><%= adminName != null ? adminName : "Administrator" %></div>
            <div class="sidebar-admin-role">Administrator</div>
        </div>
        <a href="<%= contextPath %>/logout" class="sidebar-logout" title="Logout">
            <i class="bi bi-box-arrow-right"></i>
        </a>
    </div>
</aside>

<div class="main-wrap">
    <header class="topbar">
        <button class="burger-btn" onclick="openSidebar()"><i class="bi bi-list"></i></button>
        <span class="topbar-title">Point of Sale</span>
        <span class="topbar-date">
            <i class="bi bi-calendar3 me-1"></i>
            <script>document.write(new Date().toLocaleDateString('en-ZA'));</script>
        </span>
        <div class="topbar-avatar"><%= initials %></div>
    </header>

    <div class="pos-container">
        <div class="products-section">
            <div class="search-bar">
                <input type="text" id="searchInput" placeholder="Search products by name or barcode..." onkeyup="filterProducts()">
            </div>
            <div class="products-grid" id="productsGrid">
                <% if (products != null && !products.isEmpty()) {
                    for (Product product : products) { 
                        boolean inStock = product.getStockQuantity() > 0;
                %>
                    <div class="product-card <%= !inStock ? "disabled" : "" %>" 
                         onclick="<%= inStock ? "addToCartFromCard(this)" : "" %>"
                         data-id="<%= product.getProductId() %>"
                         data-name="<%= product.getProductName() != null ? product.getProductName().replace("\"", "&quot;").replace("&", "&amp;") : "" %>"
                         data-code="<%= product.getProductCode() != null ? product.getProductCode().replace("\"", "&quot;").replace("&", "&amp;") : "" %>"
                         data-category="<%= product.getCategoryName() != null ? product.getCategoryName().replace("\"", "&quot;").replace("&", "&amp;") : "Uncategorized" %>"
                         data-price="<%= product.getUnitPrice() %>"
                         data-cost="<%= product.getCostPrice() != null ? product.getCostPrice() : 0 %>"
                         data-stock="<%= product.getStockQuantity() %>">
                        <div class="product-name" title="<%= product.getProductName() %>"><%= product.getProductName() %></div>
                        <div class="product-price">R <%= df.format(product.getUnitPrice()) %></div>
                        <div class="product-stock">
                            Stock: <%= product.getStockQuantity() %> units
                            <% if (!inStock) { %>
                                <span class="text-danger">(Out of Stock)</span>
                            <% } %>
                        </div>
                    </div>
                <% } } else { %>
                    <div class="text-center" style="grid-column: 1/-1; padding: 40px;">No products available</div>
                <% } %>
            </div>
        </div>

        <div class="cart-section">
            <div class="cart-header">
                <h3><i class="bi bi-cart-fill"></i> Shopping Cart</h3>
                <span class="role-badge"><i class="bi bi-shield-check"></i> Admin Mode</span>
            </div>
            <div class="cart-items" id="cartItems">
                <div class="text-center text-muted" style="padding: 40px;">
                    <i class="bi bi-cart" style="font-size: 2rem;"></i>
                    <p>Cart is empty</p>
                </div>
            </div>
            <div class="cart-summary">
                <div class="summary-row">
                    <span>Subtotal:</span>
                    <span id="subtotal">R 0.00</span>
                </div>
                <div class="summary-row">
                    <span>Tax (15%):</span>
                    <span id="tax">R 0.00</span>
                </div>
                <div class="summary-row">
                    <span>Total Cost:</span>
                    <span id="totalCost">R 0.00</span>
                </div>
                <div class="summary-row">
                    <span>Gross Profit:</span>
                    <span id="grossProfit" class="text-success">R 0.00</span>
                </div>
                <div class="summary-row total">
                    <span>Total:</span>
                    <span id="total" class="text-gold">R 0.00</span>
                </div>
                <div class="cart-actions">
                    <button class="btn-clear" onclick="clearCart()">Clear</button>
                    <button class="btn-checkout" onclick="checkout()">Checkout</button>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="receiptModal" tabindex="-1">
    <div class="modal-dialog modal-sm">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title"><i class="bi bi-receipt"></i> Receipt</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body receipt-content" id="receiptContent"></div>
            <div class="modal-footer">
                <button type="button" class="btn-outline" data-bs-dismiss="modal">Close</button>
                <button type="button" class="btn-gold" onclick="printReceipt()">Print</button>
            </div>
        </div>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
    var cart = [];
    var taxRate = 0.15;
    var adminName = "<%= jsAdminName %>";
    var contextPath = "<%= contextPath %>";
    var lastReceiptHtml = "";
    
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
    
    function addToCartFromCard(card) {
        var id = parseInt(card.dataset.id, 10);
        var name = card.dataset.name || '';
        var code = card.dataset.code || '';
        var category = card.dataset.category || '';
        var price = parseFloat(card.dataset.price) || 0;
        var costPrice = parseFloat(card.dataset.cost) || 0;
        var stock = parseInt(card.dataset.stock, 10) || 0;
        addToCart(id, name, code, category, price, costPrice, stock);
    }
    
    function addToCart(id, name, code, category, price, costPrice, stock) {
        var existingItem = null;
        for (var i = 0; i < cart.length; i++) {
            if (cart[i].id === id) {
                existingItem = cart[i];
                break;
            }
        }
        
        if (existingItem) {
            if (existingItem.quantity + 1 <= stock) {
                existingItem.quantity++;
            } else {
                alert('Not enough stock available! Only ' + stock + ' units left.');
                return;
            }
        } else {
            if (stock > 0) {
                cart.push({
                    id: id,
                    name: name,
                    code: code,
                    category: category,
                    price: price,
                    costPrice: costPrice,
                    quantity: 1,
                    stock: stock
                });
            } else {
                alert('Product is out of stock!');
                return;
            }
        }
        updateCartDisplay();
    }
    
    function updateCartDisplay() {
        var cartDiv = document.getElementById('cartItems');
        var subtotal = 0;
        var totalCost = 0;
        
        if (cart.length === 0) {
            cartDiv.innerHTML = '<div class="text-center text-muted" style="padding: 40px;">' +
                '<i class="bi bi-cart" style="font-size: 2rem;"></i>' +
                '<p>Cart is empty</p></div>';
            document.getElementById('subtotal').innerText = 'R 0.00';
            document.getElementById('tax').innerText = 'R 0.00';
            document.getElementById('totalCost').innerText = 'R 0.00';
            document.getElementById('grossProfit').innerHTML = 'R 0.00';
            document.getElementById('total').innerHTML = 'R 0.00';
            return;
        }
        
        var cartHtml = '';
        for (var i = 0; i < cart.length; i++) {
            var item = cart[i];
            var itemTotal = item.price * item.quantity;
            var itemCost = item.costPrice * item.quantity;
            var itemProfit = itemTotal - itemCost;
            subtotal += itemTotal;
            totalCost += itemCost;
            
            cartHtml += '<div class="cart-item">' +
                '<div class="cart-item-info">' +
                    '<div class="cart-item-name">' + escapeHtml(item.name) + '</div>' +
                    '<div class="cart-item-details">' +
                        '<small>Code: ' + escapeHtml(item.code || 'N/A') + ' | ' + escapeHtml(item.category) + '</small><br>' +
                        '<small>Price: R ' + item.price.toFixed(2) + ' | Cost: R ' + item.costPrice.toFixed(2) + '</small>' +
                    '</div>' +
                '</div>' +
                '<div class="cart-item-quantity">' +
                    '<button onclick="updateQuantity(' + i + ', ' + (item.quantity - 1) + ')">−</button>' +
                    '<span>' + item.quantity + '</span>' +
                    '<button onclick="updateQuantity(' + i + ', ' + (item.quantity + 1) + ')">+</button>' +
                '</div>' +
                '<div class="cart-item-total">' +
                    '<div>R ' + itemTotal.toFixed(2) + '</div>' +
                    '<small class="text-success">+R ' + itemProfit.toFixed(2) + '</small>' +
                '</div>' +
                '<div class="cart-item-remove" onclick="removeFromCart(' + i + ')">' +
                    '<i class="bi bi-trash3"></i>' +
                '</div>' +
            '</div>';
        }
        
        cartDiv.innerHTML = cartHtml;
        
        var tax = subtotal * taxRate;
        var total = subtotal + tax;
        var grossProfit = subtotal - totalCost;
        
        document.getElementById('subtotal').innerText = 'R ' + subtotal.toFixed(2);
        document.getElementById('tax').innerText = 'R ' + tax.toFixed(2);
        document.getElementById('totalCost').innerText = 'R ' + totalCost.toFixed(2);
        document.getElementById('grossProfit').innerHTML = 'R ' + grossProfit.toFixed(2);
        document.getElementById('total').innerHTML = 'R ' + total.toFixed(2);
    }
    
    function escapeHtml(str) {
        if (!str) return '';
        return str.replace(/[&<>]/g, function(m) {
            if (m === '&') return '&amp;';
            if (m === '<') return '&lt;';
            if (m === '>') return '&gt;';
            return m;
        });
    }
    
    function updateQuantity(index, newQuantity) {
        if (index < 0 || index >= cart.length) return;
        var item = cart[index];
        if (newQuantity <= 0) {
            cart.splice(index, 1);
        } else if (newQuantity > item.stock) {
            alert('Not enough stock available! Only ' + item.stock + ' units left.');
            return;
        } else {
            item.quantity = newQuantity;
        }
        updateCartDisplay();
    }
    
    function removeFromCart(index) {
        if (confirm('Remove this item from cart?')) {
            cart.splice(index, 1);
            updateCartDisplay();
        }
    }
    
    function clearCart() {
        if (cart.length > 0 && confirm('Clear all items from cart?')) {
            cart = [];
            updateCartDisplay();
        }
    }
    
    function checkout() {
        if (cart.length === 0) {
            alert('Cart is empty!');
            return;
        }
        
        var paymentMethod = prompt('Select payment method:\n1. Cash\n2. Card\n3. EFT', 'Cash');
        if (!paymentMethod) return;
        
        if (paymentMethod === '1') paymentMethod = 'Cash';
        else if (paymentMethod === '2') paymentMethod = 'Card';
        else if (paymentMethod === '3') paymentMethod = 'EFT';
        
        processSale(paymentMethod);
    }
    
    function processSale(paymentMethod) {
        var params = new URLSearchParams();
        params.append('action', 'processSale');
        params.append('paymentMethod', paymentMethod);
        
        for (var i = 0; i < cart.length; i++) {
            var item = cart[i];
            params.append('productId[]', item.id);
            params.append('quantity[]', item.quantity);
            params.append('price[]', item.price);
        }
        
        fetch(contextPath + '/pos-sale', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: params.toString()
        })
        .then(function(response) {
            return response.json();
        })
        .then(function(data) {
            if (data.success) {
                generateReceipt(data.invoiceNumber, paymentMethod);
                cart = [];
                updateCartDisplay();
                var receiptModal = new bootstrap.Modal(document.getElementById('receiptModal'));
                receiptModal.show();
            } else {
                alert('Error processing sale: ' + data.message);
            }
        })
        .catch(function(error) {
            console.error('Error:', error);
            alert('Error connecting to server. Please try again.');
        });
    }
    
    function generateReceipt(invoiceNumber, paymentMethod) {
        var now = new Date();
        var subtotal = 0;
        var totalCost = 0;
        
        for (var i = 0; i < cart.length; i++) {
            var item = cart[i];
            subtotal += item.price * item.quantity;
            totalCost += item.costPrice * item.quantity;
        }
        
        var tax = subtotal * taxRate;
        var total = subtotal + tax;
        var grossProfit = subtotal - totalCost;
        
        var receiptHtml = '<div class="receipt-header">' +
            '<h5>MPEOA SUPERMARKET</h5>' +
            '<p>Maseru, Naleli<br>' +
            'Tel: +26659436321<br>' +
            'VAT Reg: 1234567890</p>' +
            '<div class="receipt-divider"></div>' +
            '<p><strong>INVOICE #' + invoiceNumber + '</strong><br>' +
            'Date: ' + now.toLocaleString() + '<br>' +
            'Cashier: ' + adminName + '<br>' +
            'Payment: ' + paymentMethod + '</p>' +
            '<div class="receipt-divider"></div>' +
            '</div>' +
            '<table class="receipt-table">' +
            '<thead>' +
            '<tr style="border-bottom: 1px solid #000;">' +
            '<th style="text-align:left;">Item</th>' +
            '<th style="text-align:center;">Qty</th>' +
            '<th style="text-align:right;">Price</th>' +
            '<th style="text-align:right;">Total</th>' +
            '</tr>' +
            '</thead>' +
            '<tbody>';
        
        for (var i = 0; i < cart.length; i++) {
            var item = cart[i];
            var itemTotal = item.price * item.quantity;
            receiptHtml += '<tr>' +
                '<td style="text-align:left;">' + escapeHtml(item.name) + '<br><small>' + escapeHtml(item.code || '') + '</small></td>' +
                '<td style="text-align:center;">' + item.quantity + '</td>' +
                '<td style="text-align:right;">R ' + item.price.toFixed(2) + '</td>' +
                '<td style="text-align:right;">R ' + itemTotal.toFixed(2) + '</td>' +
                '</tr>';
        }
        
        receiptHtml += '</tbody></table>' +
            '<div class="receipt-divider"></div>' +
            '<div style="padding: 5px 0;">' +
            '<div class="d-flex justify-content-between"><span>Subtotal:</span><span>R ' + subtotal.toFixed(2) + '</span></div>' +
            '<div class="d-flex justify-content-between"><span>Tax (15%):</span><span>R ' + tax.toFixed(2) + '</span></div>' +
            '<div class="d-flex justify-content-between"><span>Total Cost:</span><span>R ' + totalCost.toFixed(2) + '</span></div>' +
            '<div class="d-flex justify-content-between text-success"><span>Gross Profit:</span><span>R ' + grossProfit.toFixed(2) + '</span></div>' +
            '<div class="d-flex justify-content-between fw-bold mt-2"><span>TOTAL:</span><span>R ' + total.toFixed(2) + '</span></div>' +
            '</div>' +
            '<div class="receipt-divider"></div>' +
            '<p class="text-center mb-0">Thank you for shopping at Mpeoa Supermarket!</p>' +
            '<p class="text-center" style="font-size: 0.65rem;">* Goods sold are not returnable *</p>' +
            '<p class="text-center" style="font-size: 0.6rem;">' + now.toLocaleString() + '</p>';
        
        lastReceiptHtml = receiptHtml;
        document.getElementById('receiptContent').innerHTML = receiptHtml;
    }
    
    function printReceipt() {
        var printWindow = window.open('', '_blank');
        printWindow.document.write('<html><head><title>Mpeoa Supermarket Receipt</title>' +
            '<style>' +
            'body { font-family: "Courier New", monospace; font-size: 12px; padding: 20px; }' +
            '.receipt-header { text-align: center; margin-bottom: 15px; }' +
            '.receipt-divider { border-top: 1px dashed #000; margin: 8px 0; }' +
            '.receipt-table { width: 100%; font-size: 11px; border-collapse: collapse; }' +
            '.receipt-table th, .receipt-table td { padding: 4px 0; }' +
            '.d-flex { display: flex; }' +
            '.justify-content-between { justify-content: space-between; }' +
            '.fw-bold { font-weight: bold; }' +
            '.text-center { text-align: center; }' +
            '.mt-2 { margin-top: 8px; }' +
            '.mb-0 { margin-bottom: 0; }' +
            '.text-success { color: green; }' +
            '</style></head><body>' + lastReceiptHtml + '</body></html>');
        printWindow.document.close();
        printWindow.print();
    }
    
    function filterProducts() {
        var searchTerm = document.getElementById('searchInput').value.toLowerCase();
        var productCards = document.querySelectorAll('.product-card');
        
        for (var i = 0; i < productCards.length; i++) {
            var card = productCards[i];
            var name = (card.getAttribute('data-name') || '').toLowerCase();
            var code = (card.getAttribute('data-code') || '').toLowerCase();
            if (name.indexOf(searchTerm) !== -1 || code.indexOf(searchTerm) !== -1) {
                card.style.display = '';
            } else {
                card.style.display = 'none';
            }
        }
    }
    
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') closeSidebar();
    });
</script>
</body>
</html>