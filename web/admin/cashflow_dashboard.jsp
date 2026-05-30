<%-- web/admin/cashflow_dashboard.jsp --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="mpeoa.models.User, mpeoa.dao.SaleDAO, mpeoa.dao.ExpenseDAO, java.util.*, java.text.*, java.math.BigDecimal, java.sql.*" %>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !"Administrator".equalsIgnoreCase(loggedInUser.getRoleName())) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }

    SaleDAO    saleDAO    = new SaleDAO();
    ExpenseDAO expenseDAO = new ExpenseDAO();

    String period = request.getParameter("period");
    if (period == null) period = "month";

    java.sql.Date endDate = new java.sql.Date(System.currentTimeMillis());
    Calendar cal = Calendar.getInstance();
    String periodLabel;

    switch (period) {
        case "week":    cal.add(Calendar.DAY_OF_MONTH, -7);  periodLabel = "Last 7 Days";    break;
        case "quarter": cal.add(Calendar.MONTH, -3);         periodLabel = "Last 3 Months";  break;
        case "year":    cal.add(Calendar.YEAR, -1);          periodLabel = "Last 12 Months"; break;
        default: period = "month"; cal.add(Calendar.MONTH, -1); periodLabel = "Last 30 Days";
    }
    java.sql.Date startDate = new java.sql.Date(cal.getTimeInMillis());

    BigDecimal totalInflow  = saleDAO.getTotalSalesByDateRange(startDate, endDate);
    BigDecimal totalOutflow = expenseDAO.getTotalExpensesByDateRange(startDate, endDate);
    BigDecimal netCashFlow  = totalInflow.subtract(totalOutflow);
    boolean    isPositive   = netCashFlow.compareTo(BigDecimal.ZERO) >= 0;

    List<Object[]> inflowTrend   = saleDAO.getDailySalesForPeriod(startDate, endDate);
    List<Object[]> expByCategory = expenseDAO.getExpensesByCategoryForPeriod(startDate, endDate);
    
    List<Object[]> outflowTrend = expenseDAO.getDailyExpensesForPeriod(startDate, endDate);
    if (outflowTrend == null) outflowTrend = new ArrayList<Object[]>();

    long daysDiff = Math.max((endDate.getTime() - startDate.getTime()) / 86400000L, 1);
    BigDecimal burnRate = BigDecimal.ZERO;
    if (totalOutflow.compareTo(BigDecimal.ZERO) > 0) {
        burnRate = totalOutflow.divide(new BigDecimal(daysDiff), 2, BigDecimal.ROUND_HALF_UP);
    }
    BigDecimal dailyIn = BigDecimal.ZERO;
    if (totalInflow.compareTo(BigDecimal.ZERO) > 0) {
        dailyIn = totalInflow.divide(new BigDecimal(daysDiff), 2, BigDecimal.ROUND_HALF_UP);
    }
    BigDecimal netDailyRate = burnRate.subtract(dailyIn);
    int runwayDays = 0;
    if (netDailyRate.compareTo(BigDecimal.ZERO) > 0 && netCashFlow.compareTo(BigDecimal.ZERO) > 0) {
        runwayDays = netCashFlow.divide(netDailyRate, 0, BigDecimal.ROUND_HALF_UP).intValue();
    }
    BigDecimal outflowRatio = totalInflow.compareTo(BigDecimal.ZERO) > 0
        ? totalOutflow.divide(totalInflow, 4, BigDecimal.ROUND_HALF_UP).multiply(new BigDecimal(100))
        : BigDecimal.ZERO;

    DecimalFormat df = new DecimalFormat("#,##0.00");
    DecimalFormat pf = new DecimalFormat("#,##0.0");
    DecimalFormat sf = new DecimalFormat("#,##0");

    StringBuilder trendLabels = new StringBuilder();
    StringBuilder trendInflow = new StringBuilder();
    StringBuilder trendOutflow = new StringBuilder();
    
    Map<String, BigDecimal> inflowMap = new HashMap<String, BigDecimal>();
    Map<String, BigDecimal> outflowMap = new HashMap<String, BigDecimal>();
    Set<String> allDates = new TreeSet<String>();
    
    for (Object[] row : inflowTrend) {
        String date = row[0].toString();
        BigDecimal amount = (BigDecimal) row[1];
        inflowMap.put(date, amount);
        allDates.add(date);
    }
    
    for (Object[] row : outflowTrend) {
        String date = row[0].toString();
        BigDecimal amount = (BigDecimal) row[1];
        outflowMap.put(date, amount);
        allDates.add(date);
    }
    
    for (String date : allDates) {
        trendLabels.append("'").append(date).append("',");
        
        BigDecimal inflow = inflowMap.get(date);
        if (inflow == null) inflow = BigDecimal.ZERO;
        trendInflow.append(inflow).append(",");
        
        BigDecimal outflow = outflowMap.get(date);
        if (outflow == null) outflow = BigDecimal.ZERO;
        trendOutflow.append(outflow).append(",");
    }
    
    StringBuilder catLabels = new StringBuilder();
    StringBuilder catValues = new StringBuilder();
    for (Object[] row : expByCategory) {
        catLabels.append("'").append(row[0]).append("',");
        catValues.append(row[1]).append(",");
    }

    String initials  = "A";
    String adminName = loggedInUser.getFullName();
    if (adminName != null && !adminName.trim().isEmpty()) {
        String[] parts = adminName.trim().split("\\s+");
        initials = (parts.length >= 2)
            ? "" + parts[0].charAt(0) + parts[1].charAt(0)
            : "" + parts[0].charAt(0);
        initials = initials.toUpperCase();
    }

    String runwayStatus = runwayDays > 60 ? "Healthy" : runwayDays > 30 ? "Monitor" : runwayDays > 0 ? "Critical" : "Stable";
    String runwayColor  = runwayDays > 60 ? "var(--success)" : runwayDays > 30 ? "var(--warning)" : runwayDays > 0 ? "var(--danger)" : "var(--gold)";
    
    int clampedDays = Math.min(Math.max(runwayDays, 0), 90);
    double circumference = 2 * Math.PI * 40;
    double dashOffset = circumference * (1.0 - clampedDays / 90.0);
    
    BigDecimal netProfitMargin = BigDecimal.ZERO;
    if (totalInflow.compareTo(BigDecimal.ZERO) > 0) {
        netProfitMargin = netCashFlow.divide(totalInflow, 4, BigDecimal.ROUND_HALF_UP).multiply(new BigDecimal(100));
    }
    
    BigDecimal expenseRatio = BigDecimal.ZERO;
    if (totalInflow.compareTo(BigDecimal.ZERO) > 0) {
        expenseRatio = totalOutflow.divide(totalInflow, 4, BigDecimal.ROUND_HALF_UP).multiply(new BigDecimal(100));
    }
    
    BigDecimal profitPerDay = dailyIn.subtract(burnRate);
    
    String contextPath = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cash Flow Dashboard — Mpeoa Supermarket ERP</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet"/>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet"/>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600;700;800&family=DM+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet"/>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
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
            --radius:        12px;
            --shadow:        0 2px 16px rgba(18,34,58,0.08);
            --shadow-md:     0 4px 24px rgba(18,34,58,0.12);
            --font-display:  'Playfair Display', Georgia, serif;
            --font-body:     'DM Sans', sans-serif;
            --mono:          'DM Sans', monospace;
        }

        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: var(--font-body); background: var(--cream); color: var(--navy); font-size: 13px; }

        .sidebar {
            position: fixed; top: 0; left: 0; width: var(--sidebar-w); height: 100vh;
            background: var(--navy); display: flex; flex-direction: column; z-index: 1040;
            overflow-y: auto; transition: transform 0.28s ease;
        }
        @media (max-width: 991px) { .sidebar { transform: translateX(-100%); } .sidebar.open { transform: translateX(0); } }

        .sidebar-brand {
            padding: 24px 20px 20px; border-bottom: 1px solid rgba(255,255,255,0.07);
            display: flex; align-items: center; gap: 12px; flex-shrink: 0;
        }
        .sidebar-logo {
            width: 40px; height: 40px; border-radius: 50%;
            border: 1.5px solid rgba(200,146,58,0.5);
            background: rgba(200,146,58,0.12);
            display: flex; align-items: center; justify-content: center;
            font-family: var(--font-display); font-size: 1.1rem; font-weight: 700;
            color: var(--gold-light); flex-shrink: 0;
        }
        .sidebar-brand-text { line-height: 1.2; }
        .sidebar-brand-name { font-family: var(--font-display); font-size: 0.92rem; font-weight: 700; color: var(--white); }
        .sidebar-brand-sub  { font-size: 0.68rem; font-weight: 500; color: rgba(255,255,255,0.38); letter-spacing: 0.08em; text-transform: uppercase; }

        .nav-sec { font-size: 0.65rem; font-weight: 600; letter-spacing: 0.12em; text-transform: uppercase;
                   color: rgba(255,255,255,0.28); padding: 18px 20px 6px; }
        .nav-link-item {
            display: flex; align-items: center; gap: 12px; padding: 11px 20px;
            color: rgba(255,255,255,0.60); text-decoration: none; font-size: 0.88rem; font-weight: 500;
            border-left: 3px solid transparent; transition: all 0.18s;
        }
        .nav-link-item i { font-size: 1rem; width: 18px; text-align: center; }
        .nav-link-item:hover { color: var(--white); background: rgba(255,255,255,0.05); border-left-color: rgba(200,146,58,0.4); }
        .nav-link-item.active { color: var(--gold-light); background: rgba(200,146,58,0.10); border-left-color: var(--gold); font-weight: 600; }

        .sidebar-footer {
            padding: 16px 20px; border-top: 1px solid rgba(255,255,255,0.07);
            display: flex; align-items: center; gap: 10px; margin-top: auto;
        }
        .sf-avatar {
            width: 34px; height: 34px; border-radius: 50%;
            background: var(--gold-pale); border: 1.5px solid rgba(200,146,58,0.4);
            display: flex; align-items: center; justify-content: center;
            font-size: 0.8rem; font-weight: 700; color: var(--gold-light);
        }
        .sf-name { font-size: 0.8rem; font-weight: 600; color: rgba(255,255,255,0.8); }
        .sf-role { font-size: 0.67rem; color: rgba(255,255,255,0.35); text-transform: uppercase; }
        .sf-logout { margin-left: auto; color: rgba(255,255,255,0.3); font-size: 1rem; text-decoration: none; }
        .sf-logout:hover { color: var(--danger); }

        .sidebar-overlay { display: none; position: fixed; inset: 0; background: rgba(18,34,58,0.55); z-index: 1039; backdrop-filter: blur(2px); }
        .sidebar-overlay.show { display: block; }
        .sidebar-close { display: none; position: absolute; top: 18px; right: 14px; background: none; border: none; color: rgba(255,255,255,0.5); font-size: 1.4rem; cursor: pointer; }
        .sidebar-close:hover { color: var(--gold-light); }
        @media (max-width: 991px) { .sidebar-close { display: block; } }

        .main-wrap { margin-left: var(--sidebar-w); min-height: 100vh; }
        @media (max-width: 991px) { .main-wrap { margin-left: 0; } }

        .topbar {
            height: var(--topbar-h); background: rgba(245,240,230,0.92); backdrop-filter: blur(12px);
            border-bottom: 1px solid var(--cream-border); padding: 0 28px;
            display: flex; align-items: center; gap: 16px; position: sticky; top: 0; z-index: 100;
        }
        .burger-btn { display: none; background: none; border: none; color: var(--navy); font-size: 1.35rem; cursor: pointer; }
        .burger-btn:hover { background: var(--gold-pale); border-radius: 6px; }
        @media (max-width: 991px) { .burger-btn { display: flex; } }
        .topbar-title { font-family: var(--font-display); font-size: 1.15rem; font-weight: 700; color: var(--navy); flex: 1; }
        .topbar-period { display: flex; gap: 8px; flex-wrap: wrap; }
        .tp-pill {
            padding: 6px 18px; border-radius: 30px; font-size: 0.75rem; font-weight: 600;
            text-decoration: none; color: var(--navy); background: var(--white);
            border: 1px solid var(--cream-border); transition: all 0.2s;
        }
        .tp-pill:hover { border-color: var(--gold); color: var(--gold); background: var(--gold-pale); }
        .tp-pill.active { background: var(--gold); color: var(--white); border-color: var(--gold); }
        .topbar-avatar { width: 36px; height: 36px; border-radius: 50%; background: var(--navy); display: flex; align-items: center; justify-content: center; font-size: 0.8rem; font-weight: 700; color: var(--gold-light); border: 2px solid var(--cream-border); }

        .page-body { padding: 28px; }
        @media (max-width: 576px) { .page-body { padding: 16px; } }

        .dash-title {
            font-size: 1.7rem; font-family: var(--font-display); font-weight: 700; color: var(--navy); margin-bottom: 20px;
            display: flex; align-items: center; gap: 10px;
        }
        .dash-subtitle { font-size: 0.78rem; color: var(--text-muted); font-weight: 400; }

        .summary-strip {
            display: grid; grid-template-columns: 1fr 1fr 1fr auto;
            gap: 0; background: var(--white); border: 1px solid var(--cream-border);
            border-radius: var(--radius); margin-bottom: 20px; overflow: hidden;
        }
        .ss-box { padding: 0; border-right: 1px solid var(--cream-border); }
        .ss-box:last-child { border-right: none; }
        .ss-head {
            padding: 10px 14px; background: var(--navy); color: var(--white);
            font-size: 0.75rem; font-weight: 600; letter-spacing: 0.05em;
        }
        .ss-head.investing { background: var(--navy-mid); }
        .ss-head.operating { background: var(--navy-light); }
        .ss-head.financing { background: var(--gold); }
        .ss-head.net       { background: var(--navy); }
        .ss-table { width: 100%; border-collapse: collapse; }
        .ss-table th {
            padding: 6px 12px; font-size: 0.68rem; font-weight: 600; color: var(--text-muted);
            border-bottom: 1px solid var(--cream-border); text-align: left; background: var(--cream-dark);
        }
        .ss-table th:last-child { text-align: right; }
        .ss-table td { padding: 6px 12px; font-size: 0.72rem; color: var(--navy); }
        .ss-table td:last-child { text-align: right; font-family: var(--mono); font-weight: 500; }
        .ss-table tr:hover { background: var(--cream); }
        .ss-table .row-total td { font-weight: 700; border-top: 1px solid var(--cream-border); font-size: 0.73rem; background: var(--cream-dark); }
        .ss-table .row-sub td { padding-left: 24px; color: var(--text-muted); font-size: 0.69rem; }
        .net-val { padding: 16px 18px; font-family: var(--font-display); font-size: 1.4rem; font-weight: 700; color: var(--success); white-space: nowrap; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 4px; min-width: 120px; }
        .net-val.neg { color: var(--danger); }
        .net-lbl { font-size: 0.65rem; font-weight: 600; color: var(--text-muted); letter-spacing: 0.05em; text-transform: uppercase; }

        .kpi-strip { display: grid; grid-template-columns: repeat(4,1fr); gap: 16px; margin-bottom: 20px; }
        @media (max-width: 700px) { .kpi-strip { grid-template-columns: repeat(2,1fr); } }

        .kpi-tile { background: var(--white); border: 1px solid var(--cream-border); border-radius: var(--radius); padding: 16px 18px; position: relative; overflow: hidden; transition: transform 0.2s, box-shadow 0.2s; }
        .kpi-tile:hover { transform: translateY(-3px); box-shadow: var(--shadow-md); }
        .kpi-tile::before { content: ''; position: absolute; left: 0; top: 0; bottom: 0; width: 4px; }
        .kpi-tile.gold::before   { background: var(--gold); }
        .kpi-tile.teal::before   { background: var(--success); }
        .kpi-tile.red::before    { background: var(--danger); }
        .kpi-tile.amber::before  { background: var(--warning); }
        .kpi-lbl  { font-size: 0.7rem; font-weight: 600; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.07em; margin-bottom: 8px; }
        .kpi-val  { font-family: var(--font-display); font-size: 1.4rem; font-weight: 700; line-height: 1; }
        .kpi-tile.gold .kpi-val { color: var(--gold); }
        .kpi-tile.teal .kpi-val { color: var(--success); }
        .kpi-tile.red .kpi-val { color: var(--danger); }
        .kpi-tile.amber .kpi-val { color: var(--warning); }
        .kpi-sub  { font-size: 0.7rem; color: var(--text-muted); margin-top: 6px; }

        .ratios-panel {
            background: var(--white); border: 1px solid var(--cream-border);
            border-radius: var(--radius); overflow: hidden; margin-bottom: 20px;
        }
        .ratios-panel .panel-body { padding: 20px; }
        .ratio-card {
            background: var(--cream-dark);
            border-radius: var(--radius);
            padding: 15px;
            height: 100%;
            border-left: 3px solid var(--gold);
        }
        .ratio-title {
            font-size: 0.7rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.08em;
            color: var(--text-muted);
            margin-bottom: 8px;
        }
        .ratio-value {
            font-family: var(--font-display);
            font-size: 1.3rem;
            font-weight: 700;
            color: var(--navy);
        }
        .ratio-interpretation {
            font-size: 0.65rem;
            color: var(--text-muted);
            margin-top: 6px;
        }

        .charts-row { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 20px; }
        @media (max-width: 900px) { .charts-row { grid-template-columns: 1fr; } }
        .bottom-row { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 20px; }
        @media (max-width: 900px) { .bottom-row { grid-template-columns: 1fr; } }

        .panel {
            background: var(--white); border: 1px solid var(--cream-border);
            border-radius: var(--radius); overflow: hidden;
        }
        .panel-head {
            padding: 12px 18px; background: var(--cream-dark); border-bottom: 1px solid var(--cream-border);
            display: flex; justify-content: space-between; align-items: center;
        }
        .panel-title { font-family: var(--font-display); font-size: 0.9rem; font-weight: 700; color: var(--navy); }
        .panel-badge { font-size: 0.65rem; color: var(--text-muted); background: var(--cream); border: 1px solid var(--cream-border); padding: 2px 10px; border-radius: 20px; }
        .panel-body { padding: 18px; }

        .chart-legend { display: flex; gap: 20px; flex-wrap: wrap; margin-bottom: 16px; font-size: 0.72rem; color: var(--text-muted); }
        .leg-dot { width: 10px; height: 10px; border-radius: 2px; display: inline-block; margin-right: 6px; vertical-align: middle; }

        .cat-table { width: 100%; border-collapse: collapse; }
        .cat-table th { font-size: 0.68rem; font-weight: 600; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.06em; padding: 8px 12px; border-bottom: 1px solid var(--cream-border); background: var(--cream-dark); text-align: left; }
        .cat-table th:last-child { text-align: right; }
        .cat-table td { padding: 8px 12px; font-size: 0.75rem; border-bottom: 1px solid var(--cream-border); vertical-align: middle; }
        .cat-table td:last-child { text-align: right; font-family: var(--mono); }
        .cat-table tr:last-child td { border-bottom: none; }
        .cat-table tr:hover { background: var(--cream); }
        .dot-sm { width: 8px; height: 8px; border-radius: 50%; display: inline-block; margin-right: 8px; vertical-align: middle; }
        .bar-cell { width: 100px; }
        .mini-bar { height: 6px; border-radius: 3px; background: var(--cream-border); overflow: hidden; }
        .mini-fill { height: 100%; border-radius: 3px; background: var(--gold); }

        .runway-panel { display: flex; align-items: center; gap: 24px; padding: 18px; }
        .gauge-wrap { width: 120px; height: 120px; position: relative; flex-shrink: 0; }
        .gauge-wrap svg { position: absolute; inset: 0; }
        .gauge-inner { position: absolute; inset: 0; display: flex; flex-direction: column; align-items: center; justify-content: center; }
        .gauge-num { font-family: var(--font-display); font-size: 1.6rem; font-weight: 700; line-height: 1; }
        .gauge-unit { font-size: 0.65rem; color: var(--text-muted); text-transform: uppercase; }
        .runway-info { flex: 1; }
        .runway-status { display: inline-block; font-size: 0.7rem; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase; padding: 4px 14px; border-radius: 20px; margin-bottom: 10px; }
        .rs-healthy  { background: var(--success-pale); color: var(--success); }
        .rs-monitor  { background: var(--warning-pale); color: var(--warning); }
        .rs-critical { background: var(--danger-pale); color: var(--danger); }
        .rs-stable   { background: var(--gold-pale); color: var(--gold); }
        .runway-metrics { display: flex; flex-direction: column; gap: 8px; }
        .rm-row { display: flex; justify-content: space-between; font-size: 0.75rem; color: var(--text-muted); }
        .rm-row strong { color: var(--navy); font-family: var(--mono); }

        .insight-strip { display: grid; grid-template-columns: repeat(2,1fr); gap: 16px; margin-top: 20px; }
        @media (max-width: 600px) { .insight-strip { grid-template-columns: 1fr; } }
        .ins-tile { background: var(--cream-dark); border: 1px solid var(--cream-border); border-radius: var(--radius); padding: 14px 16px; font-size: 0.78rem; color: var(--text-muted); line-height: 1.5; }
        .ins-tile strong { color: var(--navy); }
        .ins-header { font-size: 0.7rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.06em; margin-bottom: 6px; display: flex; align-items: center; gap: 8px; }

        @keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
        .anim { animation: fadeIn 0.3s ease both; }
        .d1 { animation-delay: 0.05s; } .d2 { animation-delay: 0.10s; } .d3 { animation-delay: 0.15s; } .d4 { animation-delay: 0.20s; }
        
        .text-danger { color: var(--danger); }
        .text-success { color: var(--success); }
        .text-warning { color: var(--warning); }
        .text-gold { color: var(--gold); }
    </style>
