<%-- web/admin/edit-purchase.jsp --%>
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
    <title>Edit Purchase Order</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet"/>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet"/>
    <style>
        body { background: #F5F0E6; font-family: 'DM Sans', sans-serif; }
        .container { max-width: 600px; margin: 50px auto; }
        .card { border-radius: 12px; box-shadow: 0 2px 16px rgba(18,34,58,0.08); border: 1px solid #DDD8CE; }
        .card-header { background: #EDE6D4; border-bottom: 1px solid #DDD8CE; font-family: 'Playfair Display', serif; font-weight: 700; padding: 16px 20px; }
        .btn-save { background: #C8923A; color: white; border: none; border-radius: 8px; padding: 10px 24px; }
        .btn-save:hover { background: #DBA85A; }
        .btn-cancel { background: transparent; border: 1.5px solid #DDD8CE; border-radius: 8px; padding: 10px 20px; }
        .form-control, .form-select { border: 1.5px solid #DDD8CE; border-radius: 8px; padding: 10px 14px; }
        .form-control:focus, .form-select:focus { border-color: #C8923A; box-shadow: 0 0 0 3px rgba(200,146,58,0.10); }
        .form-label { font-size: 0.75rem; font-weight: 600; text-transform: uppercase; color: #12223A; }
    </style>
</head>
<body>
    <div class="container">
        <div class="card">
            <div class="card-header">
                <i class="bi bi-pencil-square"></i> Edit Purchase Order
            </div>
            <div class="card-body p-4">
                <form action="${pageContext.request.contextPath}/admin/purchase-edit" method="post">
                    <input type="hidden" name="purchaseId" value="<%= purchase.getPurchaseId() %>">
                    
                    <div class="mb-3">
                        <label class="form-label">PO Number</label>
                        <input type="text" class="form-control" value="<%= purchase.getPurchaseOrderNumber() %>" readonly style="background: #EDE6D4;">
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label">Supplier</label>
                        <input type="text" class="form-control" value="<%= purchase.getSupplierName() != null ? purchase.getSupplierName() : "-" %>" readonly style="background: #EDE6D4;">
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label">Purchase Date</label>
                        <input type="date" name="purchaseDate" class="form-control" value="<%= purchase.getPurchaseDate() %>" required>
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label">Total Amount (R)</label>
                        <input type="number" step="0.01" name="totalAmount" class="form-control" value="<%= purchase.getTotalAmount() %>" required>
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label">Payment Status</label>
                        <select name="paymentStatus" class="form-select">
                            <option value="Pending" <%= "Pending".equals(purchase.getPaymentStatus()) ? "selected" : "" %>>Pending</option>
                            <option value="Paid" <%= "Paid".equals(purchase.getPaymentStatus()) ? "selected" : "" %>>Paid</option>
                        </select>
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label">Delivered By</label>
                        <input type="text" name="deliveredBy" class="form-control" value="<%= purchase.getDeliveredBy() != null ? purchase.getDeliveredBy() : "" %>" placeholder="Delivery company name">
                    </div>
                    
                    <div class="d-flex gap-2 mt-4">
                        <button type="submit" class="btn-save"><i class="bi bi-check-lg"></i> Save Changes</button>
                        <a href="${pageContext.request.contextPath}/admin/purchases.jsp" class="btn-cancel">Cancel</a>
                    </div>
                </form>
            </div>
        </div>
    </div>
</body>
</html>