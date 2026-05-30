<%-- web/admin/view-purchase.jsp --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="mpeoa.models.Purchase, mpeoa.models.User, java.text.*" %>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    
    Purchase purchase = (Purchase) request.getAttribute("purchase");
    if (purchase == null) {
        response.sendRedirect(request.getContextPath() + "/admin/purchases.jsp");
        return;
    }
    
    DecimalFormat df = new DecimalFormat("#,##0.00");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>View Purchase Order</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet"/>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet"/>
    <style>
        body { background: #F5F0E6; font-family: 'DM Sans', sans-serif; }
        .container { max-width: 600px; margin: 50px auto; }
        .card { border-radius: 12px; box-shadow: 0 2px 16px rgba(18,34,58,0.08); border: 1px solid #DDD8CE; }
        .card-header { background: #EDE6D4; border-bottom: 1px solid #DDD8CE; font-family: 'Playfair Display', serif; font-weight: 700; padding: 16px 20px; }
        .info-row { display: flex; padding: 12px 0; border-bottom: 1px solid #DDD8CE; }
        .info-label { width: 140px; font-weight: 600; color: #12223A; }
        .info-value { flex: 1; color: #12223A; }
        .badge-paid { background: rgba(46,125,82,0.1); color: #2E7D52; padding: 4px 8px; border-radius: 12px; }
        .badge-pending { background: rgba(212,164,43,0.1); color: #D4A42B; padding: 4px 8px; border-radius: 12px; }
        .btn-back { background: #C8923A; color: white; border: none; border-radius: 8px; padding: 10px 24px; text-decoration: none; display: inline-block; }
        .btn-back:hover { background: #DBA85A; color: white; }
    </style>
</head>
<body>
    <div class="container">
        <div class="card">
            <div class="card-header">
                <i class="bi bi-receipt"></i> Purchase Order Details
            </div>
            <div class="card-body p-4">
                <div class="info-row">
                    <div class="info-label">PO Number:</div>
                    <div class="info-value"><strong><%= purchase.getPurchaseOrderNumber() %></strong></div>
                </div>
                <div class="info-row">
                    <div class="info-label">Purchase Date:</div>
                    <div class="info-value"><%= purchase.getPurchaseDate() != null ? purchase.getPurchaseDate() : "-" %></div>
                </div>
                <div class="info-row">
                    <div class="info-label">Supplier:</div>
                    <div class="info-value"><%= purchase.getSupplierName() != null ? purchase.getSupplierName() : "-" %></div>
                </div>
                <div class="info-row">
                    <div class="info-label">Total Amount:</div>
                    <div class="info-value"><strong>R <%= df.format(purchase.getTotalAmount() != null ? purchase.getTotalAmount() : 0) %></strong></div>
                </div>
                <div class="info-row">
                    <div class="info-label">Payment Status:</div>
                    <div class="info-value">
                        <% if ("Paid".equalsIgnoreCase(purchase.getPaymentStatus())) { %>
                            <span class="badge-paid">Paid</span>
                        <% } else { %>
                            <span class="badge-pending">Pending</span>
                        <% } %>
                    </div>
                </div>
                <div class="info-row">
                    <div class="info-label">Delivered By:</div>
                    <div class="info-value"><%= purchase.getDeliveredBy() != null && !purchase.getDeliveredBy().isEmpty() ? purchase.getDeliveredBy() : "-" %></div>
                </div>
                <div class="info-row">
                    <div class="info-label">Received By:</div>
                    <div class="info-value"><%= purchase.getReceivedByName() != null ? purchase.getReceivedByName() : "-" %></div>
                </div>
                <div class="info-row">
                    <div class="info-label">Created Date:</div>
                    <div class="info-value"><%= purchase.getCreatedAt() != null ? purchase.getCreatedAt().toString() : "-" %></div>
                </div>
                
                <div class="mt-4 d-flex gap-2">
                    <a href="${pageContext.request.contextPath}/admin/purchases.jsp" class="btn-back"><i class="bi bi-arrow-left"></i> Back to Purchases</a>
                    <% if ("Pending".equalsIgnoreCase(purchase.getPaymentStatus())) { %>
                        <a href="${pageContext.request.contextPath}/admin/purchase-paid?id=<%= purchase.getPurchaseId() %>" class="btn-back" style="background: #2E7D52;" onclick="return confirm('Mark this purchase order as paid?')">
                            <i class="bi bi-check-lg"></i> Mark as Paid
                        </a>
                    <% } %>
                </div>
            </div>
        </div>
    </div>
</body>
</html>