</head>
<body>

<div class="sidebar-overlay" id="sidebarOverlay" onclick="closeSidebar()"></div>

<aside class="sidebar" id="sidebar">
    <button class="sidebar-close" onclick="closeSidebar()"><i class="bi bi-x-lg"></i></button>
    <div class="sidebar-brand">
        <div class="sidebar-logo">MS</div>
        <div class="sidebar-brand-text">
            <div class="sidebar-brand-name">Mpeoa Supermarket</div>
            <div class="sidebar-brand-sub">Admin Portal</div>
        </div>
    </div>
    <nav style="padding: 8px 0; flex: 1;">
        <div class="nav-sec">Main</div>
        <a href="<%= contextPath %>/admin/dashboard" class="nav-link-item"><i class="bi bi-grid-1x2-fill"></i> Dashboard</a>
        <div class="nav-sec">Management</div>
        <a href="<%= contextPath %>/admin/users.jsp" class="nav-link-item"><i class="bi bi-people-fill"></i> Users</a>
        <a href="<%= contextPath %>/admin/products.jsp" class="nav-link-item"><i class="bi bi-box-seam-fill"></i> Products</a>
        <a href="<%= contextPath %>/admin/inventory.jsp" class="nav-link-item"><i class="bi bi-archive-fill"></i> Inventory</a>
        <a href="<%= contextPath %>/admin/categories.jsp" class="nav-link-item"><i class="bi bi-tags-fill"></i> Categories</a>
        <div class="nav-sec">Operations</div>
        <a href="<%= contextPath %>/admin/sales.jsp" class="nav-link-item"><i class="bi bi-receipt"></i> Sales</a>
        <a href="<%= contextPath %>/admin/expenses.jsp" class="nav-link-item"><i class="bi bi-wallet2"></i> Expenses</a>
        <a href="<%= contextPath %>/admin/suppliers.jsp" class="nav-link-item"><i class="bi bi-truck"></i> Suppliers</a>
        <a href="<%= contextPath %>/admin/purchases.jsp" class="nav-link-item"><i class="bi bi-cart-fill"></i> Purchases</a>
        <div class="nav-sec">Insights</div>
        <a href="<%= contextPath %>/admin/bi_dashboard.jsp" class="nav-link-item"><i class="bi bi-graph-up"></i> BI &amp; Finance</a>
        <a href="<%= contextPath %>/admin/cashflow_dashboard.jsp" class="nav-link-item active"><i class="bi bi-arrow-left-right"></i> Cash Flow</a>
        <a href="<%= contextPath %>/admin/sales_dashboard.jsp" class="nav-link-item"><i class="bi bi-bar-chart-line-fill"></i> Sales BI</a>
        <a href="<%= contextPath %>/admin/reports.jsp" class="nav-link-item"><i class="bi bi-file-text-fill"></i> Reports</a>
        <a href="<%= contextPath %>/admin/analytics.jsp" class="nav-link-item"><i class="bi bi-bar-chart-steps"></i> Analytics</a>
        <div class="nav-sec">System</div>
        <a href="<%= contextPath %>/admin/settings.jsp" class="nav-link-item"><i class="bi bi-gear-fill"></i> Settings</a>
        <a href="<%= contextPath %>/admin/security.jsp" class="nav-link-item"><i class="bi bi-shield-lock-fill"></i> Security</a>
        <a href="<%= contextPath %>/admin/backup.jsp" class="nav-link-item"><i class="bi bi-database-fill"></i> Backup</a>
    </nav>
    <div class="sidebar-footer">
        <div class="sf-avatar"><%= initials %></div>
        <div>
            <div class="sf-name"><%= adminName != null ? adminName : "Administrator" %></div>
            <div class="sf-role">Administrator</div>
        </div>
        <a href="<%= contextPath %>/logout" class="sf-logout" title="Logout"><i class="bi bi-box-arrow-right"></i></a>
    </div>
</aside>

<div class="main-wrap">
    <header class="topbar">
        <button class="burger-btn" onclick="openSidebar()"><i class="bi bi-list"></i></button>
        <span class="topbar-title">Cash Flow Dashboard</span>
        <div class="topbar-period">
            <a href="?period=week"    class="tp-pill <%= "week".equals(period) ? "active" : "" %>">7 Days</a>
            <a href="?period=month"   class="tp-pill <%= "month".equals(period) ? "active" : "" %>">30 Days</a>
            <a href="?period=quarter" class="tp-pill <%= "quarter".equals(period) ? "active" : "" %>">Quarter</a>
            <a href="?period=year"    class="tp-pill <%= "year".equals(period) ? "active" : "" %>">Year</a>
        </div>
        <div class="topbar-avatar"><%= initials %></div>
    </header>

    <main class="page-body">

        <div class="dash-title anim">
            Cash Flow Dashboard
            <span class="dash-subtitle">— <%= periodLabel %></span>
        </div>

        <!-- Summary Strip -->
        <div class="summary-strip anim d1">
            
            <div class="ss-box">
                <div class="ss-head operating">Operating Activities</div>
                <table class="ss-table">
                    <thead><tr><th>Description</th><th>Sum (R)</th></tr></thead>
                    <tbody>
                        <tr><td><strong>Cash Inflow</strong></td<td class="text-success">+R <%= df.format(totalInflow) %></td</tr>
                        <tr class="row-sub"><td>Sales revenue (customer payments)</td><td class="text-success">+R <%= df.format(totalInflow) %></td</tr>
                        <tr><td><strong>Cash Outflow</strong></td<td class="text-danger">-R <%= df.format(totalOutflow) %></td</tr>
                        <% if (expByCategory != null && !expByCategory.isEmpty()) { 
                            int maxRows = 3; int ri = 0;
                            for (Object[] row : expByCategory) {
                                if (ri >= maxRows) break;
                                BigDecimal amt = (BigDecimal) row[1];
                        %>
                        <tr class="row-sub"><td><%= row[0] %></td><td class="text-danger">-R <%= df.format(amt) %></td</tr>
                        <% ri++; } 
                        if (expByCategory.size() > 3) { %>
                        <tr class="row-sub"><td><em>+ <%= (expByCategory.size() - 3) %> more categories</em></td><td>—</td</tr>
                        <% } } else { %>
                        <tr class="row-sub"><td>No expenses recorded</td><td>—</td</tr>
                        <% } %>
                        <tr class="row-total"><td><strong>Net Operating Cash Flow</strong></td>
                            <td class="<%= netCashFlow.compareTo(BigDecimal.ZERO) >= 0 ? "text-success" : "text-danger" %>">
                                <%= netCashFlow.compareTo(BigDecimal.ZERO) >= 0 ? "+" : "" %>R <%= df.format(netCashFlow) %>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <div class="ss-box">
                <div class="ss-head" style="background: var(--gold); color: var(--navy);">Top Expenses</div>
                <table class="ss-table">
                    <thead><tr><th>Category</th><th>Amount (R)</th></tr></thead>
                    <tbody>
                        <% if (expByCategory != null && !expByCategory.isEmpty()) { 
                            int count = 0;
                            for (Object[] row : expByCategory) {
                                if (count >= 5) break;
                                BigDecimal amt = (BigDecimal) row[1];
                        %>
                        <tr><td><%= row[0] %></td><td class="text-danger">R <%= df.format(amt) %></td</tr>
                        <% count++; } 
                        } else { %>
                        <tr><td colspan="2" style="text-align:center;">No expenses recorded</td></tr>
                        <% } %>
                        <tr class="row-total"><td><strong>Total Expenses</strong></td><td class="text-danger">R <%= df.format(totalOutflow) %></td</tr>
                    </tbody>
                </table>
            </div>

            <div class="ss-box">
                <div class="ss-head" style="background: var(--navy-light);">Key Metrics</div>
                <table class="ss-table">
                    <thead><tr><th>Metric</th><th>Value</th></tr></thead>
                    <tbody>
                        <tr><td>Total Sales</td><td class="text-success">R <%= df.format(totalInflow) %></td</tr>
                        <tr><td>Total Expenses</td><td class="text-danger">R <%= df.format(totalOutflow) %></td</tr>
                        <tr><td>Net Profit</td>
                            <td class="<%= netCashFlow.compareTo(BigDecimal.ZERO) >= 0 ? "text-success" : "text-danger" %>">
                                <%= netCashFlow.compareTo(BigDecimal.ZERO) >= 0 ? "+" : "" %>R <%= df.format(netCashFlow) %>
                            </td>
                        </tr>
                        <tr><td>Profit Margin</td>
                            <td><% if (totalInflow.compareTo(BigDecimal.ZERO) > 0) { 
                                    BigDecimal margin = netCashFlow.divide(totalInflow, 4, BigDecimal.ROUND_HALF_UP).multiply(new BigDecimal(100));
                                %>
                                <%= pf.format(margin) %>%
                                <% } else { %>0%<% } %>
                            </td>
                        </tr>
                        <tr><td>Period</td><td><%= periodLabel %></td</tr>
                    </tbody>
                </table>
            </div>

            <div class="ss-box" style="min-width: 130px;">
                <div class="ss-head net">Net Cash Flow</div>
                <div class="net-val <%= netCashFlow.compareTo(BigDecimal.ZERO) >= 0 ? "" : "neg" %>">
                    <div class="net-lbl">Total</div>
                    <%= netCashFlow.compareTo(BigDecimal.ZERO) >= 0 ? "+" : "" %>R <%= df.format(netCashFlow) %>
                </div>
                <div style="padding: 8px 12px; text-align: center; font-size: 0.65rem;">
                    <%= periodLabel %>
                </div>
            </div>
            
        </div>

        <!-- KPI Strip -->
        <div class="kpi-strip anim d2">
            <div class="kpi-tile teal"><div class="kpi-lbl">Cash Inflow</div><div class="kpi-val">R <%= df.format(totalInflow) %></div><div class="kpi-sub">Total received · <%= periodLabel %></div></div>
            <div class="kpi-tile red"><div class="kpi-lbl">Cash Outflow</div><div class="kpi-val">R <%= df.format(totalOutflow) %></div><div class="kpi-sub">Total operational expenses</div></div>
            <div class="kpi-tile <%= isPositive ? "teal" : "red" %>"><div class="kpi-lbl">Net Position</div><div class="kpi-val"><%= isPositive ? "+" : "" %>R <%= df.format(netCashFlow) %></div><div class="kpi-sub"><%= isPositive ? "Positive cash flow" : "Deficit - review spend" %></div></div>
            <div class="kpi-tile amber"><div class="kpi-lbl">Daily Burn Rate</div><div class="kpi-val">R <%= df.format(burnRate) %></div><div class="kpi-sub">Average daily outflow</div></div>
        </div>

        <!-- Financial Ratios Section -->
        <div class="ratios-panel anim d3">
            <div class="panel-head">
                <span class="panel-title"><i class="bi bi-calculator-fill"></i> Financial Ratios & Analysis</span>
                <span class="panel-badge">Based on sales & expenses</span>
            </div>
            <div class="panel-body">
                <div class="row g-3">
                    <div class="col-md-3 col-sm-6">
                        <div class="ratio-card" style="border-left-color: var(--success);">
                            <div class="ratio-title">Net Profit Margin</div>
                            <div class="ratio-value"><%= pf.format(netProfitMargin) %>%
                                <% if (netProfitMargin.compareTo(new BigDecimal("20")) >= 0) { %>
                                    <span class="text-success">✓ Excellent</span>
                                <% } else if (netProfitMargin.compareTo(new BigDecimal("10")) >= 0) { %>
                                    <span class="text-success">✓ Good</span>
                                <% } else if (netProfitMargin.compareTo(BigDecimal.ZERO) > 0) { %>
                                    <span class="text-warning">⚠ Low</span>
                                <% } else { %>
                                    <span class="text-danger">❌ Loss</span>
                                <% } %>
                            </div>
                            <div class="ratio-interpretation">
                                <% if (netProfitMargin.compareTo(BigDecimal.ZERO) > 0) { %>
                                    R<%= pf.format(netProfitMargin) %> profit per R100 of sales
                                <% } else { %>
                                    Business is operating at a loss
                                <% } %>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3 col-sm-6">
                        <div class="ratio-card" style="border-left-color: var(--danger);">
                            <div class="ratio-title">Expense Ratio</div>
                            <div class="ratio-value"><%= pf.format(expenseRatio) %>%
                                <% if (expenseRatio.compareTo(new BigDecimal("70")) < 0) { %>
                                    <span class="text-success">✓ Low</span>
                                <% } else if (expenseRatio.compareTo(new BigDecimal("85")) < 0) { %>
                                    <span class="text-warning">● Medium</span>
                                <% } else { %>
                                    <span class="text-danger">⚠ High</span>
                                <% } %>
                            </div>
                            <div class="ratio-interpretation">R<%= pf.format(expenseRatio) %> spent on expenses per R100 of sales</div>
                        </div>
                    </div>
                    <div class="col-md-3 col-sm-6">
                        <div class="ratio-card" style="border-left-color: var(--info);">
                            <div class="ratio-title">Profit per Day</div>
                            <div class="ratio-value"><%= profitPerDay.compareTo(BigDecimal.ZERO) >= 0 ? "+" : "" %>R <%= df.format(profitPerDay) %>
                                <% if (profitPerDay.compareTo(new BigDecimal("100")) >= 0) { %>
                                    <span class="text-success">✓ Strong</span>
                                <% } else if (profitPerDay.compareTo(BigDecimal.ZERO) > 0) { %>
                                    <span class="text-warning">● Moderate</span>
                                <% } else { %>
                                    <span class="text-danger">⚠ Loss</span>
                                <% } %>
                            </div>
                            <div class="ratio-interpretation">Daily profit after expenses</div>
                        </div>
                    </div>
                    <div class="col-md-3 col-sm-6">
                        <div class="ratio-card" style="border-left-color: var(--gold);">
                            <div class="ratio-title">Operating Efficiency</div>
                            <div class="ratio-value"><%= pf.format(profitPerDay.compareTo(BigDecimal.ZERO) > 0 ? profitPerDay.multiply(new BigDecimal("365")).divide(totalInflow, 2, BigDecimal.ROUND_HALF_UP).multiply(new BigDecimal("100")) : BigDecimal.ZERO) %>%</div>
                            <div class="ratio-interpretation">Return on daily operations</div>
                        </div>
                    </div>
                </div>
                <div class="alert alert-info mt-3" style="background: var(--info-pale); border-color: var(--info-pale); font-size:0.72rem; padding: 12px; margin-bottom: 0;">
                    <i class="bi bi-chat-dots-fill me-2"></i>
                    <strong>What these ratios tell you:</strong>
                    <% if (netProfitMargin.compareTo(new BigDecimal("10")) >= 0) { %>
                        ✓ Your business has good profitability. Keep it up!
                    <% } else if (netProfitMargin.compareTo(BigDecimal.ZERO) > 0) { %>
                        ⚠ Your profit margin is low. Consider reducing expenses or increasing prices.
                    <% } else { %>
                        ❌ Your business is losing money. Review expenses immediately!
                    <% } %>
                    <% if (expenseRatio.compareTo(new BigDecimal("80")) > 0) { %>
                        &nbsp;| ⚠ Expenses are too high (over 80% of sales). Look for ways to cut costs.
                    <% } else if (expenseRatio.compareTo(new BigDecimal("60")) < 0) { %>
                        &nbsp;| ✓ Excellent expense control!
                    <% } %>
                </div>
            </div>
        </div>

        <!-- Charts Row -->
        <div class="charts-row anim d4">
            <div class="panel">
                <div class="panel-head">
                    <span class="panel-title">Cash Flow Trend</span>
                    <span class="panel-badge"><%= periodLabel %></span>
                </div>
                <div class="panel-body">
                    <div class="chart-legend">
                        <span><span class="leg-dot" style="background:var(--success)"></span>Inflow (Sales)</span>
                        <span><span class="leg-dot" style="background:var(--danger)"></span>Outflow (Expenses)</span>
                        <span><span class="leg-dot" style="background:var(--gold)"></span>Net Cash Flow</span>
                    </div>
                    <div style="height:260px; position:relative;">
                        <canvas id="trendChart"></canvas>
                    </div>
                    <div class="text-muted small mt-2"><i class="bi bi-info-circle"></i> Outflow shows actual expenses from your database</div>
                </div>
            </div>

            <div class="panel">
                <div class="panel-head">
                    <span class="panel-title">Structure of Spendings</span>
                    <span class="panel-badge">By category</span>
                </div>
                <div class="panel-body">
                    <div style="position:relative; height:220px; width:100%; margin-bottom:20px;">
                        <canvas id="spendDonut"></canvas>
                        <div style="position:absolute; inset:0; display:flex; align-items:center; justify-content:center; flex-direction:column; pointer-events:none;">
                            <span style="font-family:var(--font-display); font-size:1.2rem; font-weight:700; color:var(--navy);">R <%= sf.format(totalOutflow) %></span>
                            <span style="font-size:0.65rem; color:var(--text-muted);">Total spend</span>
                        </div>
                    </div>
                    <div id="spendLegend" style="font-size:0.72rem; color:var(--text-muted); display:flex; flex-wrap:wrap; justify-content:center; gap:12px;"></div>
                </div>
            </div>
        </div>

        <!-- Bottom Row -->
        <div class="bottom-row anim" style="animation-delay:0.20s;">
            <div class="panel">
                <div class="panel-head">
                    <span class="panel-title">Dynamic Structure of Spendings</span>
                    <span class="panel-badge">Category breakdown</span>
                </div>
                <div class="panel-body" style="padding:0;">
                    <% if (expByCategory != null && !expByCategory.isEmpty()) {
                        String[] catColors = {"var(--gold)","var(--success)","var(--warning)","var(--danger)","#AB47BC","#42A5F5"};
                        BigDecimal maxCat = BigDecimal.ONE;
                        for (Object[] row : expByCategory) { BigDecimal v = new BigDecimal(row[1].toString()); if (v.compareTo(maxCat) > 0) maxCat = v; }
                    %>
                    <table class="cat-table">
                        <thead><tr><th>Category</th><th class="bar-cell">Share</th><th>Amount (R)</th></tr></thead>
                        <tbody>
                        <% int ci=0; for (Object[] row : expByCategory) {
                            BigDecimal cv = new BigDecimal(row[1].toString());
                            int pct = cv.multiply(new BigDecimal(100)).divide(maxCat,0,BigDecimal.ROUND_HALF_UP).intValue();
                            String cc = catColors[ci % catColors.length]; %>
                            <tr>
                                <td><span class="dot-sm" style="background:<%= cc %>"></span><%= row[0] %></td>
                                <td class="bar-cell"><div class="mini-bar"><div class="mini-fill" style="width:<%= pct %>%;background:<%= cc %>"></div></div></td>
                                <td><%= df.format(cv) %></td>
                            </tr>
                        <% ci++; } %>
                        </tbody>
                    </table>
                    <% } else { %>
                    <div style="padding:30px; text-align:center; color:var(--text-muted);">No expense data available.</div>
                    <% } %>
                </div>
            </div>

            <div style="display:flex; flex-direction:column; gap:20px;">
                <div class="panel" style="flex:1;">
                    <div class="panel-head">
                        <span class="panel-title">Structure of Income</span>
                        <span class="panel-badge">Inflow vs Outflow</span>
                    </div>
                    <div class="panel-body" style="display:flex; gap:20px; align-items:center; flex-wrap:wrap;">
                        <div style="position:relative; height:180px; width:180px; flex-shrink:0;">
                            <canvas id="incomeDonut" style="width:100%; height:100%;"></canvas>
                            <div style="position:absolute; inset:0; display:flex; align-items:center; justify-content:center; flex-direction:column; pointer-events:none; text-align:center; padding:10px;">
                                <span style="font-family:var(--font-display); font-size:1.1rem; font-weight:700; color:var(--navy);">R <%= sf.format(totalInflow) %></span>
                                <span style="font-size:0.65rem; color:var(--text-muted);">Total inflow</span>
                            </div>
                        </div>
                        <div style="display:flex; flex-direction:column; gap:10px;">
                            <div style="display:flex; align-items:center; gap:10px; color:var(--text-muted);">
                                <span style="background:var(--success); width:12px; height:12px; display:inline-block; border-radius:50%;"></span>
                                <span>Inflow (Sales)</span>
                            </div>
                            <div style="display:flex; align-items:center; gap:10px; color:var(--text-muted);">
                                <span style="background:var(--danger); width:12px; height:12px; display:inline-block; border-radius:50%;"></span>
                                <span>Outflow (Expenses)</span>
                            </div>
                            <div style="display:flex; align-items:center; gap:10px; color:var(--text-muted);">
                                <span style="background:var(--gold); width:12px; height:12px; display:inline-block; border-radius:50%;"></span>
                                <span>Net Cash Flow</span>
                            </div>
                        </div>
                    </div>
                    <div style="padding:0 18px 14px; font-size:0.72rem; color:var(--text-muted); text-align:center;">
                        Outflow is <strong style="color:var(--navy)"><%= pf.format(outflowRatio) %>%</strong> of total inflow
                    </div>
                </div>

                <div class="panel">
                    <div class="panel-head">
                        <span class="panel-title">Cash Runway</span>
                    </div>
                    <div class="runway-panel">
                        <div class="gauge-wrap" style="width:120px;height:120px;">
                            <svg width="120" height="120" viewBox="0 0 120 120">
                                <circle cx="60" cy="60" r="50" fill="none" stroke="var(--cream-border)" stroke-width="8"/>
                                <circle cx="60" cy="60" r="50" fill="none" stroke="<%= runwayColor %>"
                                    stroke-width="8" stroke-linecap="round"
                                    stroke-dasharray="<%= String.format("%.2f", circumference) %>"
                                    stroke-dashoffset="<%= String.format("%.2f", dashOffset) %>"
                                    transform="rotate(-90 60 60)"/>
                            </svg>
                            <div class="gauge-inner">
                                <div class="gauge-num" style="color:<%= runwayColor %>"><%= runwayDays > 0 ? sf.format(runwayDays) : "∞" %></div>
                                <div class="gauge-unit">days</div>
                            </div>
                        </div>
                        <div class="runway-info">
                            <div class="runway-status rs-<%= runwayStatus.toLowerCase() %>"><%= runwayStatus %></div>
                            <div class="runway-metrics">
                                <div class="rm-row"><span>Daily inflow</span><strong>R <%= df.format(dailyIn) %></strong></div>
                                <div class="rm-row"><span>Burn rate</span><strong>R <%= df.format(burnRate) %></strong></div>
                                <div class="rm-row"><span>Net daily</span><strong><%= isPositive?"+":"" %>R <%= df.format(dailyIn.subtract(burnRate).abs()) %></strong></div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Insight tiles -->
        <div class="insight-strip anim" style="animation-delay:0.25s;">
            <div class="ins-tile"><div class="ins-header" style="color:var(--success)"><i class="bi bi-arrow-down-circle-fill"></i> Inflow Summary</div>Total cash received was <strong>R <%= df.format(totalInflow) %></strong> over <%= periodLabel.toLowerCase() %>. Daily average: <strong>R <%= df.format(dailyIn) %></strong>.</div>
            <div class="ins-tile"><div class="ins-header" style="color:var(--danger)"><i class="bi bi-arrow-up-circle-fill"></i> Outflow Summary</div>Total expenses <strong>R <%= df.format(totalOutflow) %></strong>. Burn rate <strong>R <%= df.format(burnRate) %>/day</strong> — <%= burnRate.compareTo(dailyIn) < 0 ? "within healthy range." : "exceeds daily inflow. Reduce spend urgently." %></div>
            <div class="ins-tile"><div class="ins-header" style="color:<%= isPositive ? "var(--success)" : "var(--danger)" %>"><i class="bi bi-<%= isPositive ? "check-circle-fill" : "exclamation-triangle-fill" %>"></i> Net Position</div><%= isPositive ? "Positive" : "Negative" %> cash flow of <strong>R <%= df.format(netCashFlow) %></strong>. <%= isPositive ? "Business generates more than it spends." : "Urgent: outflow exceeds inflow. Review expense categories." %></div>
            <div class="ins-tile"><div class="ins-header" style="color:var(--warning)"><i class="bi bi-hourglass-split"></i> Runway Forecast</div><%= runwayDays > 0 ? "Estimated runway <strong>" + sf.format(runwayDays) + " days</strong> at current rates. " + (runwayDays > 60 ? "Healthy position." : runwayDays > 30 ? "Monitor and reduce discretionary spend." : "Critical - take immediate action.") : "Inflow meets or exceeds outflow - the business is <strong>self-sustaining</strong>." %></div>
        </div>

    </main>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
    function openSidebar()  { document.getElementById('sidebar').classList.add('open'); document.getElementById('sidebarOverlay').classList.add('show'); document.body.style.overflow='hidden'; }
    function closeSidebar() { document.getElementById('sidebar').classList.remove('open'); document.getElementById('sidebarOverlay').classList.remove('show'); document.body.style.overflow=''; }
    document.addEventListener('keydown', e => { if(e.key==='Escape') closeSidebar(); });

    Chart.defaults.color = '#6B6670';
    Chart.defaults.font.family = "'DM Sans', sans-serif";
    Chart.defaults.font.size = 11;

    const trendLabels = [<%= trendLabels.toString().replaceAll(",$","") %>];
    const inflowData   = [<%= trendInflow.toString().replaceAll(",$","") %>];
    const outflowData  = [<%= trendOutflow.toString().replaceAll(",$","") %>];
    const netData = inflowData.map((v, i) => v - outflowData[i]);

    const trendCtx = document.getElementById('trendChart').getContext('2d');
    new Chart(trendCtx, {
        data: {
            labels: trendLabels,
            datasets: [
                { type: 'bar', label: 'Outflow (Expenses)', data: outflowData, backgroundColor: 'rgba(192,57,43,0.7)', borderWidth: 0, barPercentage: 0.6, borderRadius: 4 },
                { type: 'bar', label: 'Inflow (Sales)', data: inflowData, backgroundColor: 'rgba(46,125,82,0.7)', borderWidth: 0, barPercentage: 0.6, borderRadius: 4 },
                { type: 'line', label: 'Net Cash Flow', data: netData, borderColor: '#C8923A', backgroundColor: 'transparent', tension: 0.35, pointRadius: 4, pointHoverRadius: 6, pointBackgroundColor: '#C8923A', borderWidth: 2, fill: false, yAxisID: 'y' },
                { type: 'line', label: 'Zero', data: inflowData.map(() => 0), borderColor: '#DDD8CE', backgroundColor: 'transparent', borderDash: [4,4], pointRadius: 0, borderWidth: 1, yAxisID: 'y', fill: false }
            ]
        },
        options: {
            responsive: true, maintainAspectRatio: false, interaction: { mode: 'index', intersect: false },
            plugins: { legend: { display: false }, tooltip: { backgroundColor: '#fff', borderColor: '#DDD8CE', borderWidth: 1, titleColor: '#12223A', bodyColor: '#6B6670', padding: 10, callbacks: { label: function(ctx) { return (ctx.dataset.label || '') + ': R ' + Number(ctx.raw).toLocaleString('en-ZA', {minimumFractionDigits:2}); } } } },
            scales: { x: { grid: { color: '#EDE6D4' }, ticks: { maxRotation: 45 } }, y: { grid: { color: '#EDE6D4' }, ticks: { callback: function(v) { if (v >= 1000000) return 'R ' + (v/1000000).toFixed(1) + 'M'; if (v >= 1000) return 'R ' + (v/1000).toFixed(0) + 'K'; return 'R ' + v; } }, title: { display: true, text: 'Amount (R)', color: '#6B6670' } } }
        }
    });

    const catLabels = [<%= catLabels.toString().replaceAll(",$","") %>];
    const catValues = [<%= catValues.toString().replaceAll(",$","") %>];
    const palette = ['#C8923A','#2E7D52','#D4A42B','#C0392B','#AB47BC','#42A5F5','#78909C'];

    if (catValues.length > 0) {
        new Chart(document.getElementById('spendDonut').getContext('2d'), {
            type: 'doughnut',
            data: { labels: catLabels, datasets: [{ data: catValues, backgroundColor: palette, borderWidth: 2, borderColor: '#fff', hoverOffset: 5 }] },
            options: { responsive: true, maintainAspectRatio: false, cutout: '65%', plugins: { legend: { display: false }, tooltip: { backgroundColor:'#fff', borderColor:'#DDD8CE', borderWidth:1, titleColor:'#12223A', bodyColor:'#6B6670', callbacks: { label: function(ctx) { let value = ctx.raw; let total = ctx.dataset.data.reduce((a,b) => a + b, 0); let pct = ((value / total) * 100).toFixed(1); return ' R ' + value.toLocaleString('en-ZA',{minimumFractionDigits:2}) + ' (' + pct + '%)'; } } } } }
        });
        const leg = document.getElementById('spendLegend');
        catLabels.forEach((l,i) => { leg.innerHTML += '<div class="leg-item"><span style="display:inline-block;width:12px;height:12px;border-radius:50%;background:' + palette[i%palette.length] + ';margin-right:8px;"></span>' + l + '</div>'; });
    }

    const inflowVal = <%= totalInflow %>;
    const outflowVal = <%= totalOutflow %>;
    const netVal = Math.max(<%= netCashFlow %>, 0);
    
    new Chart(document.getElementById('incomeDonut').getContext('2d'), {
        type: 'doughnut',
        data: { labels: ['Inflow','Outflow','Net'], datasets: [{ data: [inflowVal, outflowVal, netVal], backgroundColor: ['#2E7D52','#C0392B','#C8923A'], borderWidth: 2, borderColor: '#fff', hoverOffset: 4 }] },
        options: { responsive: true, maintainAspectRatio: false, cutout: '65%', plugins: { legend: { display: false }, tooltip: { backgroundColor:'#fff', borderColor:'#DDD8CE', borderWidth:1, titleColor:'#12223A', bodyColor:'#6B6670', callbacks: { label: function(ctx) { let value = ctx.raw; let total = ctx.dataset.data.reduce((a,b) => a + b, 0); let pct = total > 0 ? ((value / total) * 100).toFixed(1) : 0; return ' R ' + value.toLocaleString('en-ZA',{minimumFractionDigits:2}) + ' (' + pct + '%)'; } } } } }
    });
</script>
</body>
</html>